import 'package:field_notes/models/field_note.dart';
import 'package:field_notes/models/sync_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Local note timestamps are serialized with a UTC offset', () {
    final occurredAt = DateTime(2026, 10, 10, 8, 18, 16, 221, 83);
    final note = FieldNote(
      id: 'note',
      siteId: 'site',
      customerId: 'customer',
      title: 'Inspection',
      createdAt: occurredAt,
      occurredAt: occurredAt,
    );
    final expected = occurredAt.toUtc().toIso8601String();
    expect(note.toWritePayload()['occurredAt'], expected);
    expect(note.toJson()['occurredAt'], expected);
    expect(expected, endsWith('Z'));
  });

  for (final key in ['occurredAt', 'occurred_at', 'createdAt', 'created_at']) {
    test('Previously queued $key timestamps gain an offset on upload', () {
      const localTimestamp = '2026-10-10T08:18:16.221083';
      final mutation = SyncMutation.fromJson({
        'mutationId': 'mutation',
        'entityType': 'NOTE',
        'entityId': 'note',
        'operation': 'UPSERT',
        'data': {key: localTimestamp},
      });
      final payload = mutation.toApiPayload()['data'] as Map;
      expect(
        payload['occurredAt'],
        DateTime.parse(localTimestamp).toUtc().toIso8601String(),
      );
      expect(mutation.data[key], localTimestamp);
    });
  }

  test('Explicit offsets preserve the original instant', () {
    final mutation = SyncMutation(
      mutationId: 'mutation',
      entityType: EntityType.NOTE,
      entityId: 'note',
      operation: SyncOperation.UPSERT,
      expectedVersion: 0,
      data: {'occurredAt': '2026-10-10T08:18:16.221083+06:00'},
      timestamp: DateTime.now(),
    );
    final payload = mutation.toApiPayload()['data'] as Map;
    expect(payload['occurredAt'], '2026-10-10T02:18:16.221083Z');
  });
}
