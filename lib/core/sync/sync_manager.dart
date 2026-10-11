import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/exceptions/app_exception.dart';
import '../network/network_info.dart';
import '../storage/hive_service.dart';
import '../../models/sync_item.dart';
import '../../models/customer.dart';
import '../../models/site.dart';
import '../../models/field_note.dart';

class SyncManager {
  final ApiClient apiClient;
  final NetworkInfo networkInfo;
  final HiveService hiveService;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _localChangesTimer;
  bool _isSyncing = false;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  SyncManager({
    required this.apiClient,
    required this.networkInfo,
    required this.hiveService,
  }) {
    _initAutoSync();
  }

  void _initAutoSync() {
    // Retry persisted changes once at startup and when connectivity returns.
    Future.microtask(_pushLocalChanges);
    _connectivitySubscription = networkInfo.onConnectivityChanged
        .distinct()
        .listen((isConnected) {
          if (isConnected) scheduleLocalSync();
        });
  }

  /// Group nearby saves into one upload instead of calling the API per edit.
  void scheduleLocalSync() {
    if (hiveService.syncMutationsBox.isEmpty) return;
    _localChangesTimer?.cancel();
    _localChangesTimer = Timer(
      const Duration(milliseconds: 500),
      _pushLocalChanges,
    );
  }

  Future<void> _pushLocalChanges() async {
    if (hiveService.syncMutationsBox.isEmpty) return;
    try {
      await syncAll(pullRemoteChanges: false);
    } catch (error) {
      // Keep failed changes queued until a new save, reconnect, or manual retry.
      debugPrint('Local changes upload failed: $error');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _localChangesTimer?.cancel();
    isSyncingNotifier.dispose();
  }

  /// Push all local offline changes to the backend
  Future<int> pushPendingMutations() async {
    final box = hiveService.syncMutationsBox;
    if (box.isEmpty) return 0;

    final rawMutations = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        rawMutations.add((data as Map).cast<String, dynamic>());
      }
    }

    if (rawMutations.isEmpty) return 0;

    // Prepare payloads away from the UI isolate to keep the screen responsive.
    final batchApiPayloads = await compute(_prepareBatchPayloads, rawMutations);
    if (batchApiPayloads.isEmpty) return 0;

    final payload = {'mutations': batchApiPayloads};

