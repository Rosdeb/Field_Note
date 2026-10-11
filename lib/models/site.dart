class Site {
  final String id;
  final String customerId;
  final String name;
  final String siteName;
  final String address;
  final String? customerName;
  final int version;
  final String? createdAt;
  final String? updatedAt;

  const Site({
    required this.id,
    required this.customerId,
    required this.name,
    String? siteName,
    this.address = '',
    this.customerName,
    this.version = 0,
    this.createdAt,
    this.updatedAt,
  }) : siteName = siteName ?? name;

  Site copyWith({
    String? id,
    String? customerId,
    String? name,
    String? siteName,
    String? address,
    String? customerName,
    int? version,
    String? createdAt,
    String? updatedAt,
  }) {
    final effectiveName = siteName ?? name ?? this.siteName;
    return Site(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? effectiveName,
      siteName: effectiveName,
      address: address ?? this.address,
      customerName: customerName ?? this.customerName,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Site.fromJson(Map<String, dynamic> json) {
    final sName = (json['siteName'] ?? json['site_name'] ?? json['name']) as String? ?? '';
    return Site(
      id: json['id'] as String? ?? '',
      customerId: (json['customerId'] ?? json['customer_id']) as String? ?? '',
      name: sName,
      siteName: sName,
      address: json['address'] as String? ?? '',
      customerName: json['customerName'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveName = siteName.isNotEmpty ? siteName : name;
    return {
      'id': id,
      'customerId': customerId,
      'name': effectiveName,
      'siteName': effectiveName,
      'address': address,
      'version': version,
      'customerName': ?customerName,
      'createdAt': ?createdAt,
      'updatedAt': ?updatedAt,
    };
  }

  Map<String, dynamic> toWritePayload() {
    final effectiveName = siteName.isNotEmpty ? siteName : name;
    return {
      'siteName': effectiveName,
      'address': address,
      'customerId': customerId,
    };
  }
}
