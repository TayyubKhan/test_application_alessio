import '../../products/domain/product_entity.dart';

class CartItemEntity {
  final ProductEntity product;
  final int quantity;

  const CartItemEntity({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.discountedPrice * quantity;

  CartItemEntity copyWith({
    ProductEntity? product,
    int? quantity,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemEntity &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;
}
