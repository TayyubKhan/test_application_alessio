import 'package:dio/dio.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

class AuthInterceptor extends Interceptor {
  final ISecureStorageService _storageService;
  final OnUnauthorizedCallback? _onUnauthorized;

  AuthInterceptor({
    required ISecureStorageService storageService,
    OnUnauthorizedCallback? onUnauthorized,
  })  : _storageService = storageService,
        _onUnauthorized = onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid attaching token if explicitly requested or if already set
    if (!options.headers.containsKey('Authorization')) {
      final token = await _storageService.read(StorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Top Priority Security: Immediately purge stored credentials on 401
      await _storageService.delete(StorageKeys.accessToken);
      await _storageService.delete(StorageKeys.refreshToken);
      await _storageService.delete(StorageKeys.userCache);

      // Trigger session invalidation callback to update app auth state
      _onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
