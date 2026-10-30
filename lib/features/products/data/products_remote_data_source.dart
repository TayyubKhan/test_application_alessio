import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../domain/product_entity.dart';
import '../domain/products_page_entity.dart';

abstract class ProductsRemoteDataSource {
  Future<ProductsPageEntity> getProducts({
    required int limit,
    required int skip,
  });

  Future<ProductEntity> getProductById(int id);
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final ApiClient _apiClient;

  ProductsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ProductsPageEntity> getProducts({
    required int limit,
    required int skip,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.products,
        queryParameters: {
          'limit': limit,
          'skip': skip,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return ProductsPageEntity.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to retrieve products',
          statusCode: response.statusCode,
        );
      }
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<ProductEntity> getProductById(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.productDetail(id));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return ProductEntity.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to retrieve product #$id',
          statusCode: response.statusCode,
        );
      }
    } on Exception {
      rethrow;
    }
  }
}

final productsRemoteDataSourceProvider = Provider<ProductsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductsRemoteDataSourceImpl(apiClient: apiClient);
});
