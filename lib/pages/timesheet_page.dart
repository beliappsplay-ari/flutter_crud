import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/timesheet_service.dart';
import 'timesheet_pdf_viewer.dart';

class TimesheetPage extends StatefulWidget {
  @override
  _TimesheetPageState createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> {
  List<Map<String, dynamic>> timesheets = [];
  bool isLoading = true;
  String errorMessage = '';
  String? selectedPeriod;
  String? currentUserEmpno; // Track current user empno
  Map<String, dynamic>? mappingInfo;

  @override
  void initState() {
    super.initState();
    print('🏁 [TimesheetPage] initState called');
    loadTimesheets();
  }

  Future<void> loadTimesheets() async {
    try {
      print('🔄 [TimesheetPage] loadTimesheets started');
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final prefs = await SharedPreferences.getInstance();

      // ✅ CHANGED: Use 'token' key to match AuthService
      final token = prefs.getString('token'); // Changed from 'auth_token'
      print(
        '🔍 [TimesheetPage] Token from prefs (key: "token"): ${token?.substring(0, 20)}...',
      );

      if (token == null) {
        setState(() {
          errorMessage = 'No authentication token found. Please login again.';
          isLoading = false;
        });
        return;
      }

      // ✅ REMOVED: Employee loading - hanya ambil data user saat ini
      // Load timesheets untuk current user dengan period filter jika ada
      final result = await TimesheetService.getTimesheetByEmployee(
        token, 
        period: selectedPeriod // Hanya filter period, empno otomatis dari user login
      );

      if (result['success'] == true) {
        final loadedTimesheets = List<Map<String, dynamic>>.from(result['data'] ?? []);
        
        // Ambil empno dari timesheet pertama untuk referensi
        if (loadedTimesheets.isNotEmpty) {
          currentUserEmpno = loadedTimesheets.first['empno']?.toString();
        }

        setState(() {
          timesheets = loadedTimesheets;
          mappingInfo = result['mapping_info'];
          isLoading = false;
          errorMessage = '';
        });
        print('✅ [TimesheetPage] Timesheets loaded: ${timesheets.length} for empno: $currentUserEmpno');
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load timesheets';
          isLoading = false;
          timesheets = [];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading timesheets: $e';
        isLoading = false;
        timesheets = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [TimesheetPage] build() called');
    print('🎨 [TimesheetPage] isLoading: $isLoading');
    print('🎨 [TimesheetPage] errorMessage: $errorMessage');
    print('🎨 [TimesheetPage] timesheets.length: ${timesheets.length}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Timesheet'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [TimesheetPage] Refresh button pressed');
              loadTimesheets();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ REMOVED: Employee filter - otomatis berdasarkan user login
          
          // ✅ Period filter only
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Period',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: Text('All Periods'),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Periods'),
                    ),
                    ...getUniquePeriods().map((period) {
                      final periodValue = period['period']?.toString() ?? '';
                      final periodFormatted = period['period_formatted']?.toString() ?? periodValue;
                      
                      return DropdownMenuItem<String>(
                        value: periodValue,
                        child: Text(periodFormatted),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    print('🔄 [TimesheetPage] Period filter changed: $value');
                    setState(() {
                      selectedPeriod = value;
                    });
                    loadTimesheets(); // Reload data with new filter
                  },
                ),
                SizedBox(height: 8),
                Text(
                  '${timesheets.length} timesheets' + 
                  (currentUserEmpno != null ? ' for employee $currentUserEmpno' : ''),
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ✅ Content area
          Expanded(
            child: Builder(
              builder: (context) {
                print(
                  '🎨 [TimesheetPage] Builder - isLoading: $isLoading, errorMessage: "$errorMessage", timesheets.length: ${timesheets.length}',
                );

                if (isLoading) {
                  print('🎨 [TimesheetPage] Showing loading indicator');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text('Loading timesheets...'),
                      ],
                    ),
                  );
                }

                if (errorMessage.isNotEmpty) {
                  print('🎨 [TimesheetPage] Showing error: $errorMessage');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadTimesheets,
                          child: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (timesheets.isEmpty) {
                  print('🎨 [TimesheetPage] Showing empty state');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Timesheets Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No timesheet data available for your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadTimesheets,
                          child: Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                print('🎨 [TimesheetPage] Showing timesheet list');
                return buildTimesheetList();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getFilteredTimesheets() {
    // Karena kita sudah memfilter di server, langsung return timesheets
    return timesheets;
  }

  // Method untuk mendapatkan unique periods dari timesheets yang tersedia
  List<Map<String, dynamic>> getUniquePeriods() {
    final Map<String, Map<String, dynamic>> uniquePeriods = {};
    
    for (var timesheet in timesheets) {
      final period = timesheet['period']?.toString();
      if (period != null && period.isNotEmpty && !uniquePeriods.containsKey(period)) {
        uniquePeriods[period] = {
          'period': period,
          'period_formatted': timesheet['period_formatted']?.toString() ?? period,
        };
      }
    }
    
    return uniquePeriods.values.toList();
  }

  Widget buildTimesheetList() {
    final filteredTimesheets = getFilteredTimesheets();
    print(
      '📋 [TimesheetPage] Building list with ${filteredTimesheets.length} items',
    );

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: filteredTimesheets.length,
      itemBuilder: (context, index) {
        final timesheet = filteredTimesheets[index];
        print(
          '📋 [TimesheetPage] Building card for index $index: ${timesheet['period']} - ${timesheet['empno']}',
        );
        return buildTimesheetCard(timesheet);
      },
    );
  }

  Widget buildTimesheetCard(Map<String, dynamic> timesheet) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timesheet['period_formatted'] ??
                            timesheet['period'] ??
                            'Unknown Period',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Employee: ${timesheet['employee_name'] ?? 'Unknown'} (${timesheet['empno'] ?? 'N/A'})',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: timesheet['has_pdf'] == true
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timesheet['has_pdf'] == true ? 'PDF Available' : 'No PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // File info
            Row(
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '${timesheet['filename'] ?? 'Unknown'} (${timesheet['file_size_mb'] ?? 0} MB)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.pages, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '${timesheet['page_count'] ?? 0} pages',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Action button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: timesheet['has_pdf'] == true
                      ? () => viewTimesheet(timesheet)
                      : null,
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void viewTimesheet(Map<String, dynamic> timesheet) async {
    try {
      print('👁️ [TimesheetPage] View timesheet: ${timesheet['period']}');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      final period = timesheet['period'];
      final employeeName = timesheet['employee_name'] ?? 'Unknown';
      final empno = currentUserEmpno ?? timesheet['empno'] ?? ''; // Use current user empno
      final accessInfo = timesheet['access_info'] as Map<String, dynamic>?;
      final pdfUrl = accessInfo?['pdf_url'] ?? '';

      if (period == null || period.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid timesheet period')));
        return;
      }

      if (pdfUrl.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF URL not available')));
        return;
      }

      print('📋 Opening PDF viewer for period: $period');
      print('📋 Employee: $employeeName ($empno)');
      print('📋 PDF URL: $pdfUrl');

      // ✅ Navigate ke PDF viewer dengan current user empno
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TimesheetPdfViewer(
            period: period,
            employeeName: employeeName,
            pdfUrl: pdfUrl,
            empno: empno, // Pass current user empno ke PDF viewer
          ),
        ),
      );
    } catch (e) {
      print('💥 Error viewing timesheet: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening timesheet: $e')));
    }
  }
}
