class Customer {
  final String id;
  final String name;
  final String contactPerson;
  final String contactInformation;
  final String phone;
  final String email;
  final String address;
  final int version;
  final String? updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.contactPerson = '',
    String? contactInformation,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.version = 0,
    this.updatedAt,
  }) : contactInformation = contactInformation ?? contactPerson;

  Customer copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? contactInformation,
    String? phone,
    String? email,
    String? address,
    int? version,
    String? updatedAt,
  }) {
    final effectiveContact = contactInformation ?? contactPerson ?? this.contactInformation;
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? effectiveContact,
      contactInformation: effectiveContact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final contact = (json['contactInformation'] ??
            json['contact_information'] ??
            json['contactPerson'] ??
            json['contact_person']) as String? ??
        '';
    return Customer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contactPerson: contact,
      contactInformation: contact,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final contact = contactInformation.isNotEmpty ? contactInformation : contactPerson;
    return {
      'id': id,
      'name': name,
      'contactPerson': contact,
      'contactInformation': contact,
      'phone': phone,
      'email': email,
      'address': address,
      'version': version,
      'updatedAt': ?updatedAt,
    };
  }

  Map<String, dynamic> toWritePayload() {
    final contact = contactInformation.isNotEmpty ? contactInformation : contactPerson;
    return {
      'name': name,
      'contactInformation': contact,
    };
  }
}
