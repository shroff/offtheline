import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'storage.dart';

BaseClient createHttpClient() => BrowserClient()..withCredentials = true;

Storage createStorage() => ProxiedLocalStorage('core');
