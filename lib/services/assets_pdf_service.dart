import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssetsPdfService {
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'http://160.25.200.14:8888/api';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Check if PDF exists in assets/slip folder by trying to access it
  static Future<bool> checkPdfExists(String empno, String period) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final url = getPdfUrl(empno, period);

      print('Checking PDF existence: $url');

      final response = await http
          .head(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final exists = response.statusCode == 200;
      print('PDF exists in assets/slip: $exists');
      return exists;
    } catch (e) {
      print('Error checking PDF in assets: $e');
      return false;
    }
  }

  // Get PDF URL for viewing directly from assets/slip folder
  static String getPdfUrl(String empno, String period) {
    // Convert period format: e.g., "JUL2025" to match filename
    final formattedPeriod = _formatPeriodForFilename(period);
    // Remove /api from baseUrl for PDF access since PDFs are in public folder
    final pdfBaseUrl = baseUrl.replaceAll('/api', '');
    return '$pdfBaseUrl/assets/slip/$empno-$formattedPeriod.pdf';
  }

  // Convert period to filename format (e.g., "202507" -> "JUL2025")
  static String _formatPeriodForFilename(String period) {
    if (period.length == 6) {
      final year = period.substring(0, 4);
      final month = period.substring(4, 6);
      
      const monthNames = [
        '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      
      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return '${monthNames[monthIndex]}$year';
      }
    }
    // If period is already in correct format (e.g., "JUL2025"), return as is
    return period;
  }

  // Download PDF bytes directly from assets/slip folder
  static Future<List<int>?> downloadPdfBytes(
    String empno,
    String period,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final url = getPdfUrl(empno, period);

      print('Downloading PDF from assets: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('PDF Download response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('PDF downloaded successfully from assets/slip');
        return response.bodyBytes;
      } else {
        print('Failed to download PDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading PDF from assets: $e');
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

      // Use the correct Flutter endpoint from backend routes
      final url = '$baseUrl/flutter/my-slips';

      print('Loading salary slips from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final slips = List<Map<String, dynamic>>.from(data['data'] ?? []);
          
          // Transform data to match AssetsSalarySlip model format
          final transformedSlips = <Map<String, dynamic>>[];
          
          for (var slip in slips) {
            // Extract empno from different possible locations
            String empno = '';
            if (slip['empno'] != null) {
              empno = slip['empno'].toString();
            } else if (slip['employee'] != null && slip['employee']['employee_number'] != null) {
              empno = slip['employee']['employee_number'].toString();
            }

            final period = slip['period'] ?? '';
            
            // Check PDF availability using direct path check
            bool hasPdf = false;
            if (empno.isNotEmpty && period.isNotEmpty) {
              hasPdf = await checkPdfExists(empno, period);
            }
            
            transformedSlips.add({
              'id': slip['id'] ?? 0,
              'empno': empno,
              'period': period,
              'period_formatted': slip['period_formatted'] ?? _formatPeriodForDisplay(period),
              'fullname': slip['fullname'] ?? slip['employee']?['name'] ?? 'Unknown',
              'basic_salary': slip['basic_salary'] ?? slip['basicsalary'] ?? 0,
              'total': slip['total'] ?? 0,
              'pdf_url': empno.isNotEmpty && period.isNotEmpty ? getPdfUrl(empno, period) : '',
              'has_pdf': hasPdf,
            });
          }
          
          return transformedSlips;
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

  // Helper function to format period for display
  static String _formatPeriodForDisplay(String period) {
    if (period.length == 6) {
      final year = period.substring(0, 4);
      final month = period.substring(4, 6);
      
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      
      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return '${months[monthIndex - 1]} $year';
      }
    }
    return period;
  }
}
