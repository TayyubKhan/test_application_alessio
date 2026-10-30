import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

class AuthInterceptor extends QueuedInterceptor {
  final ISecureStorageService _storageService;
  final OnUnauthorizedCallback? _onUnauthorized;
  final Dio _refreshDio;

  AuthInterceptor({
    required ISecureStorageService storageService,
    OnUnauthorizedCallback? onUnauthorized,
    Dio? refreshDio,
  })  : _storageService = storageService,
        _onUnauthorized = onUnauthorized,
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

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
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Only handle 401 Unauthorized
    if (statusCode != 401) {
      return handler.next(err);
    }

    // If login returned 401 (invalid credentials), do not attempt refresh or wipe session
    if (path.contains(ApiEndpoints.login)) {
      return handler.next(err);
    }

    // If the refresh call itself failed with 401, clear credentials and evict
    if (path.contains(ApiEndpoints.refresh)) {
      await _clearSessionAndNotify();
      return handler.next(err);
    }

    // Try refreshing the access token
    try {
      final refreshToken = await _storageService.read(StorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSessionAndNotify();
        return handler.next(err);
      }

      final refreshResponse = await _refreshDio.post(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': refreshToken,
          'expiresInMins': ApiEndpoints.tokenExpiryMins,
        },
      );

      final data = refreshResponse.data;
      if (data is Map<String, dynamic>) {
        final newAccessToken =
            data['accessToken'] as String? ?? data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await _storageService.write(StorageKeys.accessToken, newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await _storageService.write(StorageKeys.refreshToken, newRefreshToken);
          }

          // Keep cached user entity in sync
          final userJson = await _storageService.read(StorageKeys.userCache);
          if (userJson != null && userJson.isNotEmpty) {
            try {
              final userMap = jsonDecode(userJson) as Map<String, dynamic>;
              userMap['accessToken'] = newAccessToken;
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                userMap['refreshToken'] = newRefreshToken;
              }
              await _storageService.write(StorageKeys.userCache, jsonEncode(userMap));
            } catch (_) {
              // Ignore cache serialization error
            }
          }

          // Retry the original request with the new access token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final response = await _refreshDio.fetch(requestOptions);
          return handler.resolve(response);
        }
      }

      await _clearSessionAndNotify();
      return handler.next(err);
    } catch (_) {
      await _clearSessionAndNotify();
      return handler.next(err);
    }
  }

  Future<void> _clearSessionAndNotify() async {
    await _storageService.delete(StorageKeys.accessToken);
    await _storageService.delete(StorageKeys.refreshToken);
    await _storageService.delete(StorageKeys.userCache);
    _onUnauthorized?.call();
  }
}
