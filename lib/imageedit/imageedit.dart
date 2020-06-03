library imageedit;

import 'dart:math';
import 'dart:ui' as ui;

import 'package:appcore/dialogs.dart';
import 'package:flutter/material.dart';
import 'image_resize.dart';

class ImageEditPage extends StatefulWidget {
  _ImageEditArgs args(BuildContext context) =>
      ModalRoute.of(context).settings.arguments;

  static Future<List<int>> navigateTo(BuildContext context,
      List<int> imageBytes, ImageConstraints constraints) {
    return Navigator.of(context).push<List<int>>(MaterialPageRoute(
        builder: (context) => ImageEditPage(),
        settings: RouteSettings(
          arguments: _ImageEditArgs(imageBytes, constraints),
        )));
  }

  @override
  State<ImageEditPage> createState() => _ImageEditState();
}

class ImageConstraints {
  final int maxSize;
  final bool imageSquare;
  final int imageTargetSize;

  ImageConstraints(this.maxSize, this.imageSquare, this.imageTargetSize);
}

class _ImageEditArgs {
  final List<int> imageBytes;
  final ImageConstraints constraints;

  _ImageEditArgs(this.imageBytes, this.constraints);
}

class _ImageEditState extends State<ImageEditPage> {
  bool initialized = false;
  ImageData imageData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      final args = widget.args(context);
      ui
          .instantiateImageCodec(args.imageBytes)
          .then((codec) => codec.getNextFrame())
          .then((frame) => frame.image)
          .then((image) {
        setState(() {
          imageData = ImageData.create(image, args.constraints.imageSquare);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Crop'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                final args = widget.args(context);
                final data = ImageProcessingData(
                  args.imageBytes,
                  imageData.viewport,
                  args.constraints.imageTargetSize,
                );
                List<int> result;
                showProgressDialog(
                  context,
                  message: "Processing...",
                ).then((value) =>
                    value != null ? Navigator.of(context).pop(value) : null);

                try {
                  result = await processImage(true, data);
                  Navigator.of(context).pop(result);
                } catch (e) {
                  Navigator.of(context).pop(null);
                  showAlertDialog(
                    context,
                    title: "Error processing image",
                    message: e.toString(),
                  );
                }
              },
            )
          ],
        ),
        body: imageData != null
            ? ImageViewportTransformer(
                imageData: imageData,
                onUpdateViewport: (Rect viewport) {
                  setState(() {
                    imageData = imageData.withViewport(viewport);
                  });
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      );
}

class ImageViewportTransformer extends StatefulWidget {
  final ImageData imageData;
  final Function(Rect) onUpdateViewport;

  const ImageViewportTransformer({
    Key key,
    @required this.imageData,
    @required this.onUpdateViewport,
  }) : super(key: key);

  @override
  State<ImageViewportTransformer> createState() =>
      _ImageViewportTransformerState();
}

class _ImageViewportTransformerState extends State<ImageViewportTransformer> {
  double imageWidth;
  double imageHeight;
  Rect viewport;
  Offset startOffset;
  double viewportCanvasRatio = 1;

  @override
  void initState() {
    super.initState();
    imageWidth = widget.imageData.image.width.toDouble();
    imageHeight = widget.imageData.image.height.toDouble();
    viewport = widget.imageData.viewport;
  }

  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          onScaleStart: (ScaleStartDetails details) {
            viewportCanvasRatio =
                widget.imageData.viewport.width / context.size.width;
            startOffset = details.focalPoint;
          },
          onScaleUpdate: (ScaleUpdateDetails details) {
            final viewport = widget.imageData.viewport;
            final newWidth = viewport.width / details.scale;
            final scale = (newWidth) > imageWidth
                ? viewport.width / imageWidth
                : (newWidth < 200) ? viewport.width / 200 : details.scale;
            final width = viewport.width / scale;
            final height = viewport.height / scale;
            final effectiveScale = viewportCanvasRatio / scale;
            final left = viewport.left +
                (startOffset.dx - details.focalPoint.dx) * effectiveScale +
                ((viewport.width - width) / 2);
            final top = viewport.top +
                (startOffset.dy - details.focalPoint.dy) * effectiveScale +
                ((viewport.height - height) / 2);
            setState(() {
              this.viewport = Rect.fromLTWH(
                  max(0, min(left, imageWidth - width)),
                  max(0, min(top, imageHeight - height)),
                  width,
                  height);
            });
          },
          onScaleEnd: (ScaleEndDetails details) {
            widget.onUpdateViewport(viewport);
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 200, maxWidth: 400),
            child: AspectRatio(
              aspectRatio: widget.imageData.viewport.width /
                  widget.imageData.viewport.height,
              child: CustomPaint(
                painter: ImageDataPainter(
                    imageData: widget.imageData.withViewport(viewport)),
              ),
            ),
          ),
        ),
      );
}

class ImageData {
  final ui.Image image;
  final Rect viewport;

  const ImageData._(this.image, this.viewport);

  static ImageData create(ui.Image image, bool square) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final minDimension = min(imageWidth, imageHeight);
    final viewport = square
        ? Rect.fromLTWH(max(0, imageWidth - imageHeight) / 2,
            max(0, imageHeight - imageWidth) / 2, minDimension, minDimension)
        : Rect.fromLTWH(0, 0, imageWidth, imageHeight);
    return ImageData._(image, viewport);
  }

  ImageData withViewport(Rect viewport) {
    return ImageData._(image, viewport);
  }
}

class ImageDataPainter extends CustomPainter {
  final ImageData imageData;
  final Paint defaultPaint = Paint();

  ImageDataPainter({@required this.imageData});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    Rect whole = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
        imageData.image, imageData.viewport, whole, defaultPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
