import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dio client provider with interceptors and error handling
final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) {
      // Accept status codes less than 500
      return status != null && status < 500;
    },
  );

  final dio = Dio(options);

  // Add logging interceptor in debug mode
  if (kDebugMode) {
    // Log interceptor removed for production
  }

  // Add custom interceptor for error handling and auth
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add custom headers if needed
        // For example, auth token can be added here
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        // Handle different error types
        String errorMessage = 'An error occurred';

        switch (error.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'Connection timeout. Please check your network.';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = 'Request timeout. Please try again.';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Server timeout. Please try again later.';
            break;
          case DioExceptionType.badCertificate:
            errorMessage = 'Invalid SSL certificate.';
            break;
          case DioExceptionType.badResponse:
            final statusCode = error.response?.statusCode;
            switch (statusCode) {
              case 400:
                errorMessage = 'Bad request. Please check your input.';
                break;
              case 401:
                errorMessage = 'Unauthorized. Please login again.';
                break;
              case 403:
                errorMessage = 'Forbidden. You don\'t have permission.';
                break;
              case 404:
                errorMessage = 'Resource not found.';
                break;
              case 500:
                errorMessage = 'Server error. Please try again later.';
                break;
              case 503:
                errorMessage = 'Service unavailable. Please try again later.';
                break;
              default:
                errorMessage = 'Error: ${error.response?.statusMessage}';
            }
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Request was cancelled.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Connection error. Please check your network.';
            break;
          case DioExceptionType.unknown:
            errorMessage = 'Unknown error: ${error.message}';
            break;
        }

        // Pass the error with custom message
        final dioError = DioException(
          requestOptions: error.requestOptions,
          error: errorMessage,
          type: error.type,
          response: error.response,
          message: errorMessage,
        );

        handler.next(dioError);
      },
    ),
  );

  return dio;
});

/// RouterOS Dio API client provider
final routerOSDioClientProvider = Provider<RouterOSDioClient?>((ref) {
  // This will be null until credentials are provided
  return null;
});

/// RouterOS API client using Dio
class RouterOSDioClient {
  final Dio dio;
  final String host;
  final String port;
  final String username;
  final String password;

  RouterOSDioClient({
    required this.dio,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  /// Create a RouterOSDioClient from a Dio instance and credentials
  static RouterOSDioClient create({
    required Dio dio,
    required String host,
    required String port,
    required String username,
    required String password,
  }) {
    return RouterOSDioClient(
      dio: dio,
      host: host,
      port: port,
      username: username,
      password: password,
    );
  }

  /// Connect to RouterOS API
  Future<void> connect() async {
    try {
      final response = await dio.post(
        'http://$host:$port/login',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Authentication failed');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Connection failed');
    }
  }

  /// Get hotspot users list
  Future<List<Map<String, dynamic>>> getHotspotUsers() async {
    try {
      final response = await dio.get(
        'http://$host:$port/ip/hotspot/user',
      );

      if (response.statusCode == 200 && response.data != null) {
        // Parse response based on RouterOS API format
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(
            (response.data as List).map((e) => Map<String, dynamic>.from(e)),
          );
        } else if (response.data is Map) {
          return [Map<String, dynamic>.from(response.data)];
        }
      }

      return [];
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to fetch hotspot users');
    }
  }

  /// Add hotspot user
  Future<void> addHotspotUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
    String? validity, // For limit-uptime (e.g., "5m", "1h", "1d")
    String? dataLimit, // For limit-bytes-total (e.g., "1G", "500M")
    String? sessionTimeout, // Session timeout (e.g., "30m", "1h")
  }) async {
    try {
      final response = await dio.post(
        'http://$host:$port/ip/hotspot/user/add',
        data: {
          'name': username,
          'password': password,
          'profile': profile,
          if (comment != null) 'comment': comment,
          if (validity != null &&
              validity.isNotEmpty &&
              validity != 'unlimited')
            'limit-uptime': validity,
          if (dataLimit != null && dataLimit.isNotEmpty)
            'limit-bytes-total': dataLimit,
          if (sessionTimeout != null &&
              sessionTimeout.isNotEmpty &&
              sessionTimeout != 'unlimited')
            'session-timeout': sessionTimeout,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add user');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to add hotspot user');
    }
  }

  /// Remove hotspot user
  Future<void> removeHotspotUser(String id) async {
    try {
      final response = await dio.post(
        'http://$host:$port/ip/hotspot/user/remove',
        data: {
          '.id': id,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove user');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to remove hotspot user');
    }
  }

  /// Get system resources
  Future<Map<String, dynamic>> getSystemResources() async {
    try {
      final response = await dio.get(
        'http://$host:$port/system/resource',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }

      return {};
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to fetch system resources');
    }
  }

  /// Get interface statistics
  Future<Map<String, dynamic>> getInterfaceStats() async {
    try {
      final response = await dio.get(
        'http://$host:$port/interface',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }

      return {};
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to fetch interface stats');
    }
  }

  /// Disconnect from RouterOS
  void disconnect() {
    dio.close();
  }
}
