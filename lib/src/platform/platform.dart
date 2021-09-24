library core;

export 'platform_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'platform_html.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'platform_io.dart';
