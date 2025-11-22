import 'package:dio/dio.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// HTTP API client for syncing data
class ApiClient {
  final Dio _dio;
  final SyncVaultLogger _logger;
  final String baseUrl;
  final Map<String, String>? defaultHeaders;

  ApiClient({
    required this.baseUrl,
    required SyncVaultLogger logger,
    this.defaultHeaders,
    Dio? dio,
    int timeoutSeconds = 30,
  })  : _logger = logger,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: Duration(seconds: timeoutSeconds),
                receiveTimeout: Duration(seconds: timeoutSeconds),
                headers: defaultHeaders,
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.debug('${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.debug('Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.error(
            'Request error: ${error.requestOptions.uri}',
            error: error,
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Make a GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Make a POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Make a PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Make a PATCH request
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Make a DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update headers (e.g., for authentication)
  void updateHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
    _logger.debug('Updated API client headers');
  }

  NetworkException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Request timeout',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return NetworkException(
          'Server error: ${statusCode ?? "unknown"}',
          originalError: error,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          'Request cancelled',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'Connection error - please check your internet connection',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          'SSL certificate error',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          'Network error: ${error.message}',
          originalError: error,
        );
    }
  }
}
