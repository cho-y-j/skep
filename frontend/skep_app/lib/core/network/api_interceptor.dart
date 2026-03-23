import 'package:dio/dio.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/storage/secure_storage.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  ApiInterceptor({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add JWT token to headers
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // Create a new Dio instance to avoid infinite loop
          final dio = Dio();
          final response = await dio.post(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final newToken = response.data['token'];
            final newRefreshToken = response.data['refreshToken'];

            // Save new tokens
            await _secureStorage.saveToken(newToken);
            if (newRefreshToken != null) {
              await _secureStorage.saveRefreshToken(newRefreshToken);
            }

            // Retry original request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await _dio.request<dynamic>(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
              ),
            );

            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        // Refresh failed, continue with original error
      }
    }
    super.onError(err, handler);
  }

  // Reference to Dio instance - will be injected by DioClient
  late Dio _dio;

  void setDio(Dio dio) {
    _dio = dio;
  }
}
