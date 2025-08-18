import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://160.25.200.14:8080/api';

  // Headers standar untuk semua request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers dengan token untuk authenticated requests
  Future<Map<String, String>> get _authenticatedHeaders async {
    final token = await getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  // Test connection ke Laravel API
  static Future<bool> testConnection() async {
    try {
      print('=== TEST CONNECTION ===');
      print('Testing API: $baseUrl/test');

      final response = await http
          .get(
            Uri.parse('$baseUrl/test'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('Test Response status: ${response.statusCode}');
      print('Test Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API Connection Success: $data');
        return true;
      } else {
        print('❌ API Connection Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ API Connection Failed: $e');
      return false;
    }
  }

  // Simpan token ke SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Ambil token dari SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Hapus token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Simpan data user
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  // Ambil data user tersimpan
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }
    return null;
  }

  // Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Login method - updated untuk Laravel API
  Future<AuthResult> login(String email, String password) async {
    try {
      print('=== LOGIN DEBUG ===');
      print('Calling API: $baseUrl/login');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      print('Login Response status: ${response.statusCode}');
      print('Login Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Ekstrak token dan user dari response Laravel
        final token = data['data']['token'];
        final userData = data['data']['user'];

        print('Token received: ${token?.substring(0, 20)}...');
        print('User data: $userData');

        final user = User.fromJson(userData);

        // Simpan token dan user data
        await saveToken(token);
        await saveUser(user);

        return AuthResult.success(user: user, token: token);
      } else {
        final message = data['message'] ?? 'Login failed';
        return AuthResult.error(message);
      }
    } on TimeoutException {
      return AuthResult.error('Connection timeout. Please try again.');
    } catch (e) {
      print('Login error: $e');
      return AuthResult.error('Network error: $e');
    }
  }

  // Logout method - updated untuk Laravel API
  Future<AuthResult> logout() async {
    try {
      print('=== LOGOUT DEBUG ===');
      print('Calling API: $baseUrl/logout');

      final headers = await _authenticatedHeaders;
      print('Headers: $headers');

      final response = await http
          .post(Uri.parse('$baseUrl/logout'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('Logout Response status: ${response.statusCode}');
      print('Logout Response body: ${response.body}');

      // Parse response
      final data = jsonDecode(response.body);

      // Hapus token lokal
      await removeToken();

      if (response.statusCode == 200 && data['success'] == true) {
        return AuthResult.success(
          message: data['message'] ?? 'Logout successful',
        );
      } else {
        return AuthResult.success(message: 'Logged out locally');
      }
    } catch (e) {
      print('Logout error: $e');
      // Tetap hapus token lokal meski ada error
      await removeToken();
      return AuthResult.success(message: 'Logged out locally');
    }
  }

  // Get current user dari server - updated untuk Laravel API
  Future<AuthResult> getCurrentUser() async {
    try {
      print('=== GET CURRENT USER DEBUG ===');
      print('Calling API: $baseUrl/me');

      final token = await getToken();
      print('Token available: ${token != null}');
      if (token != null) {
        print('Token preview: ${token.substring(0, 20)}...');
      }

      final headers = await _authenticatedHeaders;
      print('Headers: $headers');

      final response = await http
          .get(Uri.parse('$baseUrl/me'), headers: headers)
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']);
        await saveUser(user); // Update cached user data
        print('User loaded successfully: ${user.name}');
        return AuthResult.success(user: user);
      } else if (response.statusCode == 401) {
        // Token invalid, logout user
        print('Token invalid, logging out');
        await removeToken();
        return AuthResult.error('Session expired. Please login again.');
      } else {
        print('API error: ${data['message']}');
        return AuthResult.error(data['message'] ?? 'Failed to get user data');
      }
    } on TimeoutException {
      print('Timeout error');
      return AuthResult.error('Connection timeout');
    } catch (e) {
      print('Network error: $e');
      return AuthResult.error('Network error: $e');
    }
  }

  // Verify token validity
  Future<bool> verifyToken() async {
    try {
      print('=== VERIFY TOKEN DEBUG ===');
      print('Calling API: $baseUrl/me');

      final headers = await _authenticatedHeaders;

      final response = await http
          .get(Uri.parse('$baseUrl/me'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('Verify Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 401) {
        // Token invalid
        await removeToken();
        return false;
      } else {
        return false;
      }
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }

  // Refresh user data dari server
  Future<void> refreshUserData() async {
    final result = await getCurrentUser();
    if (!result.success) {
      // Handle error silently atau show notification
      print('Failed to refresh user data: ${result.message}');
    }
  }

  // Check if user is admin or has specific role
  // Future<bool> hasRole(String role) async {
  //   final user = await getSavedUser();
  //   return user?.role?.toLowerCase() == role.toLowerCase();
  // }

  // Get user info quickly from cache
  Future<String?> getUserName() async {
    final user = await getSavedUser();
    return user?.name;
  }

  Future<String?> getUserEmail() async {
    final user = await getSavedUser();
    return user?.email;
  }

  // Force logout (clear all local data)
  Future<void> forceLogout() async {
    try {
      await removeToken();
      print('Force logout completed');
    } catch (e) {
      print('Force logout error: $e');
    }
  }

  // Check network connectivity by testing API
  Future<bool> checkNetworkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/test'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Result wrapper untuk handling response
class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  AuthResult._({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });

  factory AuthResult.success({User? user, String? token, String? message}) {
    return AuthResult._(
      success: true,
      message: message ?? 'Success',
      user: user,
      token: token,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(success: false, message: message);
  }

  @override
  String toString() {
    return 'AuthResult{success: $success, message: $message, user: ${user?.name}, token: ${token != null ? '***' : 'null'}}';
  }
}
