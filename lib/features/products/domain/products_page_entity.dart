import 'product_entity.dart';

class ProductsPageEntity {
  final List<ProductEntity> products;
  final int total;
  final int skip;
  final int limit;

  const ProductsPageEntity({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  bool get hasMore => (skip + products.length) < total;

  factory ProductsPageEntity.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? [];
    return ProductsPageEntity(
      products: rawProducts
          .map((e) => ProductEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}
