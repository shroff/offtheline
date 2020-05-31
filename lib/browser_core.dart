import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:localstorage/localstorage.dart';

import 'storage.dart';

BaseClient createHttpClient() => BrowserClient()..withCredentials = true;

Storage createStorage() => _ProxiedLocalStorage('core');

class _ProxiedLocalStorage extends Storage {
  final LocalStorage storage;

  _ProxiedLocalStorage(String filename) : storage = LocalStorage('$filename.json');

  @override
  Future<void> initialize() async {
    return storage.ready;
  }

  @override
  Future<dynamic> read({String key}) async {
    return storage.getItem(key);
  }

  @override
  Future<void> write({String key, dynamic value}) async {
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
