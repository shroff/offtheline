import 'dart:math';
import 'dart:typed_data';

import 'package:appcore/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:image_editor/image_editor.dart';

class ImageEditPage extends StatefulWidget {
  final String path;
  final int maxUploadSize;
  final bool square;
  final int maxPixelArea;

  ImageEditPage({
    Key? key,
    required this.path,
    required this.maxUploadSize,
    required this.square,
    required this.maxPixelArea,
  }) : super(key: key);

  @override
  _ImageEditPageState createState() => _ImageEditPageState();

  static Future<Uint8List?> start(
    BuildContext context,
    String path,
    ImageConstraints constraints,
  ) {
    return Navigator.of(context).push<Uint8List>(MaterialPageRoute(
      builder: (context) => ImageEditPage(
        path: path,
        square: constraints.imageSquare,
        maxUploadSize: constraints.maxSize,
        maxPixelArea: constraints.maxPixelArea,
      ),
      settings: RouteSettings(
        name: 'editImage',
      ),
    ));
  }
}

class _ImageEditPageState extends State<ImageEditPage> {
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey();
  late final ImageProvider provider;
  @override
  void initState() {
    super.initState();
    provider = ExtendedFileImageProvider(File(widget.path), cacheRawData: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              final result = await performEdits();
              if (result != null) {
                Navigator.of(context).pop(result);
              }
            },
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ExtendedImage(
                image: provider,
                extendedImageEditorKey: editorKey,
                mode: ExtendedImageMode.editor,
                fit: BoxFit.contain,
                initEditorConfigHandler: (_) => EditorConfig(
                  maxScale: 8.0,
                  cropRectPadding: const EdgeInsets.all(20.0),
                  hitTestSize: 20.0,
                  cropAspectRatio: widget.square ? 1.0 : null,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    editorKey.currentState?.rotate(right: false);
                  },
                  icon: Icon(Icons.rotate_left),
                ),
                IconButton(
                  onPressed: () {
                    editorKey.currentState?.flip();
                  },
                  icon: Icon(Icons.flip),
                ),
                IconButton(
                  onPressed: () {
                    editorKey.currentState?.rotate(right: true);
                  },
                  icon: Icon(Icons.rotate_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> performEdits() async {
    final ExtendedImageEditorState? state = editorKey.currentState;
    if (state == null) {
      return null;
    }
    final Rect? rect = state.getCropRect();
    if (rect == null) {
      return null;
    }

    final EditActionDetails action = state.editAction!;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    final Uint8List? img = state.rawImageData;

    if (img == null) {
      return null;
    }

    final ImageEditorOption option = ImageEditorOption();

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
        FlipOption(horizontal: flipHorizontal, vertical: flipVertical));
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    final px = rect.size.width * rect.size.height;
    if (px > widget.maxPixelArea) {
      double scale = sqrt(px / widget.maxPixelArea);
      option.addOption(ScaleOption((rect.size.width * scale).toInt(),
          (rect.size.height * scale).toInt()));
    }

    option.outputFormat = const OutputFormat.jpeg(80);

    final DateTime start = DateTime.now();
    final Uint8List? result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );

    final Duration diff = DateTime.now().difference(start);

    print('Processing time: $diff');
    print('Output size: ${result?.length} bytes');

    return result;
  }
}
