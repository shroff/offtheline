import 'dart:async';

abstract class ProxiedStorage {
  FutureOr<bool> initialize();

  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});

  Future<void> deleteAll();
}
