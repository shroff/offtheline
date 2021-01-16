
import 'package:localstorage/localstorage.dart';

abstract class Storage {
  Future<void> initialize();

  Future<String> read({String key});

  Future<void> write({String key, String value});

  Future<void> delete({String key});

  Future<void> deleteAll();
}

class ProxiedLocalStorage extends Storage {
  final LocalStorage storage;

  ProxiedLocalStorage(String filename) : storage = LocalStorage('$filename.json');

  @override
  Future<void> initialize() async {
    return storage.ready;
  }

  @override
  Future<String> read({String key}) async {
    return storage.getItem(key);
  }

  @override
  Future<void> write({String key, String value}) async {
    return storage.setItem(key, value);
  }

  @override
  Future<void> delete({String key}) async {
    return storage.deleteItem(key);
  }

  @override
  Future<void> deleteAll() async {
    return storage.clear();
  }
}