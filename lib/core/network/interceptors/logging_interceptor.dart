import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  final bool enableLogging;

  LoggingInterceptor({this.enableLogging = kDebugMode});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enableLogging) {
      debugPrint('┌── [HTTP REQUEST] ${options.method} ${options.uri}');
      debugPrint('│ Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('│ Body: ${options.data}');
      }
      debugPrint('└──');
    }
    return handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enableLogging) {
      debugPrint(
        '┌── [HTTP RESPONSE] [${response.statusCode}] ${response.requestOptions.uri}',
      );
      if (response.data != null) {
        debugPrint('│ Data: ${response.data}');
      }
      debugPrint('└──');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enableLogging) {
      final message = (err.message ?? 'Unable to reach the server.').replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      debugPrint(
        '[HTTP ERROR] [${err.response?.statusCode ?? 'N/A'}] '
        '${err.requestOptions.method} ${err.requestOptions.uri.path}',
        wrapWidth: 100000,
      );
      debugPrint(
        message.length > 200 ? '${message.substring(0, 197)}...' : message,
        wrapWidth: 100000,
      );
    }
    return handler.next(err);
  }
}
