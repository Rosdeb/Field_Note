import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://127.0.0.1:8080';
  }

  static String get baseUrl {
    if (dotenv.isInitialized) {
      final envUrl = dotenv.maybeGet('BASE_URL');
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        return envUrl.trim();
      }
    }
    return defaultBaseUrl;
  }

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String meEndpoint = '/api/auth/me';

  // Sync endpoints
  static const String syncPushEndpoint = '/api/sync/push';
  static const String syncChangesEndpoint = '/api/sync/changes';

  // Data endpoints
  static const String customersEndpoint = '/api/customers';
  static const String sitesEndpoint = '/api/sites';
  static const String notesEndpoint = '/api/notes';
  static const String photosEndpoint = '/api/photos';
}
