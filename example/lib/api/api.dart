import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';

export 'package:offtheline/offtheline.dart';
export 'example_domain.dart';

class Api {
  static String? _userAgent;
  static String? get userAgent => _userAgent;

  static Future<void> initilizeUserAgent() async {
    if (!kIsWeb) {
      final info = await PackageInfo.fromPlatform();
      _userAgent =
          'OffTheLine-Example ${info.packageName} ${info.version} (${info.buildNumber})';
    }
  }
}
