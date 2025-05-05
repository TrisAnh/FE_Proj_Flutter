import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Replace with your actual API base URL
  final String baseUrl = 'http://10.0.2.2:5000/api';

  // Store JWT token
  String? _token;

  // Getter for token
  String? get token => _token;

  // Check if user is logged in
  bool get isLoggedIn => _token != null;

  // Initialize and load token from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Register with email
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Verify OTP for registration
  Future<Map<String, dynamic>> verifyRegistrationOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] && data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'OTP verification failed: $e'};
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] && data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Request password reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Password reset request failed: $e'};
    }
  }

  // Reset password with OTP
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'password': newPassword}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Password reset failed: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Save token to storage
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get user profile using JWT
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to get profile: $e'};
    }
  }
}
