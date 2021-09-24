import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'proxied_storage.dart';
import 'proxied_local_storage.dart';

BaseClient createHttpClient() => BrowserClient()..withCredentials = true;

ProxiedStorage createStorage() => ProxiedLocalStorage('core');
