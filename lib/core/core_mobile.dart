import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import 'storage.dart';

BaseClient createHttpClient() => IOClient();

Storage createStorage() => Platform.isAndroid || Platform.isIOS
    ? _ProxiedSecureStorage()
    : ProxiedLocalStorage('core');

class _ProxiedSecureStorage extends Storage {
  final storage = FlutterSecureStorage();

  @override
  FutureOr<bool> initialize() => true;

  @override
  Future<String?> read({required String key}) {
    return storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) {
    return storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() {
    return storage.deleteAll();
  }
}
