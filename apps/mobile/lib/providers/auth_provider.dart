import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _user;
  String? _accessToken;
  String? _refreshToken;

  AuthProvider(this._authService);

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final result = await _authService.tryAutoLogin();
      if (result != null) {
        _user = result.user;
        _accessToken = result.accessToken;
        _refreshToken = result.refreshToken;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _user = result.user;
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      final message = e.toString();
      if (message.contains('Invalid email or password')) {
        _errorMessage = 'Email atau password salah';
      } else if (message.contains('No active tenant')) {
        _errorMessage = 'Akun tidak memiliki akses ke tenant';
      } else {
        _errorMessage = 'Gagal masuk. Periksa koneksi internet Anda.';
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(request);
      _user = result.user;
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      final message = e.toString();
      if (message.contains('Email already registered')) {
        _errorMessage = 'Email sudah terdaftar';
      } else if (message.contains('already exists')) {
        _errorMessage = 'Nama perusahaan sudah digunakan';
      } else {
        _errorMessage = 'Gagal mendaftar. Periksa kembali data Anda.';
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
