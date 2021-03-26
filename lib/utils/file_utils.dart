import 'dart:async';

import 'package:appcore/imageedit/imageedit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

const _imageMaxDimension = 800.0;
const _imageQuality = 80;

class UploadFileData {
  final String fileName;
  final List<int>? contents;

  String get fileNameBase => path.basenameWithoutExtension(fileName);
  String get fileNameExt => path.extension(fileName);

  UploadFileData(String filePath, this.contents)
      : fileName = path.basename(filePath);
}

class ImageConstraints {
  final int maxSize;
  final bool imageSquare;
  final int imageTargetSize;

  ImageConstraints(this.maxSize, this.imageSquare, this.imageTargetSize);
}


Future<UploadFileData?> pickFile(
  BuildContext context,
  ImagePicker picker,
  ImageConstraints constraints,
) async {
  Completer result = Completer<UploadFileData?>();
  showModalBottomSheet(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.camera),
          title: Text('Capture Image'),
          onTap: () async {
            Navigator.of(ctx).pop();
            result.complete(_pickAndEditImage(context, picker, ImageSource.camera, constraints));
          },
        ),
        ListTile(
          leading: Icon(Icons.image),
          title: Text('Pick Image from Gallery'),
          onTap: () async {
            Navigator.of(ctx).pop();
            result.complete(_pickAndEditImage(
                context, picker, ImageSource.gallery, constraints));
          },
        ),
        ListTile(
          leading: Icon(Icons.attach_file),
          title: Text('Pick File'),
          onTap: () async {
            Navigator.of(ctx).pop();
            final picked = await FilePicker.platform.pickFiles(withData: true);
            if (picked == null || !picked.isSinglePick) {
              result.complete(null);
            } else {
              result.complete(UploadFileData(picked.files[0].path!, picked.files[0].bytes));
            }
          },
        ),
      ],
    ),
  );
  return result.future as FutureOr<UploadFileData?>;
}

Future<UploadFileData?> _pickAndEditImage(
  BuildContext context,
  ImagePicker picker,
  ImageSource source,
  ImageConstraints constraints,
) async {
  final image = await picker.getImage(
    source: source,
    maxWidth: _imageMaxDimension,
    maxHeight: _imageMaxDimension,
    imageQuality: _imageQuality,
  );
  if (image == null) return null;

  final editedImageData = await ImageEditPage.navigateTo(
    context,
    await image.readAsBytes(),
    constraints,
  );

  if (editedImageData == null) return null;
  return UploadFileData(image.path, editedImageData);
}
