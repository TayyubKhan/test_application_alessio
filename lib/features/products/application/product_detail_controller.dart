import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/products_repository_impl.dart';
import '../domain/product_entity.dart';

final productDetailProvider =
    FutureProvider.family<ProductEntity, int>((ref, productId) async {
  final repository = ref.watch(productsRepositoryProvider);
  return await repository.getProductById(productId);
});
