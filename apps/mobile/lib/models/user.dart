class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
      };
}

class Tenant {
  final String id;
  final String name;
  final String slug;
  final String role;

  Tenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      role: json['role'] as String? ?? 'VIEWER',
    );
  }
}

class AuthResponse {
  final User user;
  final List<Tenant> tenants;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.tenants,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final tenantsList = (json['tenants'] as List<dynamic>?) ?? [];

    return AuthResponse(
      user: User(
        id: userJson['id'] as String,
        email: userJson['email'] as String,
        name: userJson['name'] as String?,
      ),
      tenants: tenantsList
          .map((t) => Tenant.fromJson(t as Map<String, dynamic>))
          .toList(),
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

  RegisterRequest({
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
