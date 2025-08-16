// import 'package:flutter/material.dart';
// import 'package:flutter_crud/pages/halaman_produk.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Fixed import
import 'pages/login_page.dart';
import 'pages/halaman_produk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

void main() async {
  // Inisialisasi Flutter binding dulu
  WidgetsFlutterBinding.ensureInitialized();

  // Baru load environment
  await dotenv.load();

  // Cek status login dari SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getString('user') != null;

  // Sekarang kita berikan parameter isLoggedIn
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(title: 'HRIS DGE', home: HalamanProduk());
//   }
// }

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRIS DGE',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: isLoggedIn ? const HalamanProduk() : const LoginPage(),
    );
  }
}
