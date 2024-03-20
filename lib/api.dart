import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = 'https://example.api.com';

  static Future<Map<String, dynamic>> postImage(Uint8List imageData) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl + '/upload-image'),
        body: {
          'image': base64Encode(imageData),
        },
      );

      if (response.statusCode == 200) {
        // Xử lý dữ liệu trả về từ API nếu cần
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to post image: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error posting image: $error');
    }
  }
}
