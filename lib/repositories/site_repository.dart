import 'package:uuid/uuid.dart';
import '../core/storage/hive_service.dart';
import '../core/sync/sync_manager.dart';
import '../models/site.dart';
import '../models/sync_item.dart';

abstract class SiteRepository {
  Future<List<Site>> getSites({String? customerId, String? query});
  Future<Site?> getSiteById(String id);
  Future<Site> saveSite(Site site);
  Future<void> deleteSite(String id);
}

class SiteRepositoryImpl implements SiteRepository {
  final HiveService hiveService;
  final SyncManager syncManager;
  final Uuid _uuid = const Uuid();

  SiteRepositoryImpl({required this.hiveService, required this.syncManager});

  @override
  Future<List<Site>> getSites({String? customerId, String? query}) async {
    final box = hiveService.sitesBox;
    final sites = <Site>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final site = Site.fromJson((raw as Map).cast<String, dynamic>());
        if (customerId != null && site.customerId != customerId) {
          continue;
        }
        if (query != null && query.isNotEmpty) {
          final q = query.toLowerCase();
          if (!site.name.toLowerCase().contains(q) &&
              !site.address.toLowerCase().contains(q)) {
            continue;
          }
        }
        sites.add(site);
      }
    }

    sites.sort((a, b) => a.name.compareTo(b.name));
    return sites;
  }

  @override
  Future<Site?> getSiteById(String id) async {
    final raw = hiveService.sitesBox.get(id);
    if (raw == null) return null;
    return Site.fromJson((raw as Map).cast<String, dynamic>());
  }

  @override
  Future<Site> saveSite(Site site) async {
    final String siteId = site.id.isEmpty ? _uuid.v4() : site.id;
    final int nextVersion = site.version + 1;
    final updatedSite = site.copyWith(
      id: siteId,
      version: nextVersion,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. Save locally to Hive
    await hiveService.sitesBox.put(siteId, updatedSite.toJson());

    // 2. Enqueue sync mutation
    final mutationId = _uuid.v4();
    final mutation = SyncMutation(
      mutationId: mutationId,
      entityType: EntityType.SITE,
      entityId: siteId,
      operation: SyncOperation.UPSERT,
      expectedVersion: site.version,
      data: updatedSite.toWritePayload(),
      timestamp: DateTime.now(),
    );
    await hiveService.syncMutationsBox.put(mutationId, mutation.toJson());

    // 3. Trigger background sync
    syncManager.scheduleLocalSync();

    return updatedSite;
  }

  @override
  Future<void> deleteSite(String id) async {
    final existing = await getSiteById(id);
    final expectedVersion = existing?.version ?? 0;

    // 1. Delete locally from Hive
    await hiveService.sitesBox.delete(id);

    // 2. Enqueue delete mutation
    final mutationId = _uuid.v4();
    final mutation = SyncMutation(
      mutationId: mutationId,
      entityType: EntityType.SITE,
      entityId: id,
      operation: SyncOperation.DELETE,
      expectedVersion: expectedVersion,
      data: {'id': id, 'deleted': true},
      timestamp: DateTime.now(),
    );
    await hiveService.syncMutationsBox.put(mutationId, mutation.toJson());

    // 3. Trigger background sync
    syncManager.scheduleLocalSync();
  }
}
