// ============================================================
//  RetryInterceptor — Dio interceptor مع Exponential Backoff
//
//  يعيد المحاولة تلقائياً عند فشل الطلبات بسبب:
//  - انقطاع الشبكة (SocketException)
//  - Timeout
//  - HTTP 5xx (Server Error)
//  - HTTP 429 (Rate Limited)
// ============================================================

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final List<Duration> delays;

  RetryInterceptor({
    this.maxRetries = 3,
    List<Duration>? customDelays,
  }) : delays = customDelays ??
            [Duration.zero, const Duration(seconds: 1), const Duration(seconds: 2), const Duration(seconds: 4)];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && maxRetries > 0) {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        final delay = attempt < delays.length ? delays[attempt] : delays.last;
        await Future.delayed(delay);

        try {
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          if (attempt == maxRetries) {
            return handler.next(err);
          }
        }
      }
    } else {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    if (err.response != null && err.response!.statusCode != null) {
      final code = err.response!.statusCode!;
      return code >= 500 || code == 429;
    }
    return false;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final dio = Dio();
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      ),
    );
  }
}
