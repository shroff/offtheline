import 'dart:math';
import 'dart:ui';

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

import 'item_processor_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'item_processor_mobile.dart';

const _jpegQuality = 80;

class ImageProcessingData {
  final List<int> bytes;
  final Rect viewport;
  final int targetSize;

  ImageProcessingData(this.bytes, this.viewport, this.targetSize);
}

Future<List<int>> processImage<K>(
  bool useIsolateIfAvailable,
  ImageProcessingData image,
) {
  final images = {
    0: image,
  };
  return processItems(_processImage, useIsolateIfAvailable, images)
      .then((result) => result[0]!);
}

Future<Map<K, List<int>>> processImages<K>(
  bool useIsolateIfAvailable,
  Map<K, ImageProcessingData> images,
) {
  return processItems(_processImage, useIsolateIfAvailable, images);
}

Future<List<int>> _processImage(ImageProcessingData data) async {
  image.Image? src;
// Decode
  debugPrint('Decoding Image');
  src = image.decodeImage(data.bytes);
  debugPrint('Original: ${src!.width}x${src.height}');

// Read orientation from EXIF and then clear information
  final exif = (await readExifFromBytes(data.bytes)) ?? <String?, IfdTag>{};
  final orientation = (exif.containsKey('Image Orientation'))
      ? (exif['Image Orientation']!.values![0] as int?)!
      : 1;
  debugPrint('EXIF Orientation: $orientation');
  src.exif.rawData = null;
  src.exif.data.clear();

// Scale
  double scale = min(
      1,
      sqrt((data.targetSize * 4) /
          (data.viewport.width * data.viewport.height)));
  debugPrint('Scaling Image. Initial Scale: $scale');
  src = image.copyResize(src,
      width: (src.width * scale).toInt(),
      interpolation: image.Interpolation.linear);
  debugPrint('Scaled: ${src.width}x${src.height}');

// Apply orientation
  src = _applyExifOrientation(src, orientation);
  debugPrint('Rotated image: ${src.width}x${src.height}');

// Scale Viewport
  debugPrint('Scaling viewport');
  final viewportLeft = data.viewport.left * scale;
  final viewportTop = data.viewport.top * scale;
  final viewportWidth =
      min(src.width - viewportLeft, data.viewport.width * scale);
  final viewportHeight =
      min(src.height - viewportTop, data.viewport.height * scale);
  debugPrint('$viewportLeft+${viewportTop}x${viewportWidth}x$viewportHeight');

// Crop
  debugPrint('Cropping Image');
  src = image.copyCrop(src, viewportLeft.toInt(), viewportTop.toInt(),
      viewportWidth.toInt(), viewportHeight.toInt());
  List<int> result = image.encodeJpg(src, quality: _jpegQuality);
  debugPrint('Image Size: ${result.length}');

// Scale more as needed
  scale = 1;
  while (result.length > data.targetSize) {
    double newTarget = sqrt(data.targetSize / result.length);
    scale *= min(0.9, newTarget);
    int targetWidth = (src.width * scale).toInt();
    image.Image rescaled = (src.width < targetWidth)
        ? src
        : image.copyResize(src, width: targetWidth);
    result = image.encodeJpg(rescaled, quality: _jpegQuality);
    debugPrint('Resized to ${result.length} of $data.targetSize');
  }

  return result;
}

image.Image _applyExifOrientation(image.Image src, int orientation) {
  switch (orientation) {
    case 2:
      return image.flipHorizontal(src);
    case 3:
      return image.flip(src, image.Flip.both);
    case 4:
      return image.flipHorizontal(image.copyRotate(src, 180));
    case 5:
      return image.flipHorizontal(image.copyRotate(src, 90));
    case 6:
      return image.copyRotate(src, 90);
    case 7:
      return image.flipHorizontal(image.copyRotate(src, -90));
    case 8:
      return image.copyRotate(src, -90);
  }
  return src;
}
