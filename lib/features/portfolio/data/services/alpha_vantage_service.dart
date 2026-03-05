import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_cache_service.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/models/stock_quote.dart';

/// Cached entry for API responses
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp).inSeconds >
      AppConstants.cacheDurationSeconds;
}

/// Service for Marketstack API calls with 60-second caching
class MarketstackService {
  final Dio _dio;
  final Map<String, _CacheEntry<StockQuote>> _quoteCache = {};

  MarketstackService(this._dio);

  /// Fetches the latest EOD price for a given stock symbol
  Future<ApiResult<StockQuote>> fetchStockPrice(String symbol) async {
    final key = symbol.toUpperCase();
    final cacheKey = 'quote_$key';

    // L1: in-memory cache
    if (_quoteCache.containsKey(key) && !_quoteCache[key]!.isExpired) {
      return ApiSuccess(_quoteCache[key]!.data);
    }

    // L2: persistent Hive cache
    final cached = ApiCacheService.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      final quote = StockQuote.fromMarketstack(cached);
      _quoteCache[key] = _CacheEntry(quote);
      return ApiSuccess(quote);
    }

    try {
      final response = await _dio.get(
        '/eod',
        queryParameters: {
          'access_key': AppConstants.marketstackApiKey,
          'symbols': key,
          'limit': 1,
        },
      );

      final data = response.data;

      // Marketstack returns error object on failures
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        final error = data['error'];
        final errorMessage = error['message'] ?? 'Unknown API error';
        final errorCode = error['code'] ?? '';

        if (errorCode == 'usage_limit_reached' ||
            errorCode == 'rate_limit_reached') {
          return const ApiError(
            'API rate limit exceeded. Please try again later.',
            statusCode: 429,
          );
        }
        return ApiError('API error: $errorMessage');
      }

      // Parse EOD data
      final eodList = data['data'] as List<dynamic>?;

      if (eodList == null || eodList.isEmpty) {
        return ApiError('No data found for symbol: $symbol');
      }

      final quote = StockQuote.fromMarketstack(
        eodList[0] as Map<String, dynamic>,
      );

      if (quote.isEmpty) {
        return ApiError('Invalid data for symbol: $symbol');
      }

      // Cache the result (L1 in-memory + L2 persistent)
      _quoteCache[key] = _CacheEntry(quote);
      await ApiCacheService.put(
        cacheKey,
        eodList[0] as Map<String, dynamic>,
        ttl: const Duration(minutes: 5),
      );

      return ApiSuccess(quote);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const ApiError(
            'Connection timeout. Please check your network.');
      }
      return ApiError('Network error: ${e.message}');
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  /// Searches for tickers matching keywords using Marketstack tickers endpoint
  Future<ApiResult<List<Map<String, dynamic>>>> searchSymbol(
      String keywords) async {
    final cacheKey = 'search_${keywords.toLowerCase().trim()}';

    // Check persistent cache first
    final cached = ApiCacheService.get<List<dynamic>>(cacheKey);
    if (cached != null) {
      return ApiSuccess(cached.cast<Map<String, dynamic>>());
    }

    try {
      final response = await _dio.get(
        '/tickers',
        queryParameters: {
          'access_key': AppConstants.marketstackApiKey,
          'search': keywords,
          'limit': 10,
        },
      );

      final data = response.data;

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        final error = data['error'];
        return ApiError('API error: ${error['message'] ?? 'Unknown error'}');
      }

      final tickers = (data['data'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Persist search results (1 hour TTL)
      await ApiCacheService.put(cacheKey, tickers, ttl: const Duration(hours: 1));

      return ApiSuccess(tickers);
    } on DioException catch (e) {
      return ApiError('Network error: ${e.message}');
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  /// Fetches a paginated list of tickers (for browsing stocks)
  Future<ApiResult<List<Map<String, dynamic>>>> fetchTickers({
    int offset = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'tickers_${offset}_$limit';

    // Check persistent cache first
    final cached = ApiCacheService.get<List<dynamic>>(cacheKey);
    if (cached != null) {
      return ApiSuccess(cached.cast<Map<String, dynamic>>());
    }

    try {
      final response = await _dio.get(
        '/tickers',
        queryParameters: {
          'access_key': AppConstants.marketstackApiKey,
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data;

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        final error = data['error'];
        return ApiError('API error: ${error['message'] ?? 'Unknown error'}');
      }

      final tickers = (data['data'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Persist ticker pages (1 hour TTL)
      await ApiCacheService.put(cacheKey, tickers, ttl: const Duration(hours: 1));

      return ApiSuccess(tickers);
    } on DioException catch (e) {
      return ApiError('Network error: ${e.message}');
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  /// Fetches historical EOD prices for a symbol within a date range
  Future<ApiResult<List<Map<String, dynamic>>>> fetchHistoricalPrices({
    required String symbol,
    required String dateFrom,
    required String dateTo,
    int limit = 365,
  }) async {
    final key = symbol.toUpperCase();
    final cacheKey = 'history_${key}_${dateFrom}_$dateTo';

    // Check persistent cache first
    final cached = ApiCacheService.get<List<dynamic>>(cacheKey);
    if (cached != null) {
      return ApiSuccess(cached.cast<Map<String, dynamic>>());
    }

    try {
      final response = await _dio.get(
        '/eod',
        queryParameters: {
          'access_key': AppConstants.marketstackApiKey,
          'symbols': key,
          'date_from': dateFrom,
          'date_to': dateTo,
          'limit': limit,
          'sort': 'ASC',
        },
      );

      final data = response.data;

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        final error = data['error'];
        return ApiError('API error: ${error['message'] ?? 'Unknown error'}');
      }

      final eodList = (data['data'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Persist with 1 hour TTL
      await ApiCacheService.put(cacheKey, eodList, ttl: const Duration(hours: 1));

      return ApiSuccess(eodList);
    } on DioException catch (e) {
      return ApiError('Network error: ${e.message}');
    } catch (e) {
      return ApiError('Unexpected error: $e');
    }
  }

  /// Clears both in-memory and persistent caches
  Future<void> clearCache() async {
    _quoteCache.clear();
    await ApiCacheService.clearAll();
  }
}
