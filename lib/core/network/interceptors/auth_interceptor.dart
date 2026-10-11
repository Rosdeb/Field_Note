import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../storage/hive_service.dart';

class AuthInterceptor extends Interceptor {
  final HiveService hiveService;
  final VoidCallback? onUnauthorized;

  AuthInterceptor({
    required this.hiveService,
    this.onUnauthorized,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = hiveService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestPath = err.requestOptions.path;
      final isAuthEndpoint = requestPath.contains(ApiConstants.loginEndpoint) ||
          requestPath.contains(ApiConstants.registerEndpoint) ||
          requestPath.contains(ApiConstants.refreshEndpoint);

      if (!isAuthEndpoint) {
        final refreshToken = hiveService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          try {
            final refreshDio = Dio(
              BaseOptions(
                baseUrl: err.requestOptions.baseUrl.isNotEmpty
                    ? err.requestOptions.baseUrl
                    : ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

            final refreshResponse = await refreshDio.post(
              ApiConstants.refreshEndpoint,
              data: {'refreshToken': refreshToken},
            );

            if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
              final data = refreshResponse.data is Map
                  ? (refreshResponse.data as Map).cast<String, dynamic>()
                  : <String, dynamic>{};
              final newAccessToken = data['accessToken'] as String? ?? data['token'] as String? ?? '';
              final newRefreshToken = data['refreshToken'] as String? ?? refreshToken;

              if (newAccessToken.isNotEmpty) {
                await hiveService.saveTokens(
                  token: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                // Retry original request with new token
                final options = err.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final retryDio = Dio();
                final retryResponse = await retryDio.fetch(options);
                return handler.resolve(retryResponse);
              }
            }
          } catch (_) {
            // Token refresh failed, fall through to unauthorized
          }
        }
      }

      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}

typedef VoidCallback = void Function();
