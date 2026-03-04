import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';

/// Configures and provides a singleton Dio instance for API calls
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? 'https://www.alphavantage.co',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logging
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ),
    );

    // Retry interceptor for rate limits
    dio.interceptors.add(_RetryInterceptor(dio));

    return dio;
  }
}

/// Handles API retry logic for rate limit (HTTP 429) and server errors
class _RetryInterceptor extends Interceptor {
  final Dio _dio;

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isRateLimit = statusCode == 429;
    final isServerError = statusCode != null && statusCode >= 500;

    if (isRateLimit || isServerError) {
      final retries = err.requestOptions.extra['retries'] ?? 0;

      if (retries < AppConstants.maxRetries) {
        err.requestOptions.extra['retries'] = retries + 1;
        final delay = AppConstants.retryDelay * (retries + 1);

        await Future.delayed(delay);

        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }
}
