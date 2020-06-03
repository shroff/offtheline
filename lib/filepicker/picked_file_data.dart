import 'dart:typed_data';

import 'package:path/path.dart' as path;

const _imageExts = [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp'
];

class PickedFileConstraints {
  final int maxSize;
  final bool imageSquare;
  final int imageTargetSize;

  PickedFileConstraints(this.maxSize, this.imageSquare, this.imageTargetSize);
}

class PickedFileData {
  final Uint8List contents;
  final String ext;

  PickedFileData(this.contents, String name) : this.ext = path.extension(name);

  bool get isKnownImageExt => _imageExts.contains(ext);
}