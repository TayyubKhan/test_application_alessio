import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testtask/core/widgets/custom_error_widget.dart';
import 'package:testtask/core/widgets/custom_loading_indicator.dart';
import 'package:testtask/features/cart/application/cart_controller.dart';
import 'package:testtask/features/cart/presentation/widgets/cart_badge_button.dart';
import 'package:testtask/features/products/application/product_detail_controller.dart';
import 'package:testtask/features/products/domain/product_entity.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  final ProductEntity? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always watch the network provider for fresh data
    final productAsync = ref.watch(productDetailProvider(productId));

    // Use fresh API data when available, fall back to initialProduct for instant display
    final resolvedProduct = productAsync.whenOrNull(data: (p) => p) ?? initialProduct;

    if (resolvedProduct != null) {
      return _ProductDetailContent(product: resolvedProduct);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: const [
          CartBadgeButton(),
          SizedBox(width: 8),
        ],
      ),
      body: productAsync.when(
        loading: () => const CustomLoadingIndicator(
          message: 'Loading product details...',
        ),
        error: (error, _) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(productDetailProvider(productId)),
        ),
        data: (product) => _ProductDetailContent(product: product),
      ),
    );
  }
}

class _ProductDetailContent extends ConsumerStatefulWidget {
  final ProductEntity product;

  const _ProductDetailContent({required this.product});

  @override
  ConsumerState<_ProductDetailContent> createState() =>
      _ProductDetailContentState();
}

class _ProductDetailContentState extends ConsumerState<_ProductDetailContent> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final remainingStock = ref.watch(productRemainingStockProvider(product));
    final inCart = ref.watch(cartControllerProvider)[product.id]?.quantity ?? 0;

    final displayImages = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          CartBadgeButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel / Hero Image
            Hero(
              tag: 'product-thumb-${product.id}',
              child: Container(
                height: 320,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: displayImages.isNotEmpty
                    ? PageView.builder(
                        itemCount: displayImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final imageUrl = displayImages[index];
                          return InteractiveViewer(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
              ),
            ),

            // Carousel dots
            if (displayImages.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  displayImages.length,
                  (index) => Container(
                    width: _currentImageIndex == index ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Brand Chips
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (product.brand != null && product.brand!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.brand!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    product.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating & Animated Live Stock Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade800),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sleek Animated Left Items
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.4),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey<int>(remainingStock),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: remainingStock > 0
                                ? Colors.green.withValues(alpha: 0.12)
                                : theme.colorScheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            remainingStock > 0
                                ? 'In Stock ($remainingStock available)'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: remainingStock > 0
                                  ? Colors.green.shade700
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${product.discountedPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 10),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Save ${product.discountPercentage.round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About this product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),

                  // Tags
                  if (product.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Tags',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.tags
                          .map(
                            (tag) => Chip(
                              label: Text('#$tag'),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: inCart > 0
              ? Row(
                  children: [
                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              inCart == 1
                                  ? Icons.delete_outline_rounded
                                  : Icons.remove_rounded,
                              size: 18,
                              color: inCart == 1
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface,
                            ),
                            onPressed: () {
                              ref
                                  .read(cartControllerProvider.notifier)
                                  .decrementQuantity(product.id);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '$inCart',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: remainingStock > 0
                                ? () {
                                    ref
                                        .read(cartControllerProvider.notifier)
                                        .addToCart(product);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // View Cart Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/cart'),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                        label: const Text(
                          'View in Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: remainingStock > 0
                      ? () {
                          ref.read(cartControllerProvider.notifier).addToCart(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${product.title}" to cart'),
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: Colors.white,
                                onPressed: () => context.push('/cart'),
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 20, color: Colors.white),
                  label: Text(
                    remainingStock > 0 ? 'Add to Bag' : 'Out of Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
