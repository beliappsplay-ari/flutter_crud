import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class EmployeeService {
  Future<DashboardResult> getDashboardData() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard'), headers: await _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return DashboardResult.success(data: data['data']);
      } else {
        return DashboardResult.error(
          data['message'] ?? 'Failed to get dashboard data',
        );
      }
    } on TimeoutException {
      return DashboardResult.error('Connection timeout');
    } catch (e) {
      return DashboardResult.error('Network error: $e');
    }
  }

  // Get salary slips
  Future<SalarySlipResult> getSalarySlips() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/salary-slips'), headers: await _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SalarySlipResult.success(data: data['data']);
      } else {
        return SalarySlipResult.error(
          data['message'] ?? 'Failed to get salary slips',
        );
      }
    } on TimeoutException {
      return SalarySlipResult.error('Connection timeout');
    } catch (e) {
      return SalarySlipResult.error('Network error: $e');
    }
  }

  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:8000/api';
  final AuthService _authService = AuthService();

  // Headers dengan auth token
  Future<Map<String, String>> get _headers async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get current user dengan employee data lengkap
  Future<EmployeeResult> getCurrentUserWithEmployee() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/me'), headers: await _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']);
        return EmployeeResult.success(user: user);
      } else if (response.statusCode == 401) {
        return EmployeeResult.error('Session expired. Please login again.');
      } else {
        return EmployeeResult.error(
          data['message'] ?? 'Failed to get user data',
        );
      }
    } on TimeoutException {
      return EmployeeResult.error('Connection timeout');
    } catch (e) {
      return EmployeeResult.error('Network error: $e');
    }
  }

  // Get employee profile by user ID
  Future<EmployeeResult> getEmployeeProfile(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/employee/$userId'), headers: await _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final employee = Employee.fromJson(data['data']);
        return EmployeeResult.success(employee: employee);
      } else {
        return EmployeeResult.error(
          data['message'] ?? 'Failed to get employee data',
        );
      }
    } on TimeoutException {
      return EmployeeResult.error('Connection timeout');
    } catch (e) {
      return EmployeeResult.error('Network error: $e');
    }
  }

  // Update employee data
  Future<EmployeeResult> updateEmployee(
    int employeeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/employee/$employeeId'),
            headers: await _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final employee = Employee.fromJson(responseData['data']);
        return EmployeeResult.success(employee: employee);
      } else {
        return EmployeeResult.error(
          responseData['message'] ?? 'Failed to update employee',
        );
      }
    } on TimeoutException {
      return EmployeeResult.error('Connection timeout');
    } catch (e) {
      return EmployeeResult.error('Network error: $e');
    }
  }

  // Get all employees (untuk admin)
  Future<EmployeeListResult> getAllEmployees() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/employees'), headers: await _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<Employee> employees = (data['data'] as List)
            .map((item) => Employee.fromJson(item))
            .toList();
        return EmployeeListResult.success(employees: employees);
      } else {
        return EmployeeListResult.error(
          data['message'] ?? 'Failed to get employees',
        );
      }
    } on TimeoutException {
      return EmployeeListResult.error('Connection timeout');
    } catch (e) {
      return EmployeeListResult.error('Network error: $e');
    }
  }
}

class DashboardResult {
  final bool success;
  final String message;
  final dynamic data;

  DashboardResult._({required this.success, required this.message, this.data});

  factory DashboardResult.success({dynamic data, String? message}) {
    return DashboardResult._(
      success: true,
      message: message ?? 'Success',
      data: data,
    );
  }

  factory DashboardResult.error(String message) {
    return DashboardResult._(success: false, message: message);
  }
}

class SalarySlipResult {
  final bool success;
  final String message;
  final dynamic data;

  SalarySlipResult._({required this.success, required this.message, this.data});

  factory SalarySlipResult.success({dynamic data, String? message}) {
    return SalarySlipResult._(
      success: true,
      message: message ?? 'Success',
      data: data,
    );
  }

  factory SalarySlipResult.error(String message) {
    return SalarySlipResult._(success: false, message: message);
  }
}

// Result classes
class EmployeeResult {
  final bool success;
  final String message;
  final User? user;
  final Employee? employee;

  EmployeeResult._({
    required this.success,
    required this.message,
    this.user,
    this.employee,
  });

  factory EmployeeResult.success({
    User? user,
    Employee? employee,
    String? message,
  }) {
    return EmployeeResult._(
      success: true,
      message: message ?? 'Success',
      user: user,
      employee: employee,
    );
  }

  factory EmployeeResult.error(String message) {
    return EmployeeResult._(success: false, message: message);
  }
}

class EmployeeListResult {
  final bool success;
  final String message;
  final List<Employee>? employees;

  EmployeeListResult._({
    required this.success,
    required this.message,
    this.employees,
  });

  factory EmployeeListResult.success({
    List<Employee>? employees,
    String? message,
  }) {
    return EmployeeListResult._(
      success: true,
      message: message ?? 'Success',
      employees: employees,
    );
  }

  factory EmployeeListResult.error(String message) {
    return EmployeeListResult._(success: false, message: message);
  }
}
