import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Get user menu access based on emp_masters.akses field
  static Future<Map<String, dynamic>?> getUserMenuAccess() async {
    try {
      print('🔍 [MenuService] Getting user menu access...');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('❌ [MenuService] No token found');
        return null;
      }
      
      print('🔍 [MenuService] Token found, calling API...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/flutter/menu-access'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📡 [MenuService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [MenuService] Menu access data received');
        print('📋 [MenuService] Employee: ${data['data']['employee_info']['fullname']}');
        print('🔑 [MenuService] Access: ${data['data']['employee_info']['access_string']}');
        print('📱 [MenuService] Total menus: ${data['total_menus']}');
        return data;
      } else {
        print('❌ [MenuService] Failed with status: ${response.statusCode}');
        print('❌ [MenuService] Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [MenuService] Error getting menu access: $e');
      return null;
    }
  }
}

class MenuItem {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String color;
  final String route;
  final bool enabled;
  final bool? accessRequired;

  MenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.enabled,
    this.accessRequired,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: json['icon'] ?? 'help',
      color: json['color'] ?? 'grey',
      route: json['route'] ?? '/',
      enabled: json['enabled'] ?? false,
      accessRequired: json['access_required'],
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, title: $title, enabled: $enabled)';
  }
}

class EmployeeInfo {
  final String empno;
  final String fullname;
  final String accessString;
  final List<int> accessArray;

  EmployeeInfo({
    required this.empno,
    required this.fullname,
    required this.accessString,
    required this.accessArray,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      empno: json['empno'] ?? '',
      fullname: json['fullname'] ?? '',
      accessString: json['access_string'] ?? '',
      accessArray: List<int>.from(json['access_array'] ?? []),
    );
  }

  @override
  String toString() {
    return 'EmployeeInfo(empno: $empno, fullname: $fullname, access: $accessString)';
  }
}
