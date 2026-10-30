import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_repository.dart';
import '../domain/user_entity.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final ISecureStorageService _storageService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required ISecureStorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService;

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        username: username,
        password: password,
      );

      // Securely store credentials
      await _storageService.write(StorageKeys.accessToken, user.accessToken);
      if (user.refreshToken != null) {
        await _storageService.write(StorageKeys.refreshToken, user.refreshToken!);
      }
      await _storageService.write(StorageKeys.userCache, jsonEncode(user.toJson()));

      return user;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _storageService.delete(StorageKeys.accessToken);
      await _storageService.delete(StorageKeys.refreshToken);
      await _storageService.delete(StorageKeys.userCache);
    } catch (e) {
      throw StorageFailure('Failed to clear secure storage during logout: $e');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userJson = await _storageService.read(StorageKeys.userCache);
      if (userJson != null && userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        return UserEntity.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await _storageService.read(StorageKeys.accessToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );
});
