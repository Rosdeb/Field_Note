class User {
  final String id;
  final String email;

  const User({
    required this.id,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['userId']) as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }
}

class Session {
  final String userId;
  final String email;
  final String token;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final String? expiresAt;
  final String? refreshExpiresAt;

  const Session({
    required this.userId,
    required this.email,
    required this.token,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
    this.expiresAt,
    this.refreshExpiresAt,
  });

  String get effectiveAccessToken => accessToken ?? token;

  factory Session.fromJson(Map<String, dynamic> json) {
    final tokenVal = json['accessToken'] as String? ?? json['token'] as String? ?? '';
    return Session(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: tokenVal,
      accessToken: tokenVal,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      expiresAt: json['expiresAt'] as String?,
      refreshExpiresAt: json['refreshExpiresAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'token': effectiveAccessToken,
      'accessToken': ?accessToken,
      'refreshToken': ?refreshToken,
      'tokenType': ?tokenType,
      'expiresIn': ?expiresIn,
      'expiresAt': ?expiresAt,
      'refreshExpiresAt': ?refreshExpiresAt,
    };
  }
}
