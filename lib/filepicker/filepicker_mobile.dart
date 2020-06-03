import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'photo_capture_page.dart';
import 'picked_file_data.dart';

Future<PickedFileData> pickOrCapture(BuildContext context) =>
    showModalBottomSheet<PickedFileData>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.folder),
            title: Text('Pick File'),
            onTap: () async {
              Navigator.of(context).pop(await _pickFile(context));
            },
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Capture Photo'),
            onTap: () async {
              Navigator.of(context).pop(await _capturePhoto(context));
            },
          ),
        ],
      ),
    );

Future<PickedFileData> _pickFile(BuildContext context) async {
  File file = await FilePicker.getFile();
  return file == null
      ? null
      : file
          .readAsBytes()
          .then((value) => new PickedFileData(value, path.extension(file.path)));
}

Future<PickedFileData> _capturePhoto(BuildContext context) {
  return Navigator.of(context)
      .push(MaterialPageRoute(
    builder: (context) => PhotoCapturePage(),
  ))
      .then((filePath) {
    return filePath == null
        ? null
        : File(filePath)
            .readAsBytes()
            .then((value) => new PickedFileData(value, path.extension(filePath)));
  });
}
