class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalException,
  });

  @override
  String toString() => message;

  factory ApiException.fromDioException(dynamic error) {
    if (error is Exception) {
      return ApiException(
        message: error.toString(),
        originalException: error,
      );
    }
    return ApiException(message: 'Unknown error occurred');
  }

  factory ApiException.unauthorized() {
    return ApiException(
      message: 'Unauthorized access',
      statusCode: 401,
    );
  }

  factory ApiException.forbidden() {
    return ApiException(
      message: 'Access forbidden',
      statusCode: 403,
    );
  }

  factory ApiException.notFound() {
    return ApiException(
      message: 'Resource not found',
      statusCode: 404,
    );
  }

  factory ApiException.serverError() {
    return ApiException(
      message: 'Server error occurred',
      statusCode: 500,
    );
  }

  factory ApiException.networkError() {
    return ApiException(
      message: 'Network error occurred',
    );
  }
}
