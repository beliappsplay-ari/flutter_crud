import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'salary_slip_pdf_viewer.dart';

class SalarySlipPage extends StatefulWidget {
  const SalarySlipPage({super.key});

  @override
  State<SalarySlipPage> createState() => _SalarySlipPageState();
}

class _SalarySlipPageState extends State<SalarySlipPage> {
  List<dynamic> allSalarySlips = [];
  List<String> availablePeriods = [];
  String? selectedPeriod;
  Map<String, dynamic>? currentSlip;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSalarySlips();
  }

  // Get token dari SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> loadSalarySlips() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getToken();

      if (token == null) {
        setState(() {
          errorMessage = 'No authentication token found. Please login again.';
          isLoading = false;
        });
        return;
      }

      final apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
      final url = '$apiUrl/salary-slips';

      print('Loading salary slips from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            allSalarySlips = data['data'] ?? [];

            // Extract unique periods and sort them descending
            availablePeriods = allSalarySlips
                .map((slip) => slip['period'].toString())
                .toSet()
                .toList();

            availablePeriods.sort((a, b) => b.compareTo(a)); // Latest first

            // Auto-select the latest period if available
            if (availablePeriods.isNotEmpty) {
              selectedPeriod = availablePeriods.first;
              _updateCurrentSlip();
            }

            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load salary slips';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Authentication expired. Please login again.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading salary slips: $e');
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void _updateCurrentSlip() {
    if (selectedPeriod != null) {
      currentSlip = allSalarySlips.firstWhere(
        (slip) => slip['period'] == selectedPeriod,
        orElse: () => null,
      );
    } else {
      currentSlip = null;
    }
  }

  String _formatPeriod(String period) {
    if (period.length == 6) {
      final year = period.substring(0, 4);
      final month = period.substring(4, 6);

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return '${months[monthIndex - 1]} $year';
      }
    }
    return period;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Slips'),
        backgroundColor: Colors.lightBlue[300],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadSalarySlips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Salary Slip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 1, // Salary Slip is selected
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          switch (index) {
            case 0:
              // Navigate back to Dashboard
              Navigator.of(context).pop();
              break;
            case 1:
              // Already on Salary Slip page
              break;
            case 2:
              // Settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings page coming soon!')),
              );
              break;
            case 3:
              // Profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page coming soon!')),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading salary slips...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadSalarySlips,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (availablePeriods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Salary Slips Found', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'There are no salary slip records to display.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadSalarySlips,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period Filter Section
          _buildPeriodFilter(),
          
          const SizedBox(height: 20),
          
          // Salary Slip Cards
          ...allSalarySlips.map((slip) => _buildSalarySlipCard(slip)).toList(),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter by Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPeriod,
                    isExpanded: true,
                    hint: const Text('Select period'),
                    items: availablePeriods.map((period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPeriod = newValue;
                        _updateCurrentSlip();
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '${allSalarySlips.length} slips',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalarySlipCard(Map<String, dynamic> slip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Period
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatPeriod(slip['period'] ?? ''),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (slip['has_pdf'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Salary Slip PDF',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Employee Info
            Text(
              'Employee: ${slip['empno'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Salary Information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Salary:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        _formatCurrency(slip['basic_salary']),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        _formatCurrency(slip['total']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // PDF Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewPDF(slip),
                icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                label: const Text(
                  'View salary slip PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';

    final value = amount is String
        ? double.tryParse(amount) ?? 0
        : amount.toDouble();
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _viewPDF(Map<String, dynamic> slip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalarySlipPDFViewer(
          salarySlipId: slip['id'],
          employeeName:
              slip['employee']?['fullname'] ??
              slip['employee_name'] ??
              'Unknown',
          period: slip['period'] ?? 'Unknown',
        ),
      ),
    );
  }
}

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';

    final value = amount is String
        ? double.tryParse(amount) ?? 0
        : amount.toDouble();
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _viewPDF(Map<String, dynamic> slip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalarySlipPDFViewer(
          salarySlipId: slip['id'],
          employeeName:
              slip['employee']?['fullname'] ??
              slip['employee_name'] ??
              'Unknown',
          period: slip['period'] ?? 'Unknown',
        ),
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> slip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Salary Slip Details - ${_formatPeriod(slip['period'] ?? '')}',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Employee Information', [
                _buildDetailRow(
                  'Employee Name',
                  slip['employee']?['fullname'] ??
                      slip['employee_name'] ??
                      'N/A',
                ),
                _buildDetailRow(
                  'Employee No',
                  slip['empno']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Period',
                  _formatPeriod(slip['period'] ?? 'N/A'),
                ),
              ]),

              const SizedBox(height: 16),

              if (slip['details'] != null) ...[
                _buildDetailSection(
                  'Income Breakdown',
                  _buildIncomeRows(slip['details']['income']),
                ),

                const SizedBox(height: 16),

                _buildDetailSection(
                  'Deduction Breakdown',
                  _buildDeductionRows(slip['details']['deductions']),
                ),

                const SizedBox(height: 16),
              ],

              _buildDetailSection('Summary', [
                _buildDetailRow(
                  'Total Income',
                  _formatCurrency(slip['total_income']),
                  isTotal: true,
                ),
                _buildDetailRow(
                  'Total Deductions',
                  _formatCurrency(slip['deductions']),
                  isTotal: true,
                ),
                const Divider(),
                _buildDetailRow(
                  'NET SALARY',
                  _formatCurrency(slip['net_salary']),
                  isTotal: true,
                  isNetSalary: true,
                ),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _viewPDF(slip);
            },
            child: const Text('View PDF'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIncomeRows(Map<String, dynamic> income) {
    List<Widget> rows = [];

    // Helper function to check if value is greater than 0
    bool hasValue(dynamic value) {
      if (value == null) return false;
      final numValue = value is String
          ? double.tryParse(value) ?? 0
          : value.toDouble();
      return numValue > 0;
    }

    // Add income items only if they have value > 0
    if (hasValue(income['basic_salary'])) {
      rows.add(
        _buildDetailRow(
          'Basic Salary',
          _formatCurrency(income['basic_salary']),
        ),
      );
    }

    if (hasValue(income['transport'])) {
      rows.add(
        _buildDetailRow(
          'Transport Allowance',
          _formatCurrency(income['transport']),
        ),
      );
    }

    if (hasValue(income['meal'])) {
      rows.add(
        _buildDetailRow('Meal Allowance', _formatCurrency(income['meal'])),
      );
    }

    if (hasValue(income['overtime'])) {
      rows.add(
        _buildDetailRow('Overtime', _formatCurrency(income['overtime'])),
      );
    }

    if (hasValue(income['other_income'])) {
      rows.add(
        _buildDetailRow(
          'Other Income',
          _formatCurrency(income['other_income']),
        ),
      );
    }

    if (hasValue(income['medical'])) {
      rows.add(
        _buildDetailRow(
          'Medical Allowance',
          _formatCurrency(income['medical']),
        ),
      );
    }

    if (hasValue(income['bpjs_company'])) {
      rows.add(
        _buildDetailRow(
          'BPJS Company',
          _formatCurrency(income['bpjs_company']),
        ),
      );
    }

    // If no income items, show at least basic salary
    if (rows.isEmpty) {
      rows.add(
        _buildDetailRow(
          'Basic Salary',
          _formatCurrency(income['basic_salary'] ?? 0),
        ),
      );
    }

    return rows;
  }

  List<Widget> _buildDeductionRows(Map<String, dynamic> deductions) {
    List<Widget> rows = [];

    // Helper function to check if value is greater than 0
    bool hasValue(dynamic value) {
      if (value == null) return false;
      final numValue = value is String
          ? double.tryParse(value) ?? 0
          : value.toDouble();
      return numValue > 0;
    }

    // Add deduction items only if they have value > 0
    if (hasValue(deductions['tax'])) {
      rows.add(
        _buildDetailRow('Income Tax', _formatCurrency(deductions['tax'])),
      );
    }

    if (hasValue(deductions['jkm'])) {
      rows.add(_buildDetailRow('JKM', _formatCurrency(deductions['jkm'])));
    }

    if (hasValue(deductions['jht'])) {
      rows.add(_buildDetailRow('JHT', _formatCurrency(deductions['jht'])));
    }

    if (hasValue(deductions['bpjs_employee'])) {
      rows.add(
        _buildDetailRow(
          'BPJS Employee',
          _formatCurrency(deductions['bpjs_employee']),
        ),
      );
    }

    if (hasValue(deductions['personal_advance'])) {
      rows.add(
        _buildDetailRow(
          'Personal Advance',
          _formatCurrency(deductions['personal_advance']),
        ),
      );
    }

    if (hasValue(deductions['koperasi'])) {
      rows.add(
        _buildDetailRow('Koperasi', _formatCurrency(deductions['koperasi'])),
      );
    }

    if (hasValue(deductions['loan_car'])) {
      rows.add(
        _buildDetailRow('Loan Car', _formatCurrency(deductions['loan_car'])),
      );
    }

    // If no deductions, show a message
    if (rows.isEmpty) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No deductions for this period',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isNetSalary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isNetSalary ? Colors.green[700] : null,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNetSalary
                  ? Colors.green[700]
                  : (isTotal ? Colors.blue[700] : null),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
