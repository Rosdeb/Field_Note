// ignore_for_file: constant_identifier_names

enum EntityType { CUSTOMER, SITE, NOTE }

enum SyncOperation { UPSERT, DELETE }

class SyncMutation {
  final String mutationId;
  final EntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final int expectedVersion;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const SyncMutation({
    required this.mutationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.expectedVersion,
    required this.data,
    required this.timestamp,
  });

  factory SyncMutation.fromJson(Map<String, dynamic> json) {
    return SyncMutation(
      mutationId: json['mutationId'] as String? ?? '',
      entityType: EntityType.values.firstWhere(
        (e) => e.name == json['entityType'],
        orElse: () => EntityType.NOTE,
      ),
      entityId: json['entityId'] as String? ?? '',
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => SyncOperation.UPSERT,
      ),
      expectedVersion: (json['expectedVersion'] as num?)?.toInt() ?? 0,
      data:
          (json['data'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
          {},
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mutationId': mutationId,
      'entityType': entityType.name,
      'entityId': entityId,
      'operation': operation.name,
      'expectedVersion': expectedVersion,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> _sanitizeData(
    EntityType entityType,
    SyncOperation operation,
    Map<String, dynamic> raw,
  ) {
    if (operation == SyncOperation.DELETE) {
      return {};
    }

    switch (entityType) {
      case EntityType.CUSTOMER:
        final contact =
            (raw['contactInformation'] ??
                    raw['contact_information'] ??
                    raw['contactPerson'] ??
                    raw['contact_person'])
                as String? ??
            '';
        return {
          'name': raw['name'] as String? ?? '',
          'contactInformation': contact,
        };

      case EntityType.SITE:
        final siteName =
            (raw['siteName'] ?? raw['site_name'] ?? raw['name']) as String? ??
            '';
        final customerId =
            (raw['customerId'] ?? raw['customer_id']) as String? ?? '';
        final address = raw['address'] as String? ?? '';
        return {
          'siteName': siteName,
          'address': address,
          'customerId': customerId,
        };

      case EntityType.NOTE:
        final siteId = (raw['siteId'] ?? raw['site_id']) as String? ?? '';
        final title = raw['title'] as String? ?? '';
        final description =
            (raw['description'] ?? raw['notes']) as String? ?? '';
        final photoId =
            raw['photoId'] as String? ??
            raw['photo_id'] as String? ??
            ((raw['photos'] is List && (raw['photos'] as List).isNotEmpty)
                ? (raw['photos'] as List).first.toString()
                : null);
        final occurredAt =
            (raw['occurredAt'] ??
                    raw['occurred_at'] ??
                    raw['createdAt'] ??
                    raw['created_at'])
                as String? ??
            DateTime.now().toUtc().toIso8601String();
        final status = raw['status'] as String? ?? 'OPEN';

        return {
          'siteId': siteId,
          'title': title,
          'description': description,
          'status': status,
          // Older queued notes stored local timestamps without an offset.
          'occurredAt':
              DateTime.tryParse(occurredAt)?.toUtc().toIso8601String() ??
              occurredAt,
          'photoId': ?photoId,
        };
    }
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'mutationId': mutationId,
      'entityType': entityType.name,
      'entityId': entityId,
      'operation': operation.name,
      'expectedVersion': expectedVersion,
      'data': _sanitizeData(entityType, operation, data),
    };
  }
}

class SyncAck {
  final String mutationId;
  final EntityType entityType;
  final String entityId;
  final int version;
  final int revision;
  final Map<String, dynamic> data;

  const SyncAck({
    required this.mutationId,
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.revision,
    required this.data,
  });

  factory SyncAck.fromJson(Map<String, dynamic> json) {
    return SyncAck(
      mutationId: json['mutationId'] as String? ?? '',
      entityType: EntityType.values.firstWhere(
        (e) => e.name == json['entityType'],
        orElse: () => EntityType.NOTE,
      ),
      entityId: json['entityId'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      data:
          (json['data'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
          {},
    );
  }
}

class SyncChange {
  final int revision;
  final EntityType entityType;
  final String entityId;
  final Map<String, dynamic> data;

  const SyncChange({
    required this.revision,
    required this.entityType,
    required this.entityId,
    required this.data,
  });

  factory SyncChange.fromJson(Map<String, dynamic> json) {
    return SyncChange(
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      entityType: EntityType.values.firstWhere(
        (e) => e.name == json['entityType'],
        orElse: () => EntityType.NOTE,
      ),
      entityId: json['entityId'] as String? ?? '',
      data:
          (json['data'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
          {},
    );
  }
}

class SyncPullResponse {
  final List<SyncChange> changes;
  final int nextCursor;
  final bool hasMore;

  const SyncPullResponse({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    return SyncPullResponse(
      changes:
          (json['changes'] as List<dynamic>?)
              ?.map(
                (e) => SyncChange.fromJson((e as Map).cast<String, dynamic>()),
              )
              .toList() ??
          [],
      nextCursor: (json['nextCursor'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
