import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimesheetService {
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // ✅ CHANGED: dari 'auth_token' ke 'token'
  }

  static Future<Map<String, dynamic>> getMyTimesheets(String token) async {
    try {
      print('🔍 [TimesheetService] Starting getMyTimesheets...');
      print('🔍 [TimesheetService] Using token key: "token"'); // ✅ Debug info
      print(
        '🔍 [TimesheetService] Token (first 20 chars): ${token.substring(0, 20)}...',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/timesheet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [TimesheetService] Response status: ${response.statusCode}');
      print('📄 [TimesheetService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          List<dynamic> rawData = jsonResponse['data'] ?? [];
          List<Map<String, dynamic>> timesheets = [];

          // Get current user info
          final userInfo = await _getCurrentUserInfo(token);

          for (var item in rawData) {
            try {
              timesheets.add({
                'period': item['period']?.toString() ?? '',
                'period_formatted': item['period_formatted']?.toString() ?? '',
                'filename': item['filename']?.toString() ?? '',
                'file_size_mb': (item['file_size_mb'] is num) ? item['file_size_mb'].toDouble() : 0.0,
                'page_count': (item['page_count'] is num) ? item['page_count'].toInt() : 0,
                'period_mapping': item['period_mapping'] ?? {},
                'access_info': item['access_info'] ?? {},
                'employee_name': userInfo['name']?.toString() ?? 'Unknown',
                'empno': userInfo['empno']?.toString() ?? 'unknown',
                'has_pdf': item['has_pdf'] ?? true,
                'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              });
            } catch (e) {
              print('❌ Error parsing timesheet item: $e');
            }
          }

          print('✅ Parsed timesheets count: ${timesheets.length}');

          return {
            'success': true,
            'data': timesheets,
            'total': jsonResponse['total'] ?? timesheets.length,
            'mapping_info': jsonResponse['mapping_info'] ?? {},
            'directory': jsonResponse['directory'] ?? '',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Unknown error',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': [],
        };
      }
    } catch (e) {
      print('💥 Exception in getMyTimesheets: $e');
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  // Add method yang dibutuhkan PDF viewer:
  static Future<List<int>?> downloadTimesheetPdfBytes(String period, {String? empno}) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No token available for PDF download');
        return null;
      }

      print('📥 Downloading PDF bytes for period: $period, empno: $empno');

      // Build URL dengan parameter empno jika tersedia
      String url;
      if (empno != null && empno.isNotEmpty) {
        url = '$baseUrl/flutter/timesheet/$period/pdf?empno=$empno';
      } else {
        url = '$baseUrl/flutter/timesheet/$period/pdf';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      print('📥 PDF download response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
          '✅ PDF downloaded successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        print('❌ PDF download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 PDF download error: $e');
      return null;
    }
  }

  // Method untuk mendapatkan daftar employee yang memiliki timesheet
  static Future<Map<String, dynamic>> getTimesheetEmployees(String token) async {
    try {
      print('🔍 [TimesheetService] Getting timesheet employees...');

      final response = await http.get(
        Uri.parse('$baseUrl/timesheet/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [TimesheetService] Employees response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          // ✅ FIXED: Properly parse employee data with type safety
          List<dynamic> rawEmployees = jsonResponse['data'] ?? [];
          List<Map<String, dynamic>> employees = [];
          
          for (var employee in rawEmployees) {
            employees.add({
              'empno': employee['empno']?.toString() ?? '',
              'name': employee['name']?.toString() ?? '',
              'fullname': employee['fullname']?.toString() ?? employee['name']?.toString() ?? '',
              'page_number': (employee['page_number'] is num) ? employee['page_number'].toInt() : 0,
            });
          }
          
          return {
            'success': true,
            'data': employees,
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to get employees',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': [],
        };
      }
    } catch (e) {
      print('💥 Exception in getTimesheetEmployees: $e');
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  // Method untuk mendapatkan timesheet berdasarkan empno dan period
  // ✅ SIMPLIFIED: Untuk single user, gunakan endpoint original
  static Future<Map<String, dynamic>> getTimesheetByEmployee(String token, {String? empno, String? period}) async {
    try {
      print('🔍 [TimesheetService] Getting timesheet for current user, period: $period');

      // ✅ CHANGED: Gunakan endpoint Flutter yang baru
      String url = '$baseUrl/timesheet';
      
      // Hanya tambah period filter jika ada
      if (period != null && period.isNotEmpty) {
        url += '?period=$period';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [TimesheetService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          // ✅ FIXED: Handle both Map and List response formats
          dynamic rawData = jsonResponse['data'];
          List<Map<String, dynamic>> timesheets = [];
          
          // If data is a Map, convert to list format
          if (rawData is Map<String, dynamic>) {
            // Response is a single object, wrap in list
            rawData = [rawData];
          } else if (rawData is! List) {
            // Fallback to empty list if unexpected format
            rawData = [];
          }

          for (var item in rawData) {
            try {
              timesheets.add({
                'period': item['period']?.toString() ?? '',
                'period_formatted': item['period_formatted']?.toString() ?? '',
                'filename': item['filename']?.toString() ?? '',
                'file_size_mb': (item['file_size_mb'] is num) ? item['file_size_mb'].toDouble() : 0.0,
                'page_count': (item['page_count'] is num) ? item['page_count'].toInt() : 0,
                'period_mapping': item['period_mapping'] ?? {},
                'access_info': item['access_info'] ?? {},
                'employee_name': item['employee_name']?.toString() ?? 'Unknown',
                'empno': item['empno']?.toString() ?? 'unknown', // ✅ FIXED: Force to string
                'has_pdf': item['has_pdf'] ?? true,
                'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              });
            } catch (e) {
              print('❌ Error parsing timesheet item: $e');
            }
          }

          return {
            'success': true,
            'data': timesheets,
            'total': jsonResponse['total'] ?? timesheets.length,
            'mapping_info': jsonResponse['mapping_info'] ?? {},
            'filters_applied': {
              'period': period,
              'note': 'Auto-filtered by current user empno'
            },
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Unknown error',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'data': [],
        };
      }
    } catch (e) {
      print('💥 Exception in getTimesheetByEmployee: $e');
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  static Future<Map<String, dynamic>> _getCurrentUserInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final user = data['data'];
          final employee = user['employee'];

          return {
            'name': user['name']?.toString() ?? 'Unknown',
            'email': user['email']?.toString() ?? '',
            'empno': employee?['empno']?.toString() ?? user['empno']?.toString() ?? 'unknown', // ✅ FIXED: Try employee first, then user empno
            'fullname': employee?['fullname']?.toString() ?? user['name']?.toString() ?? 'Unknown',
          };
        }
      }
    } catch (e) {
      print('💥 Error getting user info: $e');
    }

    return {
      'name': 'Unknown',
      'email': '',
      'empno': 'unknown',
      'fullname': 'Unknown',
    };
  }

  static Future<http.Response> downloadTimesheet(
    String token,
    String period,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flutter/timesheet/$period/pdf'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );
      return response;
    } catch (e) {
      print('💥 Download error: $e');
      rethrow;
    }
  }
}
