import 'package:dio/dio.dart';
import '../exceptions/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        exception = TimeoutException(
          statusCode: err.response?.statusCode,
          data: err.response?.data,
        );
        break;

      case DioExceptionType.connectionError:
        exception = NetworkException(
          statusCode: err.response?.statusCode,
          data: err.response?.data,
        );
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        String message = _readServerMessage(responseData);

        if (statusCode == 400) {
          if (message == 'Server error occurred.' || message.isEmpty) {
            message =
                'Invalid request. Please ensure email format is valid and password has at least 10 characters.';
          }
          exception = ServerException(
            message: message,
            statusCode: 400,
            data: responseData,
          );
        } else if (statusCode == 401) {
          if (message == 'Server error occurred.' || message.isEmpty) {
            message = 'Session expired or unauthorized. Please log in again.';
          }
          exception = UnauthorizedException(
            message: message,
            statusCode: statusCode,
            data: responseData,
          );
        } else {
          exception = ServerException(
            message: message,
            statusCode: statusCode ?? 500,
            data: responseData,
          );
        }
        break;

      case DioExceptionType.cancel:
        exception = const AppException(message: 'Request was cancelled');
        break;

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        exception = AppException(
          message: err.message ?? 'An unexpected network error occurred.',
          statusCode: err.response?.statusCode,
          data: err.response?.data,
        );
        break;
    }

    final customDioError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: exception,
      message: exception.message,
    );

    return handler.next(customDioError);
  }

  // APIs use different field names for the same human-readable error.
  String _readServerMessage(dynamic data) {
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      const messageKeys = [
        'detail',
        'message',
        'error_description',
        'error',
        'title',
      ];
      for (final key in messageKeys) {
        final message = data[key]?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
      if (data['errors'] is List) {
        return (data['errors'] as List)
            .map((error) => error.toString())
            .join(', ');
      }
    }
    return 'Server error occurred.';
  }
}
