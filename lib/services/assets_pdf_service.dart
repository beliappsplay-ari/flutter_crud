import 'dart:convert';
import 'dart:typed_data';
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

  // ============================================================================
  // SALARY SLIP METHODS
  // ============================================================================

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

  static String getPdfUrl(String empno, String period) {
    return '$baseUrl/api/payroll/view-pdf/$empno/$period';
  }

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

  static Future<List<Map<String, dynamic>>> getMySlipsWithPdfInfo() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

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

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static String formatPeriod(String period) {
    if (period.isEmpty) return '';

    final parts = period.split(' ');
    if (parts.length != 2) return period;

    final monthMap = {
      'January': 'Jan',
      'February': 'Feb',
      'March': 'Mar',
      'April': 'Apr',
      'May': 'May',
      'June': 'Jun',
      'July': 'Jul',
      'August': 'Aug',
      'September': 'Sep',
      'October': 'Oct',
      'November': 'Nov',
      'December': 'Dec',
    };

    final shortMonth = monthMap[parts[0]] ?? parts[0];
    return '$shortMonth ${parts[1]}';
  }

  static String periodToPdfFilename(String period) {
    final periodMap = {
      'January': '01',
      'February': '02',
      'March': '03',
      'April': '04',
      'May': '05',
      'June': '06',
      'July': '07',
      'August': '08',
      'September': '09',
      'October': '10',
      'November': '11',
      'December': '12',
    };

    final parts = period.split(' ');
    if (parts.length != 2) return '';

    final monthName = parts[0];
    final year = parts[1];

    if (!periodMap.containsKey(monthName)) return '';

    final monthNumber = periodMap[monthName];
    return '$year$monthNumber.pdf';
  }
}
