import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/splash_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/products/domain/product_entity.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/products_list_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);

    // Keep on splash screen while securely restoring session
    if (authState.isInitial) {
      return '/splash';
    }

    final isSplash = state.matchedLocation == '/splash';
    final isLoggingIn = state.matchedLocation == '/login';

    if (!authState.isAuthenticated) {
      return isLoggingIn ? null : '/login';
    }

    // Authenticated users cannot stay on login or splash
    if (isLoggingIn || isSplash) {
      return '/products';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final product = state.extra as ProductEntity?;
              return ProductDetailScreen(
                productId: id,
                initialProduct: product,
              );
            },
          ),
        ],
      ),
    ],
  );
});
