import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
          ),
        ),
        _storage = const FlutterSecureStorage();

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(data);

    await _storage.write(key: ApiConfig.authTokenKey, value: authResponse.accessToken);
    await _storage.write(key: ApiConfig.refreshTokenKey, value: authResponse.refreshToken);
    await _storage.write(key: ApiConfig.userDataKey, value: authResponse.user.name ?? authResponse.user.email);

    return authResponse;
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      '/auth/register',
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(data);

    await _storage.write(key: ApiConfig.authTokenKey, value: authResponse.accessToken);
    await _storage.write(key: ApiConfig.refreshTokenKey, value: authResponse.refreshToken);
    await _storage.write(key: ApiConfig.userDataKey, value: authResponse.user.name ?? authResponse.user.email);

    return authResponse;
  }

  Future<void> logout() async {
    try {
      final token = await _storage.read(key: ApiConfig.authTokenKey);
      if (token != null) {
        await _dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {}
    await _storage.delete(key: ApiConfig.authTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userDataKey);
  }

  Future<AuthResponse?> tryAutoLogin() async {
    final token = await _storage.read(key: ApiConfig.authTokenKey);
    final refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);
    final userName = await _storage.read(key: ApiConfig.userDataKey);

    if (token == null || refreshToken == null) return null;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final newToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String?;

      await _storage.write(key: ApiConfig.authTokenKey, value: newToken);
      if (newRefreshToken != null) {
        await _storage.write(key: ApiConfig.refreshTokenKey, value: newRefreshToken);
      }

      final userResponse = await _dio.get(
        '/tenants/current',
        options: Options(headers: {'Authorization': 'Bearer $newToken'}),
      );
      final tenantData = userResponse.data['data'] as Map<String, dynamic>;
      final members = tenantData['members'] as List<dynamic>? ?? [];
      Map<String, dynamic>? currentUser;
      for (final m in members) {
        final member = m as Map<String, dynamic>;
        final user = member['user'] as Map<String, dynamic>?;
        if (user?['email'] != null) {
          currentUser = user;
          break;
        }
      }

      return AuthResponse(
        user: User(
          id: currentUser?['id'] as String? ?? '',
          email: currentUser?['email'] as String? ?? '',
          name: currentUser?['name'] as String? ?? userName,
        ),
        accessToken: newToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );
    } catch (_) {
      await _storage.delete(key: ApiConfig.authTokenKey);
      await _storage.delete(key: ApiConfig.refreshTokenKey);
      await _storage.delete(key: ApiConfig.userDataKey);
      return null;
    }
  }
}
