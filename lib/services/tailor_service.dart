import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TailorService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1";

  // Get service categories
  Future<Map<String, dynamic>> getServiceCategories({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/categories');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint("✅ Categories API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Categories fetched successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch categories',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create tailor profile
  Future<Map<String, dynamic>> createTailorProfile({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/create-tailor-profile");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint("✅ Create Profile Request: ${json.encode(body)}");
      debugPrint("✅ Create Profile Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': data['message'] ?? 'Profile created successfully',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create profile');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get tailor profile
  Future<Map<String, dynamic>> getTailorProfile({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/tailor/profile');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("✅ Get Profile Response: ${response.body}");
      debugPrint("✅ Get Profile Response: ${token}");


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data['tailor'] ?? {},
          'message': data['message'] ?? 'Profile fetched successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update tailor profile (generic update - can include any fields)
  Future<Map<String, dynamic>> updateTailorProfile({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/update-tailor-profile');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint("✅ Update Profile Request: ${token}");
      debugPrint("✅ Update Profile Request: ${json.encode(body)}");
      debugPrint("✅ Update Profile Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Note: updateTailorProfile is now a generic method that accepts any request body
  // You can call it directly with any fields you need to update

  // Get bookings
  Future<Map<String, dynamic>> getBookings({
    required String token,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString = '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      final url = Uri.parse('$baseUrl/tailor/bookings$queryString');
      debugPrint("✅ Categories API Response: ${token}");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Bookings fetched successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch bookings',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(
      String token,
      String imagePath,
      ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/tailor/profile/image'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to upload image: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error uploading image: ${e.toString()}',
      };
    }
  }

  // Upload category images
  Future<Map<String, dynamic>> uploadCategoryImages(
      String token,
      String categoryId,
      List<String> imagePaths,
      ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/tailor/category/$categoryId/images'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      for (var imagePath in imagePaths) {
        request.files.add(
          await http.MultipartFile.fromPath('images', imagePath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to upload images: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error uploading images: ${e.toString()}',
      };
    }
  }
}