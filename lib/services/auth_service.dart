import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:8000/api';

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

  // Login method
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Ekstrak token dan user dari response Laravel
        final token =
            data['data']['token'] ?? data['token']; // Support kedua format
        final userData = data['data']['user'] ?? data['user'];

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
      return AuthResult.error('Network error: $e');
    }
  }

  // Logout method
  Future<AuthResult> logout() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: await _authenticatedHeaders,
          )
          .timeout(const Duration(seconds: 10));

      // Hapus token lokal regardless of server response
      await removeToken();

      if (response.statusCode == 200) {
        return AuthResult.success(message: 'Logout successful');
      } else {
        return AuthResult.success(message: 'Logged out locally');
      }
    } catch (e) {
      // Tetap hapus token lokal meski ada error
      await removeToken();
      return AuthResult.success(message: 'Logged out locally');
    }
  }

  // Get current user dari server
  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/me'), headers: await _authenticatedHeaders)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']);
        await saveUser(user); // Update cached user data
        return AuthResult.success(user: user);
      } else if (response.statusCode == 401) {
        // Token invalid, logout user
        await removeToken();
        return AuthResult.error('Session expired. Please login again.');
      } else {
        return AuthResult.error(data['message'] ?? 'Failed to get user data');
      }
    } on TimeoutException {
      return AuthResult.error('Connection timeout');
    } catch (e) {
      return AuthResult.error('Network error: $e');
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
}
