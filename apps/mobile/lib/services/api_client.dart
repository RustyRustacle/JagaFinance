import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException({required this.message, this.statusCode, this.code});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;
  final void Function(String accessToken, String refreshToken)? onTokenRefreshed;
  final void Function()? onAuthFailure;
  String? _accessToken;
  String? _refreshToken;

  ApiClient({
    this.onTokenRefreshed,
    this.onAuthFailure,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            try {
              final refreshed = await _attemptRefresh();
              if (refreshed) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $_accessToken';
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {}
            onAuthFailure?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Future<bool> _attemptRefresh() async {
    try {
      final response = await Dio(
        BaseOptions(baseUrl: ApiConfig.baseUrl),
      ).post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String? ?? _refreshToken!;

      _accessToken = newAccess;
      _refreshToken = newRefresh;
      onTokenRefreshed?.call(newAccess, newRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    String? fileName,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (e.response?.data != null) {
      final errorData = e.response!.data;
      if (errorData is Map<String, dynamic>) {
        final error = errorData['error'] as Map<String, dynamic>?;
        if (error != null) {
          return ApiException(
            message: (error['message'] as String?) ?? 'Unknown error',
            statusCode: e.response?.statusCode,
            code: error['code'] as String?,
          );
        }
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Connection timed out. Please check your internet.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'No internet connection.');
      default:
        return ApiException(message: e.message ?? 'An unexpected error occurred');
    }
  }
}
