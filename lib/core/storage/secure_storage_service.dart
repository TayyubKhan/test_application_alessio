import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../errors/exceptions.dart';

abstract class ISecureStorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
}

class SecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to read key $key: ${e.toString()}');
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException(message: 'Failed to write key $key: ${e.toString()}');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to delete key $key: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(message: 'Failed to clear secure storage: ${e.toString()}');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to check key $key: ${e.toString()}');
    }
  }
}
