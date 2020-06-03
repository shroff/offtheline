library filepicker;

export 'package:appcore/filepicker/filepicker_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'package:appcore/filepicker/filepicker_web.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'package:appcore/filepicker/filepicker_mobile.dart';

export 'picked_file_data.dart';