import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssetsPdfService {
  static String get baseUrl {
    return dotenv.env['API_URL']?.replaceAll('/api', '') ??
        'http://160.25.200.14:8888';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Check if PDF exists in assets/slip folder
  static Future<bool> checkPdfExists(String empno, String period) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final url = '$baseUrl/api/payroll/check-pdf/$empno/$period';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['pdf_exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking PDF: $e');
      return false;
    }
  }

  // Get PDF URL for viewing
  static String getPdfUrl(String empno, String period) {
    return '$baseUrl/api/payroll/view-pdf/$empno/$period';
  }

  // Download PDF bytes
  static Future<List<int>?> downloadPdfBytes(
    String empno,
    String period,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final url = getPdfUrl(empno, period);

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }

  // Get my salary slips with PDF availability info
  static Future<List<Map<String, dynamic>>> getMySlipsWithPdfInfo() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      //final url = '$baseUrl/api/payroll/my-slips';

      final url = '$baseUrl/api/flutter/my-slips';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to load salary slips');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load salary slips: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMySlipsWithPdfInfo: $e');
      throw Exception('Network error: $e');
    }
  }
}
