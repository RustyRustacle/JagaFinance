class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? phone;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'phone': phone,
      };
}

class Tenant {
  final String id;
  final String name;
  final String slug;
  final String? role;

  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    this.role,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      role: json['role'] as String?,
    );
  }
}

class AuthResponse {
  final User user;
  final List<Tenant>? tenants;
  final Tenant? tenant;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    this.tenants,
    this.tenant,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tenants: (json['tenants'] as List<dynamic>?)
          ?.map((t) => Tenant.fromJson(t as Map<String, dynamic>))
          .toList(),
      tenant: json['tenant'] != null
          ? Tenant.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final String tenantName;
  final String tenantSlug;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.tenantName,
    required this.tenantSlug,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'tenantName': tenantName,
        'tenantSlug': tenantSlug,
      };
}
