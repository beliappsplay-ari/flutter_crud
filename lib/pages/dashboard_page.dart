import 'package:flutter/material.dart';
import 'package:flutter_crud/pages/halaman_produk.dart';
import 'package:flutter_crud/pages/user_profile_page.dart';
import 'package:flutter_crud/pages/assets_salary_slip_page.dart';
import 'package:flutter_crud/pages/salary_slip_page.dart';
import '../services/auth_service.dart';
import '../services/assets_pdf_service.dart';
import '../models/assets_salary_slip.dart';
import 'assets_pdf_viewer.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  int _selectedIndex = 0; // Index halaman yang sedang aktif

  // Daftar halaman yang akan ditampilkan di Bottom Navigation Bar
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardHomePage(onNavigate: _onItemTapped);
      case 1:
        return const AssetsSalarySlipPageContent(); // Content only without navigation
      case 2:
        return const Center(child: Text('Settings Page'));
      case 3:
        return const UserProfilePage();
      default:
        return DashboardHomePage(onNavigate: _onItemTapped);
    }
  }

  // Metode yang dipanggil saat item Bottom Navigation Bar ditekan
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fungsi logout
  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final logoutResult = await _authService.logout();

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login and clear all routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      // Show logout message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(logoutResult.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'HRIS DGE'
              : _selectedIndex == 1
              ? 'PDF Slips'
              : _selectedIndex == 2
              ? 'Settings'
              : 'Profile',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Salary Slips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Dashboard Home Page dengan menu grid
class DashboardHomePage extends StatelessWidget {
  final Function(int)? onNavigate;

  const DashboardHomePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'HRIS - DIAN GARAHA ELEKTRIKA',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions Section
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Menu Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.people,
                  title: 'Employees',
                  subtitle: 'Manage employee data',
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to employees page (for now, show message)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Employees feature - coming soon!'),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.cloud_download,
                  title: 'Salary slips',
                  subtitle: 'View salary slips',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssetsSalarySlipPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Reports',
                  subtitle: 'View analytics & reports',
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reports feature - coming soon!'),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App configuration',
                  color: Colors.grey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings feature - coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Content-only widget for dashboard bottom navigation
class AssetsSalarySlipPageContent extends StatefulWidget {
  const AssetsSalarySlipPageContent({super.key});

  @override
  State<AssetsSalarySlipPageContent> createState() =>
      _AssetsSalarySlipPageContentState();
}

class _AssetsSalarySlipPageContentState
    extends State<AssetsSalarySlipPageContent> {
  List<AssetsSalarySlip> _salarySlips = [];
  List<AssetsSalarySlip> _filteredSlips = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedPeriod;
  List<String> _availablePeriods = [];

  @override
  void initState() {
    super.initState();
    _loadSalarySlips();
  }

  Future<void> _loadSalarySlips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slipsData = await AssetsPdfService.getMySlipsWithPdfInfo();
      final slips = slipsData
          .map((data) => AssetsSalarySlip.fromJson(data))
          .toList();

      // Extract unique periods and sort them (latest first)
      final periods = slips
          .map((slip) => slip.period)
          .where((period) => period.isNotEmpty)
          .toSet()
          .toList();

      periods.sort((a, b) => b.compareTo(a)); // Latest first

      setState(() {
        _salarySlips = slips;
        _filteredSlips = slips;
        _availablePeriods = periods;
        _selectedPeriod = periods.isNotEmpty ? periods.first : null;
        _isLoading = false;
      });

      // Apply initial filter if we have a selected period
      if (_selectedPeriod != null) {
        _filterByPeriod(_selectedPeriod!);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _filteredSlips = _salarySlips
          .where((slip) => slip.period == period)
          .toList();
    });
  }

  void _showAllPeriods() {
    setState(() {
      _selectedPeriod = null;
      _filteredSlips = _salarySlips;
    });
  }

  Future<void> _openPdf(AssetsSalarySlip slip) async {
    if (!slip.hasPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not available for this period'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssetsPdfViewer(
            empno: slip.empno,
            period: slip.period,
            employeeName: slip.fullname,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Period Filter Section
        if (_availablePeriods.isNotEmpty && !_isLoading) _buildPeriodFilter(),

        // Content Section
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Period',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      hint: const Text('Select Period'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'All Periods',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ..._availablePeriods.map((period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue == null) {
                          _showAllPeriods();
                        } else {
                          _filterByPeriod(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredSlips.length} slips',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading server PDF slips...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSalarySlips,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredSlips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedPeriod != null
                  ? 'No PDF slips found for $_selectedPeriod'
                  : 'No server PDF slips found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_selectedPeriod != null) ...[
              const SizedBox(height: 8),
              Text(
                'Try selecting a different period',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSalarySlips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredSlips.length,
        itemBuilder: (context, index) {
          final slip = _filteredSlips[index];
          return _buildSalarySlipCard(slip);
        },
      ),
    );
  }

  Widget _buildSalarySlipCard(AssetsSalarySlip slip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPdf(slip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          slip.periodFormatted,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Employee: ${slip.empno}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // PDF Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: slip.hasPdf ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          slip.hasPdf ? Icons.cloud_done : Icons.cloud_off,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          slip.hasPdf ? 'Salary Slip PDF' : 'No PDF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Salary Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Basic Salary:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          slip.formattedBasicSalary,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          slip.formattedTotal,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: slip.hasPdf ? () => _openPdf(slip) : null,
                  icon: Icon(
                    slip.hasPdf ? Icons.cloud_download : Icons.warning,
                  ),
                  label: Text(
                    slip.hasPdf ? 'View Salary Slip PDF' : 'PDF Not Available',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: slip.hasPdf ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
