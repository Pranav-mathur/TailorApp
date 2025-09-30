// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
// class TailorService {
//   final String baseUrl = "http://100.27.221.127:3000/api/v1";
//
//   Future<Map<String, dynamic>> createTailorProfile({
//     required String token,
//     required Map<String, dynamic> body,
//   }) async {
//     final url = Uri.parse("$baseUrl/create-tailor-profile");
//
//     final response = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//       body: jsonEncode(body),
//     );
//
//     debugPrint("✅ bosy: ${body}");
//     debugPrint("✅ Send OTP API Response: ${response.statusCode}");
//     debugPrint("✅ Send OTP API Response Body: ${response.body}");
//     debugPrint("✅ Send OTP API Response Body: ${response}");
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception("Failed to create tailor profile: ${response.body}");
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class TailorService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1"; // Replace with your actual API base URL

  // Get service categories
  Future<Map<String, dynamic>> getServiceCategories({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/categories'); // Adjust endpoint as needed

      // final response = await http.get(
      //   url,
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   final Map<String, dynamic> data = json.decode(response.body);
      //   return {
      //     'success': true,
      //     'data': data, // Return the entire response since categories are at root level
      //     'message': 'Categories fetched successfully',
      //   };
      // } else if (response.statusCode == 401) {
      //   return {
      //     'success': false,
      //     'message': 'Unauthorized access. Please login again.',
      //   };
      // } else {
      //   final Map<String, dynamic> errorData = json.decode(response.body);
      //   return {
      //     'success': false,
      //     'message': errorData['message'] ?? 'Failed to fetch categories',
      //   };
      // }
      return {  'success': true,
        'data': {
          "categories": [
            {
              "id": "507f1f77bcf86cd799439011",
              "name": "Shirts",
              "gender": "Male",
              "subcategories": [
                {"name": "Casual Shirts"},
                {"name": "Formal Shirts"}
              ]
            }
          ]
        }, // Return the entire response since categories are at root level
        'message': 'Categories fetched successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create tailor profile (your existing method)
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

      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   final Map<String, dynamic> data = json.decode(response.body);
      //   return {
      //     'success': true,
      //     'data': data['data'] ?? {},
      //     'message': data['message'] ?? 'Profile created successfully',
      //   };
      // } else if (response.statusCode == 401) {
      //   throw Exception('Unauthorized access. Please login again.');
      // } else {
      //   final Map<String, dynamic> errorData = json.decode(response.body);
      //   throw Exception(errorData['message'] ?? 'Failed to create profile');
      // }
      return {
        'success': true,
        'data': {
          "message": "Tailor profile created successfully",
          "user": {
            "id": "507f1f77bcf86cd799439011",
            "mobile_number": "+916976543210",
            "user_type": "tailor",
            "tailor_details": {
              "name": "Test Tailor",
              "portfolio_images": ["https://example.com/portfolio1.jpg"],
              "categories": [],
              "address": {},
              "location": {},
              "is_sponsored": false,
              "avg_rating": 0,
              "review_count": 0,
              "is_profile_complete": true,
              "kyc_done": false
            }
          }
        } ?? {},
        'message': 'Profile created successfully',
      };
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? {},
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

  // Update tailor profile
  Future<Map<String, dynamic>> updateTailorProfile({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/tailor/profile');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

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

  Future<Map<String, dynamic>> getBookings({
    required String token,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      // Build query parameters
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

      final url = Uri.parse('$baseUrl/bookings$queryString');

      // final response = await http.get(
      //   url,
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   final Map<String, dynamic> data = json.decode(response.body);
      //   return {
      //     'success': true,
      //     'data': data, // Return the entire response with metaData and data
      //     'message': 'Bookings fetched successfully',
      //   };
      // } else if (response.statusCode == 401) {
      //   return {
      //     'success': false,
      //     'message': 'Unauthorized access. Please login again.',
      //   };
      // } else {
      //   final Map<String, dynamic> errorData = json.decode(response.body);
      //   return {
      //     'success': false,
      //     'message': errorData['message'] ?? 'Failed to fetch bookings',
      //   };
      // }
      return {
        'success': true,
        'data': {
          "metaData": {
            "total_bookings": 1,
            "page": 1,
            "limit": 20,
            "profile_pic": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80",
            "business_name": "Elegant Tailors"
          },
          "data": [
            {
              "bookingId": "507f1f77bcf86cd799439014",
              "order_id": "ORD12345",
              "customer_name": "John Doe",
              "price": 1200,
              "customer_image": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80",
              "status": "Requested",
              "requestedDateTime": "2024-12-31T10:00:00Z",
              "category": {
              "id": "64abc123",
              "name": "Blouse Stitching"
              },
              "created_at": "2024-01-01T10:00:00Z",
              "updated_at": "2024-01-01T10:00:00Z"
            },
            {
              "bookingId": "507f1f77bcf86cd799439014",
              "order_id": "ORD12345",
              "customer_name": "John Doe",
              "price": 1200,
              "customer_image": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80",
              "status": "Completed",
              "requestedDateTime": "2024-12-31T10:00:00Z",
              "category": {
                "id": "64abc123",
                "name": "Blouse Stitching"
              },
              "created_at": "2024-01-01T10:00:00Z",
              "updated_at": "2024-01-01T10:00:00Z"
            },
          ]
        },
        'message': 'Bookings fetched successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}


