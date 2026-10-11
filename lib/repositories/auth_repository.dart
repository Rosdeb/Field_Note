import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/hive_service.dart';
import '../core/sync/sync_manager.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> login(String email, String password);
  Future<User?> register(String email, String password);
  Future<Session?> refreshToken();
  Future<void> logout();
  User? getCurrentUser();
  bool get isAuthenticated;
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final HiveService hiveService;
  final SyncManager syncManager;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.hiveService,
    required this.syncManager,
  });

  @override
  bool get isAuthenticated => hiveService.getAuthToken() != null;

  @override
  User? getCurrentUser() {
    final userJson = hiveService.getSavedUser();
    if (userJson != null) {
      return User.fromJson(userJson);
    }
    return null;
  }

  @override
  Future<User?> login(String email, String password) async {
    final response = await apiClient.post(
      ApiConstants.loginEndpoint,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final session = Session.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );

      final user = User(id: session.userId, email: session.email);
      await hiveService.saveSession(
        token: session.effectiveAccessToken,
        refreshToken: session.refreshToken,
        userJson: user.toJson(),
      );

      // On login, automatically restore all user data from the server
      await syncManager.fullRestore();

      return user;
    }
    return null;
  }

  @override
  Future<User?> register(String email, String password) async {
    final response = await apiClient.post(
      ApiConstants.registerEndpoint,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final session = Session.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );

      final user = User(id: session.userId, email: session.email);
      await hiveService.saveSession(
        token: session.effectiveAccessToken,
        refreshToken: session.refreshToken,
        userJson: user.toJson(),
      );

      return user;
    }
    return null;
  }

  @override
  Future<Session?> refreshToken() async {
    final currentRefreshToken = hiveService.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return null;
    }

    final response = await apiClient.post(
      ApiConstants.refreshEndpoint,
      data: {
        'refreshToken': currentRefreshToken,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final session = Session.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );

      await hiveService.saveTokens(
        token: session.effectiveAccessToken,
        refreshToken: session.refreshToken ?? currentRefreshToken,
      );

      return session;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = hiveService.getRefreshToken();
      await apiClient.post(
        ApiConstants.logoutEndpoint,
        data: {
          'refreshToken': ?refreshToken,
        },
      );
    } catch (_) {
      // Ignore network failure on logout
    }
    await hiveService.clearSession();
    await hiveService.clearAllData();
  }
}
