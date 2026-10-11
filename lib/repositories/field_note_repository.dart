import 'package:uuid/uuid.dart';
import '../core/storage/hive_service.dart';
import '../core/sync/sync_manager.dart';
import '../models/field_note.dart';
import '../models/sync_item.dart';

abstract class FieldNoteRepository {
  Future<List<FieldNote>> getFieldNotes({
    String? siteId,
    String? customerId,
    String? status,
    String? query,
  });
  Future<FieldNote?> getFieldNoteById(String id);
  Future<FieldNote> saveFieldNote(FieldNote note);
  Future<void> deleteFieldNote(String id);
}

class FieldNoteRepositoryImpl implements FieldNoteRepository {
  final HiveService hiveService;
  final SyncManager syncManager;
  final Uuid _uuid = const Uuid();

  FieldNoteRepositoryImpl({
    required this.hiveService,
    required this.syncManager,
  });

  @override
  Future<List<FieldNote>> getFieldNotes({
    String? siteId,
    String? customerId,
    String? status,
    String? query,
  }) async {
    final box = hiveService.notesBox;
    final notes = <FieldNote>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final note = FieldNote.fromJson((raw as Map).cast<String, dynamic>());
        if (siteId != null && note.siteId != siteId) continue;
        if (customerId != null && note.customerId != customerId) continue;
        if (status != null && note.status != status) continue;
        if (query != null && query.isNotEmpty) {
          final q = query.toLowerCase();
          if (!note.title.toLowerCase().contains(q) &&
              !note.notes.toLowerCase().contains(q)) {
            continue;
          }
        }
        notes.add(note);
      }
    }

    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<FieldNote?> getFieldNoteById(String id) async {
    final raw = hiveService.notesBox.get(id);
    if (raw == null) return null;
    return FieldNote.fromJson((raw as Map).cast<String, dynamic>());
  }

  @override
  Future<FieldNote> saveFieldNote(FieldNote note) async {
    final String noteId = note.id.isEmpty ? _uuid.v4() : note.id;
    final int nextVersion = note.version + 1;
    final updatedNote = note.copyWith(
      id: noteId,
      version: nextVersion,
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    // 1. Save locally in Hive
    await hiveService.notesBox.put(noteId, updatedNote.toJson());

    // 2. Enqueue sync mutation
    final mutationId = _uuid.v4();
    final mutation = SyncMutation(
      mutationId: mutationId,
      entityType: EntityType.NOTE,
      entityId: noteId,
      operation: SyncOperation.UPSERT,
      expectedVersion: note.version,
      data: updatedNote.toWritePayload(),
      timestamp: DateTime.now(),
    );
    await hiveService.syncMutationsBox.put(mutationId, mutation.toJson());

    // 3. Trigger background sync
    syncManager.scheduleLocalSync();

    return updatedNote;
  }

  @override
  Future<void> deleteFieldNote(String id) async {
    final existing = await getFieldNoteById(id);
    final expectedVersion = existing?.version ?? 0;

    // 1. Delete locally from Hive
    await hiveService.notesBox.delete(id);

    // 2. Enqueue delete mutation
    final mutationId = _uuid.v4();
    final mutation = SyncMutation(
      mutationId: mutationId,
      entityType: EntityType.NOTE,
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
