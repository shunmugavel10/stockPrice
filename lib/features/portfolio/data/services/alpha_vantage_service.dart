import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/models/stock_quote.dart';

/// Service for Alpha Vantage API calls
class AlphaVantageService {
  final Dio _dio;

  AlphaVantageService(this._dio);

  String get _apiKey => dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? '';

  /// Fetches real-time quote for a given stock symbol
  Future<ApiResult<StockQuote>> getGlobalQuote(String symbol) async {
    try {
      final response = await _dio.get(
        '/query',
        queryParameters: {
          'function': AppConstants.globalQuoteFunction,
          'symbol': symbol.toUpperCase(),
          'apikey': _apiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Alpha Vantage returns a "Note" key on rate limit
      if (data.containsKey('Note')) {
        return const ApiError('API rate limit reached. Please wait and try again.',
            statusCode: 429);
      }

      // Alpha Vantage returns "Error Message" for invalid symbols
      if (data.containsKey('Error Message')) {
        return ApiError('Invalid symbol: $symbol');
      }

      // Check for empty response
      if (data['Global Quote'] == null ||
          (data['Global Quote'] as Map).isEmpty) {
        return ApiError('No data found for symbol: $symbol');
      }

      final quote = StockQuote.fromJson(data);
      return ApiSuccess(quote);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const ApiError('Connection timeout. Please check your network.');
      }
      return ApiError('Network error: ${e.message}');
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  /// Searches for symbols matching keywords
  Future<ApiResult<List<Map<String, dynamic>>>> searchSymbol(
      String keywords) async {
    try {
      final response = await _dio.get(
        '/query',
        queryParameters: {
          'function': AppConstants.symbolSearchFunction,
          'keywords': keywords,
          'apikey': _apiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('Note')) {
        return const ApiError('API rate limit reached. Please wait and try again.',
            statusCode: 429);
      }

      final matches = (data['bestMatches'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      return ApiSuccess(matches);
    } on DioException catch (e) {
      return ApiError('Network error: ${e.message}');
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }
}
