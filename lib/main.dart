import 'package:flutter/material.dart';
import 'package:flutter_crud/pages/dashboard_page.dart';
import 'package:flutter_crud/pages/login_page.dart';
import 'package:flutter_crud/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Pastikan binding Flutter diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRIS DGE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget untuk mengecek authentication status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Verify token dengan server
        final result = await _authService.getCurrentUser();
        if (mounted) {
          setState(() {
            _isLoggedIn = result.success;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Error checking auth status, default to not logged in
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const DashboardPage() : const LoginPage();
  }
}
