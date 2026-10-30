import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

final secureStorageServiceProvider = Provider<ISecureStorageService>((ref) {
  return SecureStorageService();
});
