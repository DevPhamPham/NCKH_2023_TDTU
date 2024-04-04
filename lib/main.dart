import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:app_nckh_2024/image_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      debugShowCheckedModeBanner: false,
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
  bool _isImageSending = false;

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
        title: Text('Bạn giống ai nhất?'),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Image.memory(_imageBytes!),
                ),
              ),
            ),
          if (_isImageSending)
            Center(
              child: CircularProgressIndicator(),
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
              if (_imageBytes != null && !_isImageSending) {
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

  // Future<String> getImage(String name) async {
  //   try {
  //     // Kết nối Firebase Storage
  //     FirebaseStorage storage = FirebaseStorage.instance;
  //     print(storage);

  //     // Tạo tham chiếu tới vị trí lưu trữ trên Firebase Storage
  //     Reference ref = storage.ref().child("$name");
  //     print(ref);
  //     // Lấy URL của tệp đã được tải lên
  //     String url = await ref.getDownloadURL();
  //     print(url);
  //     return url;
  //   } catch (error) {
  //     // Xử lý các lỗi xảy ra trong quá trình tải lên
  //     print('Error getting image: $error');
  //     return ''; // Trả về chuỗi rỗng nếu không tìm thấy ảnh
  //   }
  // }
  void _showImages(Set<String> names) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ImageListScreen(names: names),
    ),
  );
}

  void _saveAndSendImage() async {
    try {
      setState(() {
        _isImageSending = true;
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://nckhpyspark.loca.lt/v1/nckh'),
      );

      // Thêm dữ liệu hình ảnh dưới dạng multipart/form-data
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'image.jpg',
        ),
      );

      // Gửi yêu cầu và xử lý phản hồi từ máy chủ
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Phân tích JSON từ phản hồi
        final data = jsonDecode(response.body);
        // Lấy danh sách tên file từ phản hồi
        final List<dynamic> result = data['result'];
        // Tạo danh sách tên file chỉ bao gồm phần tên
        final Set<String> names = Set();
        for (var item in result) {
          final String fullName = item[0];
          final nameParts = fullName.split('_'); // Tách chuỗi theo dấu '_'
          final name = nameParts.first; // Lấy phần tên đầu tiên
          names.add("${name}_${nameParts[1]}");
        }
        // In ra danh sách tên file
        print(names);

// // Truy vấn dữ liệu từ Firebase Storage và so sánh với danh sách tên file
//         for (var name in names) {
//           bool exists = false;
//           String url = await getImage(name);
//           if (url.isNotEmpty) {
//             exists = true;
//           }

//           if (exists) {
//             print('Found: $name');
//             // Xử lý khi tìm thấy tên ảnh trong Firebase Storage
//           } else {
//             print('Not found: $name');
//             // Xử lý khi không tìm thấy tên ảnh trong Firebase Storage
//           }
//         }

// Hiển thị danh sách ảnh và tên ảnh trên màn hình
      _showImages(names);


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
    } finally {
      setState(() {
        _isImageSending = false;
      });
    }
  }
}
