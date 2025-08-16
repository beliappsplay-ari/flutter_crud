import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_crud/tambah_produk.dart';
import 'package:http/http.dart' as http;

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  List _listdata = [];
  bool _loading = true;
  String _errorMessage = '';

  Future _getData() async {
    // List URL untuk dicoba secara berurutan
    //List<String> urls = ['http://192.168.0.121:80/api_hris/read.php'];
    List<String> urls = ['http://192.168.0.103:80/api_hris/read.php'];

    for (String url in urls) {
      try {
        print('Mencoba koneksi ke: $url');

        // Buat client dengan konfigurasi khusus
        var client = http.Client();

        final response = await client
            .get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'User-Agent': 'Flutter App',
              },
            )
            .timeout(
              Duration(seconds: 10), // Kurangi timeout untuk testing
              onTimeout: () {
                throw TimeoutException('Koneksi timeout setelah 10 detik');
              },
            );

        print('Status response: ${response.statusCode}');
        print('Isi response: ${response.body}');

        if (response.statusCode == 200) {
          final responseBody = response.body;

          // Cek apakah response kosong
          if (responseBody.isEmpty) {
            throw Exception('Response kosong dari server');
          }

          // Coba parse JSON
          try {
            final data = jsonDecode(responseBody);
            setState(() {
              _listdata = data is List ? data : [data];
              _loading = false;
              _errorMessage = '';
            });
            print('Berhasil terhubung ke: $url');
            client.close();
            return; // Keluar dari loop jika berhasil
          } catch (e) {
            throw Exception('Gagal parsing JSON: $e');
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('Gagal dengan URL $url: $e');
        continue; // Lanjut ke URL berikutnya
      }
    }

    // Jika semua URL gagal
    setState(() {
      _loading = false;
      _errorMessage =
          'Tidak dapat terhubung ke server. Semua URL telah dicoba.';
    });
    _showErrorSnackBar('Tidak dapat terhubung ke server');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _loading = true;
                _errorMessage = '';
              });
              _getData();
            },
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HRIS DGE'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
                _errorMessage = '';
              });
              _getData();
            },
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _errorMessage = '';
                      });
                      _getData();
                    },
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _listdata.isEmpty
          ? Center(child: Text('Tidak ada data'))
          : ListView.builder(
              itemCount: _listdata.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      _listdata[index]['fullname'] ?? 'Nama tidak tersedia',
                    ),
                    subtitle: Text(
                      _listdata[index]['empno'] ?? 'Nomor tidak tersedia',
                    ),
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahProduk()),
          ).then((value) {
            // Refresh data setelah kembali dari halaman tambah
            if (value == true) {
              _getData();
            }
          });
        },
      ),
      bottomNavigationBar: bottomNavigationBar(),
    );
  }

  BottomNavigationBar bottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      ],
      currentIndex: 0,
      onTap: (index) {
        // Handle navigation if needed
      },
    );
  }
}
