import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/hive_service.dart';
import 'interceptors/interceptors.dart';

class ApiClient {
  late final Dio dio;
  final HiveService _hiveService;

  ApiClient({
    String? baseUrl,
    HiveService? hiveService,
    VoidCallback? onUnauthorized,
  }) : _hiveService = hiveService ?? HiveService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Modular Interceptors Pipeline
    dio.interceptors.addAll([
      AuthInterceptor(
        hiveService: _hiveService,
        onUnauthorized: onUnauthorized,
      ),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
