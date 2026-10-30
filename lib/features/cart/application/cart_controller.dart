import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/domain/product_entity.dart';
import '../domain/cart_item_entity.dart';

class CartController extends StateNotifier<Map<int, CartItemEntity>> {
  CartController() : super({});

  void addToCart(ProductEntity product) {
    final current = state[product.id];
    final currentQty = current?.quantity ?? 0;

    if (currentQty >= product.stock) {
      return; // Stock limit reached
    }

    final newQty = currentQty + 1;
    state = {
      ...state,
      product.id: CartItemEntity(product: product, quantity: newQty),
    };
  }

  void decrementQuantity(int productId) {
    final current = state[productId];
    if (current == null) return;

    if (current.quantity <= 1) {
      deleteFromCart(productId);
    } else {
      state = {
        ...state,
        productId: current.copyWith(quantity: current.quantity - 1),
      };
    }
  }

  void deleteFromCart(int productId) {
    if (!state.containsKey(productId)) return;
    final updated = Map<int, CartItemEntity>.from(state)..remove(productId);
    state = updated;
  }

  void clearCart() {
    state = {};
  }

  int getQuantity(int productId) {
    return state[productId]?.quantity ?? 0;
  }

  int getRemainingStock(ProductEntity product) {
    final inCart = state[product.id]?.quantity ?? 0;
    return max(0, product.stock - inCart);
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, Map<int, CartItemEntity>>((ref) {
  return CartController();
});

final cartItemsProvider = Provider<List<CartItemEntity>>((ref) {
  final cartMap = ref.watch(cartControllerProvider);
  return cartMap.values.toList();
});

final cartTotalCountProvider = Provider<int>((ref) {
  final cartMap = ref.watch(cartControllerProvider);
  return cartMap.values.fold(0, (sum, item) => sum + item.quantity);
});

final cartSubtotalPriceProvider = Provider<double>((ref) {
  final cartMap = ref.watch(cartControllerProvider);
  return cartMap.values.fold(0.0, (sum, item) => sum + item.totalPrice);
});

final productRemainingStockProvider =
    Provider.family<int, ProductEntity>((ref, product) {
  final cartMap = ref.watch(cartControllerProvider);
  final inCart = cartMap[product.id]?.quantity ?? 0;
  return max(0, product.stock - inCart);
});
