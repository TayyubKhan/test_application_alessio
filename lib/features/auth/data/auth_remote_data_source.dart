import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> login({
    required String username,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'username': username.trim(),
          'password': password.trim(),
          'expiresInMins': 60,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return UserEntity.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to authenticate user',
          statusCode: response.statusCode,
        );
      }
    } on Exception {
      rethrow;
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});
