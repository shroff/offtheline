import 'dart:typed_data';

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

  PickedFileData(this.contents, this.ext);

  bool get isKnownImageExt => _imageExts.contains(ext);
}