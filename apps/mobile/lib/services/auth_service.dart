import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessKey = 'jagafinance_access_token';
  static const _refreshKey = 'jagafinance_refresh_token';
  static const _userKey = 'jagafinance_user';
  static const _tenantKey = 'jagafinance_tenant';

  AuthService(this._api);

  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final result = AuthResponse.fromJson(response['data'] as Map<String, dynamic>);
    await _persistSession(result);
    return result;
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String tenantName,
    required String tenantSlug,
  }) async {
    final response = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      'tenantName': tenantName,
      'tenantSlug': tenantSlug,
    });

    final result = AuthResponse.fromJson(response['data'] as Map<String, dynamic>);
    await _persistSession(result);
    return result;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _clearSession();
  }

  Future<bool> tryAutoLogin() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final userData = await _storage.read(key: _userKey);

    if (access == null || refresh == null || userData == null) {
      return false;
    }

    _api.setTokens(access, refresh);

    _api.onTokenRefreshed = (newAccess, newRefresh) {
      _storage.write(key: _accessKey, value: newAccess);
      _storage.write(key: _refreshKey, value: newRefresh);
    };

    _api.onAuthFailure = () {
      _clearSession();
    };

    return true;
  }

  Future<void> _persistSession(AuthResponse result) async {
    _api.setTokens(result.accessToken, result.refreshToken);

    await _storage.write(key: _accessKey, value: result.accessToken);
    await _storage.write(key: _refreshKey, value: result.refreshToken);
    await _storage.write(key: _userKey, value: result.user.name ?? result.user.email);

    _api.onTokenRefreshed = (newAccess, newRefresh) {
      _storage.write(key: _accessKey, value: newAccess);
      _storage.write(key: _refreshKey, value: newRefresh);
    };

    _api.onAuthFailure = () {
      _clearSession();
    };
  }

  Future<void> _clearSession() async {
    _api.clearTokens();
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _tenantKey);
  }
}
