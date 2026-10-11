class FieldNote {
  final String id;
  final String siteId;
  final String customerId;
  final String title;
  final String notes;
  final String description;
  final String status; // DRAFT, OPEN, IN_PROGRESS, COMPLETED
  final List<String> photos;
  final String? photoId;
  final double? latitude;
  final double? longitude;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime occurredAt;
  final bool isSynced;

  FieldNote({
    required this.id,
    required this.siteId,
    required this.customerId,
    required this.title,
    String? notes,
    String? description,
    this.status = 'OPEN',
    this.photos = const [],
    this.photoId,
    this.latitude,
    this.longitude,
    this.version = 0,
    required this.createdAt,
    this.updatedAt,
    DateTime? occurredAt,
    this.isSynced = false,
  }) : notes = notes ?? description ?? '',
       description = description ?? notes ?? '',
       occurredAt = occurredAt ?? createdAt;

  FieldNote copyWith({
    String? id,
    String? siteId,
    String? customerId,
    String? title,
    String? notes,
    String? description,
    String? status,
    List<String>? photos,
    String? photoId,
    double? latitude,
    double? longitude,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? occurredAt,
    bool? isSynced,
  }) {
    final effectiveText = description ?? notes ?? this.notes;
    final effectiveCreated = createdAt ?? this.createdAt;
    return FieldNote(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      notes: notes ?? effectiveText,
      description: description ?? effectiveText,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      photoId: photoId ?? this.photoId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      version: version ?? this.version,
      createdAt: effectiveCreated,
      updatedAt: updatedAt ?? this.updatedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory FieldNote.fromJson(Map<String, dynamic> json) {
    final noteText = (json['description'] ?? json['notes']) as String? ?? '';
    final photoIdVal =
        json['photoId'] as String? ?? json['photo_id'] as String?;
    final photosList =
        (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        (photoIdVal != null && photoIdVal.isNotEmpty
            ? [photoIdVal]
            : <String>[]);
    final created =
        DateTime.tryParse(
          json['createdAt'] as String? ??
              json['created_at'] as String? ??
              json['occurredAt'] as String? ??
              json['occurred_at'] as String? ??
              '',
        ) ??
        DateTime.now();
    final occurred =
        DateTime.tryParse(
          json['occurredAt'] as String? ?? json['occurred_at'] as String? ?? '',
        ) ??
        created;

    return FieldNote(
      id: json['id'] as String? ?? '',
      siteId: (json['siteId'] ?? json['site_id']) as String? ?? '',
      customerId: (json['customerId'] ?? json['customer_id']) as String? ?? '',
      title: json['title'] as String? ?? '',
      notes: noteText,
      description: noteText,
      status: json['status'] as String? ?? 'OPEN',
      photos: photosList,
      photoId: photoIdVal ?? (photosList.isNotEmpty ? photosList.first : null),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdAt: created,
      updatedAt: DateTime.tryParse(
        json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
      ),
      occurredAt: occurred,
      isSynced:
          json['isSynced'] as bool? ?? json['is_synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveText = description.isNotEmpty ? description : notes;
    final effectivePhotoId =
        photoId ?? (photos.isNotEmpty ? photos.first : null);
    return {
      'id': id,
      'siteId': siteId,
      'customerId': customerId,
      'title': title,
      'notes': effectiveText,
      'description': effectiveText,
      'status': status,
      'photos': photos,
      'photoId': ?effectivePhotoId,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'updatedAt': ?updatedAt?.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toWritePayload() {
    final effectiveText = description.isNotEmpty ? description : notes;
    final effectivePhotoId =
        photoId ?? (photos.isNotEmpty ? photos.first : null);
    return {
      'siteId': siteId,
      'title': title,
      'description': effectiveText,
      'status': status,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'photoId': ?effectivePhotoId,
    };
  }
}
