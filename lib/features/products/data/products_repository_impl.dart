import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../domain/product_entity.dart';
import '../domain/products_page_entity.dart';
import '../domain/products_repository.dart';
import 'products_remote_data_source.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remoteDataSource;

  ProductsRepositoryImpl({
    required ProductsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<ProductsPageEntity> getProducts({
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      return await _remoteDataSource.getProducts(limit: limit, skip: skip);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(e.toString());
    }
  }

  @override
  Future<ProductEntity> getProductById(int id) async {
    try {
      return await _remoteDataSource.getProductById(id);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(e.toString());
    }
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final remoteDataSource = ref.watch(productsRemoteDataSourceProvider);
  return ProductsRepositoryImpl(remoteDataSource: remoteDataSource);
});
