import 'dart:async';
import 'dart:typed_data';

import 'package:appcore/imageedit/imageedit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

const _imageMaxDimension = 800.0;
const _imageQuality = 80;
const _imageExtensions = ["jpg", "jpeg", "png", "webp"];

class UploadFileData {
  final String fileName;
  final Uint8List contents;

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
  ImageConstraints constraints, {
  bool allowImagesOnly = false,
}) async {
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
            result.complete(_pickAndEditImage(
                context, picker, ImageSource.camera, constraints));
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
            final picked = await FilePicker.platform.pickFiles(
              type: allowImagesOnly ? FileType.image : FileType.any,
              withData: true,
            );
            if (picked == null || !picked.isSinglePick) {
              result.complete(null);
              return;
            }

            final file = picked.files[0];
            Uint8List contents = file.bytes!;
            UploadFileData? uploadData = UploadFileData(file.path!, contents);

            if (file.extension != null &&
                _imageExtensions.contains(file.extension!.toLowerCase())) {
              final editedImageData = await ImageEditPage.navigateTo(
                context,
                file.bytes!,
                constraints,
              );
              if (editedImageData == null) {
                uploadData = null;
              } else {
                uploadData = UploadFileData("image.jpg", editedImageData);
              }
            }
            if ((uploadData?.contents.length ?? 0) > 1000000) {
              uploadData = null;
            }

            result.complete(uploadData);
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