    final response = await apiClient.post(
      ApiConstants.syncPushEndpoint,
      data: payload,
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const ServerException(
        message: 'The server did not confirm the upload.',
      );
    }
    return _saveAcknowledgements(response.data);
  }

  // An acknowledgement means the server accepted this queued change.
  Future<int> _saveAcknowledgements(dynamic responseData) async {
    final results = (responseData['results'] as List<dynamic>?) ?? [];
    for (final result in results) {
      final acknowledgement = SyncAck.fromJson(
        (result as Map).cast<String, dynamic>(),
      );
      await hiveService.syncMutationsBox.delete(acknowledgement.mutationId);
      await _applyAckToLocalStore(acknowledgement);
    }
    return results.length;
  }

  Future<void> _pullAllChanges() async {
    bool hasMore = true;
    while (hasMore) {
      hasMore = await pullChanges();
    }
  }

  Future<void> _applyAckToLocalStore(SyncAck ack) async {
    switch (ack.entityType) {
      case EntityType.CUSTOMER:
        final raw = hiveService.customersBox.get(ack.entityId);
        if (raw != null) {
          final customer = Customer.fromJson(
            (raw as Map).cast<String, dynamic>(),
          );
          final updated = customer.copyWith(version: ack.version);
          await hiveService.customersBox.put(ack.entityId, updated.toJson());
        }
        break;

      case EntityType.SITE:
        final raw = hiveService.sitesBox.get(ack.entityId);
        if (raw != null) {
          final site = Site.fromJson((raw as Map).cast<String, dynamic>());
          final updated = site.copyWith(version: ack.version);
          await hiveService.sitesBox.put(ack.entityId, updated.toJson());
        }
        break;

      case EntityType.NOTE:
        final raw = hiveService.notesBox.get(ack.entityId);
        if (raw != null) {
          final note = FieldNote.fromJson((raw as Map).cast<String, dynamic>());
          final updated = note.copyWith(version: ack.version, isSynced: true);
          await hiveService.notesBox.put(ack.entityId, updated.toJson());
        }
        break;
    }
  }

  /// Pull incremental changes from backend using cursor
  Future<bool> pullChanges() async {
    final currentCursor = hiveService.getLastSyncCursor();
    final response = await apiClient.get(
      ApiConstants.syncChangesEndpoint,
      queryParameters: {'after': currentCursor, 'limit': 100},
    );

    if (response.statusCode == 200 && response.data != null) {
      // Parse the response away from the UI isolate.
      final rawData = (response.data as Map).cast<String, dynamic>();
      final pullResponse = await compute(_parsePullResponse, rawData);

      for (final change in pullResponse.changes) {
        await _applyServerChangeToLocal(change);
      }

      await hiveService.setLastSyncCursor(pullResponse.nextCursor);
      return pullResponse.hasMore;
    }

    return false;
  }

  Future<void> _applyServerChangeToLocal(SyncChange change) async {
    final data = change.data;
    final isDeleted = data.isEmpty || data['deleted'] == true;

    switch (change.entityType) {
      case EntityType.CUSTOMER:
        if (isDeleted) {
          await hiveService.customersBox.delete(change.entityId);
        } else {
          final customer = Customer.fromJson(data);
          await hiveService.customersBox.put(customer.id, customer.toJson());
        }
        break;

      case EntityType.SITE:
        if (isDeleted) {
          await hiveService.sitesBox.delete(change.entityId);
        } else {
          final site = Site.fromJson(data);
          await hiveService.sitesBox.put(site.id, site.toJson());
        }
        break;

      case EntityType.NOTE:
        if (isDeleted) {
          await hiveService.notesBox.delete(change.entityId);
        } else {
          final note = FieldNote.fromJson(data).copyWith(isSynced: true);
          await hiveService.notesBox.put(note.id, note.toJson());
        }
        break;
    }
  }

  /// Automatic sync only uploads; manual sync also downloads server changes.
  Future<int> syncAll({
    bool throwOnError = false,
    bool pullRemoteChanges = true,
  }) async {
    if (_isSyncing) return 0;
    if (!pullRemoteChanges && hiveService.syncMutationsBox.isEmpty) return 0;

    // Set the lock before awaiting connectivity to prevent overlapping uploads.
    _isSyncing = true;
    try {
      if (hiveService.getAuthToken() == null) {
        if (throwOnError) {
          throw const UnauthorizedException(
            message: 'Please log in first to synchronize with the server.',
          );
        }
        return 0;
      }
      if (!(await networkInfo.isConnected)) {
        if (throwOnError) {
          throw const NetworkException(
            message:
                'No internet connection. Changes will sync automatically when connected.',
          );
        }
        return 0;
      }

      isSyncingNotifier.value = true;
      int pushedCount = 0;
      while (hiveService.syncMutationsBox.isNotEmpty) {
        final acknowledgedCount = await pushPendingMutations();
        pushedCount += acknowledgedCount;
        // Stop when no progress is made; never repeatedly upload the same batch.
        if (acknowledgedCount == 0) break;
      }
      if (hiveService.syncMutationsBox.isNotEmpty) {
        throw const ServerException(
          message: 'Some changes were not accepted. Please retry sync.',
        );
      }
      if (pullRemoteChanges) await _pullAllChanges();
      return pushedCount;
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
    }
  }

  /// Restore all server data from scratch (e.g. fresh install or login)
  Future<void> fullRestore({bool throwOnError = false}) async {
    if (hiveService.getAuthToken() == null) {
      if (throwOnError) {
        throw const UnauthorizedException(
          message: 'Please log in first to restore data from the server.',
        );
      }
      return;
    }

    if (!(await networkInfo.isConnected)) {
      if (throwOnError) {
        throw const NetworkException(
          message: 'No internet connection. Cannot restore data while offline.',
        );
      }
      return;
    }

    await hiveService.setLastSyncCursor(0);

    try {
      _isSyncing = true;
      isSyncingNotifier.value = true;

      await _pullAllChanges();
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
    }
  }
}

// Top-level functions can be passed to compute() to run in another isolate.

int _entityTypeRank(EntityType entityType, SyncOperation operation) {
  if (operation == SyncOperation.DELETE) {
    switch (entityType) {
      case EntityType.NOTE:
        return 0;
      case EntityType.SITE:
        return 1;
      case EntityType.CUSTOMER:
        return 2;
    }
  } else {
    switch (entityType) {
      case EntityType.CUSTOMER:
        return 0;
      case EntityType.SITE:
        return 1;
      case EntityType.NOTE:
        return 2;
    }
  }
}

List<Map<String, dynamic>> _prepareBatchPayloads(
  List<Map<String, dynamic>> rawList,
) {
  final mutations = rawList.map((data) => SyncMutation.fromJson(data)).toList();

  // Save parents before children; delete children before parents.
  mutations.sort((a, b) {
    final rankA = _entityTypeRank(a.entityType, a.operation);
    final rankB = _entityTypeRank(b.entityType, b.operation);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    return a.timestamp.compareTo(b.timestamp);
  });

  return mutations.take(100).map((m) => m.toApiPayload()).toList();
}

SyncPullResponse _parsePullResponse(Map<String, dynamic> rawJson) {
  return SyncPullResponse.fromJson(rawJson);
}
