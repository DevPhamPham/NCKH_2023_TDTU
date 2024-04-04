import 'package:app_nckh_2024/image_detail_screen.dart';
import 'package:flutter/material.dart';

class ImageListScreen extends StatelessWidget {
  final Set<String> names; // Thay đổi từ Set<String> thành List<String>

  const ImageListScreen({Key? key, required this.names}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image List'),
      ),
      body: ListView.builder(
        itemCount: names.length,
        itemBuilder: (context, index) {
          final imageName =
              names.elementAt(index); // Thay đổi cách lấy phần tử từ Set
          // print("TESTTTTTTTTTTTTTT");
          // print(names);
          // print(imageName);
          // print("TESTTTTTTTTTTTTTT");
          return ListTile(
            title: Text(imageName),
            trailing: Icon(Icons.arrow_forward), // Thêm biểu tượng nhấp nhảy
            onTap: () {
              _showImageDetail(context, imageName);
            },
          );
        },
      ),
    );
  }

  void _showImageDetail(BuildContext context, String imageName) {
    String imageUrl =
        "https://firebasestorage.googleapis.com/v0/b/store-19553.appspot.com/o/${Uri.encodeFull(imageName)}.jpg?alt=media";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailScreen(imageUrl: imageUrl),
      ),
    );
  }
}
