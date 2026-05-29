import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;
  final List<void Function(String)> _pendingRequests = [];

  ApiClient() : _storage = const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(_authInterceptor());
  }

  Dio get dio => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: ApiConfig.authTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);
          if (refreshToken == null) {
            handler.next(error);
            return;
          }
          try {
            final newToken = await _refreshToken(refreshToken);
            if (newToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (_) {
            await _clearAuth();
          }
        }
        handler.next(error);
      },
    );
  }

  Future<String?> _refreshToken(String refreshToken) async {
    if (!_isRefreshing) {
      _isRefreshing = true;
      try {
        final response = await Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
          ),
        ).post(
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
        for (final pending in _pendingRequests) {
          pending(newToken);
        }
        _pendingRequests.clear();
        return newToken;
      } catch (e) {
        await _clearAuth();
        return null;
      } finally {
        _isRefreshing = false;
      }
    } else {
      final completer = Completer<String>();
      _pendingRequests.add(completer.complete);
      return await completer.future;
    }
  }

  Future<void> _clearAuth() async {
    await _storage.delete(key: ApiConfig.authTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userDataKey);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Future<Response> upload(
    String path, {
    required String filePath,
    String fieldName = 'file',
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
    });
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onProgress,
    );
  }
}
