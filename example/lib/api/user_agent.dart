import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';

String? _userAgent;
String? get userAgent => _userAgent;

Future<void> initilizeUserAgent() async {
  if (!kIsWeb) {
    final info = await PackageInfo.fromPlatform();
    _userAgent =
        'OffTheLine-Example ${info.packageName} ${info.version} (${info.buildNumber})';
  }
}
