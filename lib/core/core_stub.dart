import 'package:http/http.dart';
import 'storage.dart';

export 'package:http/http.dart';
export 'storage.dart';

BaseClient createHttpClient() => throw UnsupportedError('Cannot create a client without dart:html or dart:io.');

Storage createStorage() => throw UnsupportedError('Cannot create storage without dart:html or dart:io.');
