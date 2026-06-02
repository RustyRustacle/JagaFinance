class ApiConfig {
  // Kita bypass sementara dari Environment, langsung tembak IP asli Laptop Anda
  static const String baseUrl = 'http://192.168.18.164:3001/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);

  static const int maxUploadSize = 10 * 1024 * 1024;

  static const String authTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String userDataKey = 'auth_user_data';
}