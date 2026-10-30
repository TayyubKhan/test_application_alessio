import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testtask/core/theme/theme_provider.dart';
import 'package:testtask/core/widgets/custom_error_widget.dart';
import 'package:testtask/core/widgets/custom_loading_indicator.dart';
import 'package:testtask/core/widgets/empty_state_widget.dart';
import 'package:testtask/features/auth/application/auth_controller.dart';
import 'package:testtask/features/cart/presentation/widgets/cart_badge_button.dart';
import 'package:testtask/features/products/application/products_controller.dart';
import 'package:testtask/features/products/application/products_state.dart';
import 'package:testtask/features/products/presentation/widgets/product_card.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger load more when user is 250 pixels away from bottom
    if (maxScroll - currentScroll <= 250) {
      ref.read(productsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(productsControllerProvider.notifier).refresh();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your current session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Products'),
            if (authState.user != null)
              Text(
                'Hi, ${authState.user!.firstName.isNotEmpty ? authState.user!.firstName : authState.user!.username}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 22,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),

          // Cart Button with Count Badge
          const CartBadgeButton(),

          // Logout Button
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        loading: () => const CustomLoadingIndicator(
          message: 'Loading catalog products...',
        ),
        error: (error, _) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.read(productsControllerProvider.notifier).loadInitial(),
        ),
        data: (productsState) {
          if (productsState.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: EmptyStateWidget(
                      title: 'No Products Available',
                      message: 'We couldn\'t find any products in the catalog right now.',
                      onAction: _onRefresh,
                      actionLabel: 'Refresh',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: productsState.products.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Bottom footer (loading more, error, or end of list message)
                if (index >= productsState.products.length) {
                  return _buildPaginationFooter(productsState);
                }

                final product = productsState.products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    context.push('/products/${product.id}', extra: product);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationFooter(ProductsState state) {
    final theme = Theme.of(context);

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (state.paginationError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Column(
            children: [
              Text(
                state.paginationError!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.read(productsControllerProvider.notifier).loadMore(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Loading More'),
              ),
            ],
          ),
        ),
      );
    }

    // End of Catalog reached
    if (!state.hasMore && state.products.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve viewed all ${state.total} products',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
