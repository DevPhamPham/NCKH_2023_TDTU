import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Uint8List? _imageBytes;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (_imageBytes != null)
            Center(
              child: Image.memory(_imageBytes!),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _toggleCamera,
            child: Icon(Icons.switch_camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _toggleFlash,
            child: _isFlashOn ? Icon(Icons.flash_on) : Icon(Icons.flash_off),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              try {
                await _initializeControllerFuture;

                final isFront = _controller.description.lensDirection ==
                    CameraLensDirection.front;
                if (!isFront)
                  await _controller.setFlashMode(
                      _isFlashOn ? FlashMode.torch : FlashMode.off);

                final XFile image = await _controller.takePicture();
                final bytes = await image.readAsBytes();
                setState(() {
                  _imageBytes = Uint8List.fromList(bytes);
                });
                // Hiển thị hộp thoại xác nhận lưu ảnh
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Xác nhận lưu ảnh'),
                      content:
                          Text('Bạn có muốn lưu ảnh và gửi lên API không?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            // Thoát khỏi hộp thoại
                            Navigator.of(context).pop();
                            setState(() {
                              _imageBytes = null;
                            });
                          },
                          child: Text('Thoát'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Xác nhận lưu ảnh và gửi lên API
                            _saveAndSendImage();
                            Navigator.of(context).pop();
                          },
                          child: Text('Xác nhận'),
                        ),
                      ],
                    );
                  },
                );
              } catch (e) {
                print(e);
              }
            },
            child: Icon(Icons.camera),
          ),
        ],
      ),
    );
  }

  void _toggleCamera() async {
    try {
      final cameraList = await availableCameras();
      final isFront =
          _controller.description.lensDirection == CameraLensDirection.front;
      final newCamera = cameraList.firstWhere((camera) =>
          camera.lensDirection !=
          (isFront ? CameraLensDirection.front : CameraLensDirection.back));
      await _controller.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.medium,
      );
      await _controller.initialize();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  void _toggleFlash() async {
    try {
      await _initializeControllerFuture;
      final bool currentFlashMode =
          _controller.value.flashMode == FlashMode.torch;
      setState(() {
        _isFlashOn = !currentFlashMode;
      });
      await _controller
          .setFlashMode(currentFlashMode ? FlashMode.off : FlashMode.torch);
    } catch (e) {
      print(e);
    }
  }

  void _saveAndSendImage() {
    // Gửi _imageBytes lên API và xử lý kết quả
    // Ví dụ:
    // api.postImage(_imageBytes).then((response) {
    //   // Xử lý kết quả trả về từ API
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: Text('Thông báo'),
    //         content: Text(response.data),
    //         actions: <Widget>[
    //           TextButton(
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //             child: Text('OK'),
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // }).catchError((error) {
    //   print(error);
    // });
    // Trong đoạn mã trên, bạn cần thay thế api.postImage b
  }
}
