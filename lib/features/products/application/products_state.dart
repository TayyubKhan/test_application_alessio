import '../domain/product_entity.dart';

class ProductsState {
  final List<ProductEntity> products;
  final int total;
  final int skip;
  final bool hasMore;
  final bool isLoadingMore;
  final String? paginationError;

  const ProductsState({
    required this.products,
    required this.total,
    required this.skip,
    required this.hasMore,
    this.isLoadingMore = false,
    this.paginationError,
  });

  factory ProductsState.initial() {
    return const ProductsState(
      products: [],
      total: 0,
      skip: 0,
      hasMore: true,
      isLoadingMore: false,
      paginationError: null,
    );
  }

  bool get isEmpty => products.isEmpty;

  ProductsState copyWith({
    List<ProductEntity>? products,
    int? total,
    int? skip,
    bool? hasMore,
    bool? isLoadingMore,
    String? paginationError,
  }) {
    return ProductsState(
      products: products ?? this.products,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: paginationError,
    );
  }
}
