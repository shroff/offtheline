import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PhotoCapturePage extends StatefulWidget {
  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage> {
  Future<List<CameraDescription>> _cameras;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _cameras = availableCameras();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _cameras,
      builder: (context, snapshot) {
        if (snapshot.hasError) debugPrint(snapshot.error);
        return snapshot.hasData ? _CameraPreview(camera: snapshot.data[_cameraIndex]) : Center(child: CircularProgressIndicator());
      });
}

class _CameraPreview extends StatefulWidget {
  final CameraDescription camera;

  const _CameraPreview({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  State<_CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<_CameraPreview> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.ultraHigh,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Capture'),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.camera),
                    onPressed: () async {
                      try {
                          final fileName = '${DateTime.now()}.jpg';
                        final path = kIsWeb ? fileName : join(
                          (await getTemporaryDirectory()).path,
                          fileName
                        );
                        _controller.takePicture(path).then((value) {
                          Navigator.of(context).pop(path);
                        });
                      } catch (e) {
                        Navigator.of(context).pop(null);
                      }
                    },
                  )
                ],
              ),
              body: Center(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: CameraPreview(_controller),
                      ),
                    ),
                    FlatButton.icon(
                      icon: Icon(Icons.camera),
                      label: Text('CAPTURE'),
                      onPressed: () async {
                        try {
                          final path = join(
                            (await getTemporaryDirectory()).path,
                            '${DateTime.now()}.jpg',
                          );
                          _controller.takePicture(path).then((value) {
                            Navigator.of(context).pop(path);
                          });
                        } catch (e) {
                          Navigator.of(context).pop(null);
                        }
                      },
                    )
                  ],
                ),
              ),
            );
          } else {
            // Otherwise, display a loading indicator.
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
        },
      );
}
