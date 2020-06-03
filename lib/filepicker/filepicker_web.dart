import 'dart:async';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'picked_file_data.dart';

Future<PickedFileData> pickOrCapture(BuildContext context) =>
    _pickFile(context);

Future<PickedFileData> _pickFile(BuildContext context) {
  final Completer<PickedFileData> completer = Completer();
  final InputElement input = document.createElement('input');
  input
    ..type = 'file'
    ..accept = 'image/*';
  input.onChange.listen((e) {
    final files = input.files;
    for (final file in files) {
      final reader = new FileReader();
      reader.onLoad.listen((e2) {
        completer.complete(new PickedFileData(reader.result, path.extension(file.name)));
      });
      reader.onError.listen((e2) {
        completer.completeError(e2);
      });
      reader.onAbort.listen((e2) {
        completer.completeError(e2);
      });
      reader.readAsArrayBuffer(
          file); // or '.readAsDataUrl' for using as img src, for example
    }
  });
  input.click();
  return completer.future;
}
