class ApiConfig {
  // Ubah ke false untuk pakai server lokal (http://localhost:5000)
  static const bool useLocal = false;

  static String get baseUrl {
    if (useLocal) {
      return 'http://10.0.2.2:5000/api/v1'; // Android emulator → localhost
    }
    return 'https://jagafinance-production.up.railway.app/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Timeout khusus untuk logout — ga usah nunggu lama
  static const Duration logoutTimeout = Duration(seconds: 5);

  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);

  static const int maxUploadSize = 10 * 1024 * 1024;

  static const String authTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String userDataKey = 'auth_user_data';
}