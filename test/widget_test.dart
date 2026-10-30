import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testtask/core/constants/storage_keys.dart';
import 'package:testtask/core/storage/secure_storage_provider.dart';
import 'package:testtask/core/storage/secure_storage_service.dart';
import 'package:testtask/features/auth/domain/user_entity.dart';
import 'package:testtask/features/auth/presentation/screens/login_screen.dart';
import 'package:testtask/features/cart/application/cart_controller.dart';
import 'package:testtask/features/products/domain/product_entity.dart';
import 'package:testtask/features/products/presentation/screens/products_list_screen.dart';
import 'package:testtask/main.dart';

class MockSecureStorageService implements ISecureStorageService {
  final Map<String, String> _storage = {};

  MockSecureStorageService([Map<String, String>? initial]) {
    if (initial != null) {
      _storage.addAll(initial);
    }
  }

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);
}

void main() {
  group('Entity Tests', () {
    test('UserEntity parses correctly from json', () {
      final json = {
        'id': 1,
        'username': 'emilys',
        'email': 'emily@example.com',
        'firstName': 'Emily',
        'lastName': 'Johnson',
        'gender': 'female',
        'image': 'https://dummyjson.com/icon/emilys/128',
        'accessToken': 'test_token',
      };

      final user = UserEntity.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'emilys');
      expect(user.fullName, 'Emily Johnson');
      expect(user.accessToken, 'test_token');
    });

    test('ProductEntity calculates discounted price correctly', () {
      const product = ProductEntity(
        id: 1,
        title: 'Test Product',
        description: 'Test description',
        category: 'beauty',
        price: 100.0,
        discountPercentage: 20.0,
        rating: 4.5,
        stock: 10,
        thumbnail: 'https://example.com/thumb.jpg',
        images: [],
        tags: ['beauty'],
      );

      expect(product.discountedPrice, 80.0);
    });
  });

  group('Cart Controller Tests', () {
    test('Adding product to cart reduces remaining stock correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const product = ProductEntity(
        id: 42,
        title: 'Mascara',
        description: 'Desc',
        category: 'beauty',
        price: 20.0,
        discountPercentage: 0.0,
        rating: 4.5,
        stock: 5,
        thumbnail: '',
        images: [],
        tags: [],
      );

      final controller = container.read(cartControllerProvider.notifier);

      expect(container.read(productRemainingStockProvider(product)), 5);

      controller.addToCart(product);
      expect(container.read(productRemainingStockProvider(product)), 4);
      expect(container.read(cartTotalCountProvider), 1);

      controller.decrementQuantity(product.id);
      expect(container.read(productRemainingStockProvider(product)), 5);
      expect(container.read(cartTotalCountProvider), 0);
    });
  });

  group('Session & Widget Tests', () {
    testWidgets('App displays LoginScreen initially when unauthenticated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(MockSecureStorageService()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('App never shows LoginScreen on cold start when token exists in storage', (tester) async {
      final mockUser = {
        'id': 1,
        'username': 'emilys',
        'email': 'emily@example.com',
        'firstName': 'Emily',
        'lastName': 'Johnson',
        'gender': 'female',
        'image': '',
        'accessToken': 'valid_jwt_token',
      };

      final mockStorage = MockSecureStorageService({
        StorageKeys.accessToken: 'valid_jwt_token',
        StorageKeys.userCache: jsonEncode(mockUser),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MyApp(),
        ),
      );

      // Verify that during initial frame, LoginScreen is NOT rendered
      expect(find.byType(LoginScreen), findsNothing);

      await tester.pumpAndSettle();

      // Navigated directly to ProductsListScreen, LoginScreen was never shown
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(ProductsListScreen), findsOneWidget);
    });
  });
}
