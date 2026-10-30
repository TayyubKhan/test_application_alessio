import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/cart_controller.dart';
import '../../domain/cart_item_entity.dart';


class CartItemTile extends ConsumerWidget {
  final CartItemEntity item;

  const CartItemTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = item.product;
    final remainingStock = ref.watch(productRemainingStockProvider(product));

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 76,
                height: 76,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                child: product.thumbnail.isNotEmpty
                    ? Image.network(
                        product.thumbnail,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 24,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${product.discountedPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($remainingStock left)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: remainingStock > 0
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quantity Stepper Controls
                  Row(
                    children: [
                      _buildStepperButton(
                        context,
                        icon: item.quantity > 1
                            ? Icons.remove_rounded
                            : Icons.delete_outline_rounded,
                        color: item.quantity > 1 ? null : theme.colorScheme.error,
                        onPressed: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .decrementQuantity(product.id);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Text(
                            '${item.quantity}',
                            key: ValueKey<int>(item.quantity),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _buildStepperButton(
                        context,
                        icon: Icons.add_rounded,
                        onPressed: remainingStock > 0
                            ? () {
                                ref
                                    .read(cartControllerProvider.notifier)
                                    .addToCart(product);
                              }
                            : null,
                      ),
                      const Spacer(),

                      // Total for this line item
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
              : (color ?? theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
