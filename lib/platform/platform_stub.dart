import 'package:http/http.dart';
import 'proxied_storage.dart';

export 'package:http/http.dart';
export 'proxied_storage.dart';

BaseClient createHttpClient() => throw UnsupportedError(
    'Cannot create a client without dart:html or dart:io.');

ProxiedStorage createStorage() => throw UnsupportedError(
    'Cannot create storage without dart:html or dart:io.');
