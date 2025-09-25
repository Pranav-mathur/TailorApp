import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class KycService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1"; // Base URL

  /// Uploads a single document to /images/upload
  Future<String> uploadDocument(File file, String token) async {
    try {
      final uri = Uri.parse("$baseUrl/images/upload");
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );


      // var response = await request.send();
      // debugPrint("✅ Logout API Response: ${response.statusCode}");
      // debugPrint("✅ Logout API Response Body: ${response}");
      // debugPrint("✅ Logout file: ${file}");
      // debugPrint("✅ Logout API token Body: ${token}");
      // debugPrint("🔑 Authorization header: Bearer ${token.substring(0, 10)}...");
      // debugPrint("📋 Request fields: ${request.headers}");
      // debugPrint("📎 Request files: ${request.files.length}");
      //
      // if (response.statusCode == 200) {
      //   final respStr = await response.stream.bytesToString();
      //   final data = jsonDecode(respStr);
      //   // Return the image URL from API
      //   return data['imageUrl'] ?? '';
      // } else if (response.statusCode == 401) {
      //   throw Exception('Unauthorized: Invalid token');
      // } else if (response.statusCode == 400) {
      //   throw Exception('Bad Request: No file uploaded');
      // } else {
      //   throw Exception('Upload failed with status ${response.statusCode}');
      // }

      return "https://your-s3-bucket.s3.amazonaws.com/image-name.jpg";
    } catch (e) {
      debugPrint('KycService upload error: $e');
      rethrow;
    }
  }
}
