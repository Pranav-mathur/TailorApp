import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  final String baseUrl = "http://100.27.221.127:3000/api/v1";

  // Send OTP to mobile number
  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    final url = Uri.parse("$baseUrl/auth/login/send-otp");
    debugPrint("✅ Send OTP API Payload: $mobileNumber");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobileNumber": mobileNumber}),
    );

    debugPrint("✅ Send OTP API Response: ${response.statusCode}");
    debugPrint("✅ Send OTP API Response Body: ${response.body}");
    debugPrint("✅ Send OTP API Response Body: ${response}");

    if (response.statusCode == 200) {
      return {
        "message": "OTP sent successfully"
      };
    } else {
      // Handle specific error cases
      if (response.statusCode == 400) {
        throw Exception("Invalid mobile number format");
      } else if (response.statusCode == 500) {
        throw Exception("Failed to send OTP. Please try again.");
      } else {
        throw Exception("Failed to send OTP: ${response.body}");
      }
    }
  }

  // Verify OTP and get JWT token
  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String otp) async {
    final url = Uri.parse("$baseUrl/auth/login/verify-otp");
    debugPrint("✅ Verify OTP API Payload: mobileNumber=$mobileNumber, otp=$otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "mobileNumber": mobileNumber,
        "otp": otp,
      }),
    );

    debugPrint("✅ Verify OTP API Response: ${response.statusCode}");
    debugPrint("✅ Verify OTP API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Handle specific error cases
      if (response.statusCode == 400) {
        throw Exception("Mobile number and OTP are required");
      } else if (response.statusCode == 401) {
        throw Exception("Invalid OTP. Please try again.");
      } else if (response.statusCode == 500) {
        throw Exception("Server error. Please try again.");
      } else {
        throw Exception("OTP verification failed: ${response.body}");
      }
    }
  }

  // Logout method
  Future<Map<String, dynamic>> logout(String token) async {
    final url = Uri.parse("$baseUrl/auth/logout");
    debugPrint("✅ Logout API called");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("✅ Logout API Response: ${response.statusCode}");
    debugPrint("✅ Logout API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Logout failed: ${response.body}");
    }
  }

  // Updated login method - now sends OTP instead of direct login
  Future<Map<String, dynamic>> loginWithPhone(String mobileNumber) async {
    return await sendOtp(mobileNumber);
  }

  // Method to make authenticated requests
  Future<http.Response> makeAuthenticatedRequest(
      String endpoint,
      String token, {
        String method = 'GET',
        Map<String, dynamic>? body,
      }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        return await http.get(url, headers: headers);
    }
  }
}