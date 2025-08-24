import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'salary_slip_pdf_viewer.dart';

class SalarySlipPage extends StatefulWidget {
  const SalarySlipPage({super.key});

  @override
  State<SalarySlipPage> createState() => _SalarySlipPageState();
}

class _SalarySlipPageState extends State<SalarySlipPage> {
  List<Map<String, dynamic>> salarySlips = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedPeriod;
  List<String> availablePeriods = [];

  @override
  void initState() {
    super.initState();
    _fetchSalarySlips();
  }

  String? get apiUrl => dotenv.env['API_URL'];

  Future<void> _fetchSalarySlips() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'Authentication token not found';
            isLoading = false;
          });
        }
        return;
      }

      String url = '${apiUrl ?? "http://10.0.2.2:8000/api"}/salary-slips';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> slipsData = data['data'];
          if (mounted) {
            setState(() {
              salarySlips = slipsData.cast<Map<String, dynamic>>();
              _updateAvailablePeriods();
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage = data['message'] ?? 'Failed to load salary slips';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Failed to load salary slips: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  void _updateAvailablePeriods() {
    final periods = salarySlips
        .map((slip) => slip['period']?.toString() ?? '')
        .where((period) => period.isNotEmpty)
        .toSet()
        .toList();

    periods.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

    setState(() {
      availablePeriods = periods;
      if (periods.isNotEmpty && selectedPeriod == null) {
        selectedPeriod = periods.first; // Set to newest period
      }
    });
  }

  List<Map<String, dynamic>> get filteredSalarySlips {
    if (selectedPeriod == null || selectedPeriod!.isEmpty) {
      return salarySlips;
    }
    return salarySlips
        .where((slip) => slip['period'] == selectedPeriod)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF Slips',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildPeriodFilter(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchSalarySlips,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildSalarySlipsList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Timesheet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Salary Slip',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/timesheet');
              break;
            case 2:
              // Current page
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Period: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: DropdownButton<String>(
              value: selectedPeriod,
              hint: const Text('Select Period'),
              isExpanded: true,
              items: availablePeriods.map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(_formatPeriod(period)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPeriod = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySlipsList() {
    final slips = filteredSalarySlips;

    if (slips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No salary slips found for selected period',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slips.length,
      itemBuilder: (context, index) {
        return _buildSalarySlipCard(slips[index]);
      },
    );
  }

  Widget _buildSalarySlipCard(Map<String, dynamic> slip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slip['employee']?['fullname'] ??
                  slip['employee_name'] ??
                  'Unknown Employee',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Employee No: ${slip['empno']?.toString() ?? 'N/A'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Basic Salary: ${_formatCurrency(slip['basic_salary'])}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Total: ${_formatCurrency(slip['net_salary'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _viewPDF(slip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View salary slip PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(String period) {
    if (period.isEmpty) return 'Unknown Period';

    // Assuming period format is YYYY-MM
    final parts = period.split('-');
    if (parts.length == 2) {
      final year = parts[0];
      final month = parts[1];

      final months = [
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
