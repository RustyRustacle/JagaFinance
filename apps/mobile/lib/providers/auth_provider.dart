import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ApiClient _api;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  List<Tenant> _tenants = [];
  Tenant? _activeTenant;
  String? _error;

  AuthProvider(this._api)
      : _authService = AuthService(_api);

  AuthStatus get status => _status;
  User? get user => _user;
  List<Tenant> get tenants => _tenants;
  Tenant? get activeTenant => _activeTenant;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> tryAutoLogin() async {
    final hasSession = await _authService.tryAutoLogin();
    if (hasSession) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _user = result.user;
      _tenants = result.tenants;
      _activeTenant = result.tenants.isNotEmpty ? result.tenants.first : null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to connect to server';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String tenantName,
    required String tenantSlug,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        tenantName: tenantName,
        tenantSlug: tenantSlug,
      );
      _user = result.user;
      _tenants = result.tenants;
      _activeTenant = result.tenants.isNotEmpty ? result.tenants.first : null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to connect to server';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _tenants = [];
    _activeTenant = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
