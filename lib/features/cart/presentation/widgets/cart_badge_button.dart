import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/cart_controller.dart';

class CartBadgeButton extends ConsumerWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartTotalCountProvider);
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Shopping Cart',
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () {
            context.push('/cart');
          },
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
