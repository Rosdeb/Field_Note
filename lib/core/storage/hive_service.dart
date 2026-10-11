import 'package:hive_flutter/hive_flutter.dart';
import 'storage_keys.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  late Box<dynamic> _sessionBox;
  late Box<dynamic> _customersBox;
  late Box<dynamic> _sitesBox;
  late Box<dynamic> _notesBox;
  late Box<dynamic> _syncMutationsBox;
  late Box<dynamic> _settingsBox;

  Box<dynamic> get sessionBox => _sessionBox;
  Box<dynamic> get customersBox => _customersBox;
  Box<dynamic> get sitesBox => _sitesBox;
  Box<dynamic> get notesBox => _notesBox;
  Box<dynamic> get syncMutationsBox => _syncMutationsBox;
  Box<dynamic> get settingsBox => _settingsBox;

  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }

    _sessionBox = await Hive.openBox(StorageKeys.sessionBox);
    _customersBox = await Hive.openBox(StorageKeys.customersBox);
    _sitesBox = await Hive.openBox(StorageKeys.sitesBox);
    _notesBox = await Hive.openBox(StorageKeys.notesBox);
    _syncMutationsBox = await Hive.openBox(StorageKeys.syncMutationsBox);
    _settingsBox = await Hive.openBox(StorageKeys.settingsBox);
  }

  // Token & Session Helpers
  String? getAuthToken() {
    return _sessionBox.get(StorageKeys.tokenKey) as String?;
  }

  String? getRefreshToken() {
    return _sessionBox.get(StorageKeys.refreshTokenKey) as String?;
  }

  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required Map<String, dynamic> userJson,
  }) async {
    await _sessionBox.put(StorageKeys.tokenKey, token);
    if (refreshToken != null) {
      await _sessionBox.put(StorageKeys.refreshTokenKey, refreshToken);
    }
    await _sessionBox.put(StorageKeys.userKey, userJson);
  }

  Future<void> saveTokens({
    required String token,
    String? refreshToken,
  }) async {
    await _sessionBox.put(StorageKeys.tokenKey, token);
    if (refreshToken != null) {
      await _sessionBox.put(StorageKeys.refreshTokenKey, refreshToken);
    }
  }

  Map<String, dynamic>? getSavedUser() {
    final data = _sessionBox.get(StorageKeys.userKey);
    if (data == null) return null;
    return (data as Map).cast<String, dynamic>();
  }

  Future<void> clearSession() async {
    await _sessionBox.clear();
  }

  // Sync Cursor
  int getLastSyncCursor() {
    return (_settingsBox.get(StorageKeys.lastSyncCursorKey) as num?)?.toInt() ?? 0;
  }

  Future<void> setLastSyncCursor(int cursor) async {
    await _settingsBox.put(StorageKeys.lastSyncCursorKey, cursor);
  }

  // Onboarding
  bool isOnboardingCompleted() {
    return (_settingsBox.get(StorageKeys.onboardingCompletedKey) as bool?) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _settingsBox.put(StorageKeys.onboardingCompletedKey, completed);
  }

  // Clear all local domain data (useful on logout or fresh re-sync)
  Future<void> clearAllData() async {
    await _customersBox.clear();
    await _sitesBox.clear();
    await _notesBox.clear();
    await _syncMutationsBox.clear();
    await setLastSyncCursor(0);
  }
}
