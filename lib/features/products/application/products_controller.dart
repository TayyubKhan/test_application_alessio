import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../data/products_repository_impl.dart';
import '../domain/products_repository.dart';
import '../../auth/application/auth_controller.dart';
import 'products_state.dart';

class ProductsController extends StateNotifier<AsyncValue<ProductsState>> {
  final ProductsRepository _repository;
  static const int _pageSize = 20;

  ProductsController({required ProductsRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final page = await _repository.getProducts(limit: _pageSize, skip: 0);
      state = AsyncValue.data(
        ProductsState(
          products: page.products,
          total: page.total,
          skip: page.skip,
          hasMore: page.hasMore,
        ),
      );
    } on Failure catch (e, st) {
      state = AsyncValue.error(e.message, st);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _repository.getProducts(limit: _pageSize, skip: 0);
      state = AsyncValue.data(
        ProductsState(
          products: page.products,
          total: page.total,
          skip: page.skip,
          hasMore: page.hasMore,
        ),
      );
    } on Failure catch (e, st) {
      // If refresh fails and we already had data, preserve it or surface error
      if (!state.hasValue) {
        state = AsyncValue.error(e.message, st);
      }
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e.toString(), st);
      }
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, paginationError: null),
    );

    try {
      final nextSkip = currentState.products.length;
      final page = await _repository.getProducts(
        limit: _pageSize,
        skip: nextSkip,
      );

      final combined = [...currentState.products, ...page.products];

      state = AsyncValue.data(
        currentState.copyWith(
          products: combined,
          total: page.total,
          skip: page.skip,
          hasMore: (nextSkip + page.products.length) < page.total,
          isLoadingMore: false,
          paginationError: null,
        ),
      );
    } on Failure catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          paginationError: e.message,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          paginationError: 'Failed to load more products: $e',
        ),
      );
    }
  }
}

final productsControllerProvider =
    StateNotifierProvider<ProductsController, AsyncValue<ProductsState>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(productsRepositoryProvider);

  final controller = ProductsController(repository: repository);
  if (authState.isAuthenticated) {
    controller.loadInitial();
  }
  return controller;
});
