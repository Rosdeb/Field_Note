import '../core/storage/hive_service.dart';
import '../core/sync/sync_manager.dart';
import '../models/sync_item.dart';

abstract class SyncRepository {
  List<SyncMutation> getPendingMutations();
  Future<int> triggerSync();
  Future<void> restoreAllData();
  int getLastSyncCursor();
}

class SyncRepositoryImpl implements SyncRepository {
  final HiveService hiveService;
  final SyncManager syncManager;

  SyncRepositoryImpl({
    required this.hiveService,
    required this.syncManager,
  });

  @override
  List<SyncMutation> getPendingMutations() {
    final box = hiveService.syncMutationsBox;
    final mutations = <SyncMutation>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        mutations.add(SyncMutation.fromJson((raw as Map).cast<String, dynamic>()));
      }
    }

    mutations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return mutations;
  }

  @override
  Future<int> triggerSync() async {
    return await syncManager.syncAll(throwOnError: true);
  }

  @override
  Future<void> restoreAllData() async {
    await syncManager.fullRestore(throwOnError: true);
  }

  @override
  int getLastSyncCursor() {
    return hiveService.getLastSyncCursor();
  }
}
