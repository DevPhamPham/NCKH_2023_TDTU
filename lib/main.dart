import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
  final ImagePicker _picker = ImagePicker();

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
            onPressed: _getImageFromCamera,
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _getImageFromGallery,
            child: Icon(Icons.photo_library),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              if (_imageBytes != null) {
                _saveAndSendImage();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please select an image first.'),
                  ),
                );
              }
            },
            child: Icon(Icons.send),
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

  Future<void> _getImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = Uint8List.fromList(bytes);
      });
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = Uint8List.fromList(bytes);
      });
    }
  }

  void _saveAndSendImage() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.118.67:5001/v1/nckh'),
      );

      // Thêm dữ liệu hình ảnh dưới dạng multipart/form-data
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'image.jpg',
        ),
      );

      // Gửi yêu cầu và xử lý phản hồi từ server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Xử lý kết quả trả về từ server
        final data = response.body;
        print(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image.'),
          ),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while sending image.'),
        ),
      );
    }
  }
}
