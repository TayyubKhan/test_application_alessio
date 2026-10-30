import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../data/products_repository_impl.dart';
import '../domain/products_repository.dart';
import '../../auth/application/auth_controller.dart';
import 'products_state.dart';

class ProductsController extends StateNotifier<AsyncValue<ProductsState>> {
  final ProductsRepository _repository;
  static const int _pageSize = 20;
  int _epoch = 0;

  ProductsController({required ProductsRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> loadInitial() async {
    final epoch = ++_epoch;
    state = const AsyncValue.loading();
    try {
      final page = await _repository.getProducts(limit: _pageSize, skip: 0);
      if (epoch != _epoch) return;
      state = AsyncValue.data(
        ProductsState(
          products: page.products,
          total: page.total,
          skip: page.skip,
          hasMore: page.hasMore,
        ),
      );
    } on Failure catch (e, st) {
      if (epoch != _epoch) return;
      state = AsyncValue.error(e.message, st);
    } catch (e, st) {
      if (epoch != _epoch) return;
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> refresh() async {
    final epoch = ++_epoch;
    try {
      final page = await _repository.getProducts(limit: _pageSize, skip: 0);
      if (epoch != _epoch) return;
      state = AsyncValue.data(
        ProductsState(
          products: page.products,
          total: page.total,
          skip: page.skip,
          hasMore: page.hasMore,
        ),
      );
    } on Failure catch (e, st) {
      if (epoch != _epoch) return;
      // If refresh fails and we already had data, preserve it or surface error
      if (!state.hasValue) {
        state = AsyncValue.error(e.message, st);
      }
    } catch (e) {
      if (epoch != _epoch) return;
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

    final epoch = _epoch;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, paginationError: null),
    );

    try {
      final nextSkip = currentState.products.length;
      final page = await _repository.getProducts(
        limit: _pageSize,
        skip: nextSkip,
      );

      // Discard stale pagination results if a refresh or reload happened while awaiting
      if (epoch != _epoch) return;

      final latestState = state.valueOrNull ?? currentState;
      final combined = [...latestState.products, ...page.products];

      state = AsyncValue.data(
        latestState.copyWith(
          products: combined,
          total: page.total,
          skip: page.skip,
          hasMore: (latestState.products.length + page.products.length) < page.total,
          isLoadingMore: false,
          paginationError: null,
        ),
      );
    } on Failure catch (e) {
      if (epoch != _epoch) return;
      final latestState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(
        latestState.copyWith(
          isLoadingMore: false,
          paginationError: e.message,
        ),
      );
    } catch (e) {
      if (epoch != _epoch) return;
      final latestState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(
        latestState.copyWith(
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
