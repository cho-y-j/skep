import 'package:dio/dio.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/api_interceptor.dart';
import 'package:skep_app/core/storage/secure_storage.dart';

class DioClient {
  late final Dio _dio;
  late final SecureStorage _secureStorage;
  late final ApiInterceptor _interceptor;

  DioClient() {
    _secureStorage = SecureStorage();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    _interceptor = ApiInterceptor(secureStorage: _secureStorage);
    _interceptor.setDio(_dio);
    _dio.interceptors.add(_interceptor);
  }

  Dio getDio() => _dio;

  SecureStorage getSecureStorage() => _secureStorage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Never _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      throw Exception('Connection timeout');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      throw Exception('Receive timeout');
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.data?['message'] ?? 'Unknown error';
      throw Exception('Error: $statusCode - $message');
    } else if (error.type == DioExceptionType.unknown) {
      throw Exception('Network error: ${error.error}');
    } else {
      throw Exception('Unexpected error: ${error.message}');
    }
  }
}
