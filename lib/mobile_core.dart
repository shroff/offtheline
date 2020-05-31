import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import 'storage.dart';

BaseClient createHttpClient() => IOClient();

Storage createStorage() => _ProxiedSecureStorage();

class _ProxiedSecureStorage extends Storage {
  final storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {
  }

  @override
  Future<dynamic> read({String key}) {
    return storage.read(key: key);
  }

  @override
  Future<void> write({String key, value}) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({String key}) {
    return storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() {
    return storage.deleteAll();
  }
}
