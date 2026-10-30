import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage_provider.dart';
import 'auth_interceptor.dart';
import 'session_notifier.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required this.dio});

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Exception _handleDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;

    String errorMessage = 'A network error occurred. Please try again.';

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      if (data.containsKey('message') && data['message'] != null) {
        errorMessage = data['message'].toString();
      }
    } else if (error.message != null && error.message!.isNotEmpty) {
      errorMessage = error.message!;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please check your internet connectivity.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection detected. Please verify your connection.',
        );
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return AuthException(message: errorMessage, statusCode: 401);
        }
        return ServerException(message: errorMessage, statusCode: statusCode);
      case DioExceptionType.cancel:
        return const ServerException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ServerException(message: 'Security certificate verification failed.');
      case DioExceptionType.unknown:
      default:
        return ServerException(message: errorMessage);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  final sessionNotifier = ref.watch(sessionNotifierProvider);

  final baseOptions = BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(baseOptions);

  dio.interceptors.add(
    AuthInterceptor(
      storageService: storageService,
      onUnauthorized: () {
        sessionNotifier.notifySessionExpired();
      },
    ),
  );

  // Only attach LogInterceptor in debug builds to prevent information leakage
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ),
    );
  }

  return ApiClient(dio: dio);
});
