import 'dart:async';

import 'package:localstorage/localstorage.dart';

abstract class Storage {
  FutureOr<bool> initialize();

  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});

  Future<void> deleteAll();
}

class ProxiedLocalStorage extends Storage {
  final LocalStorage storage;

  ProxiedLocalStorage(String filename)
      : storage = LocalStorage('$filename.json');

  @override
  FutureOr<bool> initialize() async {
    return storage.ready;
  }

  @override
  Future<String?> read({required String key}) async {
    return storage.getItem(key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    return storage.setItem(key, value);
  }

  @override
  Future<void> delete({required String key}) async {
    return storage.deleteItem(key);
  }

  @override
  Future<void> deleteAll() async {
    return storage.clear();
  }
}
