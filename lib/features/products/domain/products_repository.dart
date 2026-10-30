import 'product_entity.dart';
import 'products_page_entity.dart';

abstract class ProductsRepository {
  Future<ProductsPageEntity> getProducts({
    int limit = 20,
    int skip = 0,
  });

  Future<ProductEntity> getProductById(int id);
}
