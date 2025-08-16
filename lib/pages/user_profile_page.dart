import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart'; // Pastikan path benar

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) Tampilkan data awal dari SharedPreferences (cepat)
    await _loadFromPrefs();

    // 2) Segarkan dari server (opsional)
    unawaited(_fetchLatestProfile(silent: true));
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user');

      if (raw == null) {
        setState(() {
          _loading = false;
          _error = 'Belum ada data user. Silakan login terlebih dahulu.';
        });
        return;
      }

      final data = jsonDecode(raw);
      setState(() {
        _user = (data is Map) ? Map<String, dynamic>.from(data) : {'raw': data};
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat data user: $e';
      });
    }
  }

  /// Ambil profil terbaru dari API (opsional)
  Future<void> _fetchLatestProfile({bool silent = false}) async {
    // Dapatkan URL API dari .env
    final baseUrl = dotenv.env['API_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      if (!silent) {
        _showSnack('API_URL belum diset di .env');
      }
      return;
    }

    // Ambil token dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Jika token tidak ada, beri tahu user untuk login
    if (token == null || token.isEmpty) {
      if (!silent)
        _showSnack('Token otentikasi tidak ditemukan. Silakan login ulang.');
      // Arahkan ke halaman login jika token tidak ada
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
      return;
    }

    // Ambil user_id dari data yang tersimpan
    final current = _user ?? {};
    final userId = current['id']?.toString();
    if (userId == null || userId.isEmpty) {
      if (!silent) _showSnack('User ID tidak ditemukan pada data lokal');
      return;
    }

    if (!silent) setState(() => _loading = true);

    http.Client? client;
    try {
      client = http.Client();
      final uri = Uri.parse(
        '$baseUrl/profile',
      ).replace(queryParameters: {'user_id': userId});

      final res = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token', // Sertakan token di header
            },
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 401) {
        // Tangani Unauthorized (token kadaluarsa, dll.)
        _showSnack('Sesi Anda habis. Silakan login ulang.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
        return;
      }

      if (res.statusCode != 200) {
        throw Exception('Server error: ${res.statusCode}');
      }

      final body = utf8.decode(res.bodyBytes);
      final json = jsonDecode(body);
      final profile = json['data'] as Map<String, dynamic>?;

      if (profile == null) {
        if (!silent) _showSnack('Profil tidak ditemukan di server');
        return;
      }

      final merged = {...current, ...profile};

      setState(() {
        _user = merged;
        _loading = false;
        _error = null;
      });

      if (!silent) _showSnack('Profil diperbarui');
    } on TimeoutException {
      if (!silent) {
        setState(() => _loading = false);
        _showSnack('Timeout saat mengambil profil');
      }
    } catch (e) {
      if (!silent) {
        setState(() => _loading = false);
        _showSnack('Gagal memperbarui profil: $e');
      }
    } finally {
      client?.close();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _v(String key, {String fallback = '—'}) {
    final value = _user?[key];
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _fetchLatestProfile(silent: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? _EmptyState(
              message: _error!,
              onLogin: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  name: _v('fullname', fallback: _v('user_name')),
                  role: _v('position', fallback: 'Posisi / Jabatan'),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Informasi Pribadi'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.badge,
                        label: 'Employee No',
                        value: _v('empno'),
                      ),
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: _v('fullname', fallback: _v('user_name')),
                      ),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _v('email'),
                      ),
                      // Tambahkan _InfoTile lainnya sesuai data dari API
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ... (widget pembantu lainnya seperti _Header, _InfoTile, dll. tetap sama)

class _Header extends StatelessWidget {
  final String name;
  final String role;
  const _Header({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          _Avatar(name: name),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(color: scheme.onPrimaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Nama User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(role.isNotEmpty ? role : 'Posisi / Jabatan'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: null,
            icon: Icon(
              Icons.camera_alt_outlined,
              color: scheme.onPrimaryContainer,
            ),
            tooltip: 'Ubah Foto',
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  String _initials(String n) {
    final parts = n
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 32,
      backgroundColor: scheme.onPrimaryContainer.withOpacity(0.15),
      child: Text(
        _initials(name),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label),
      subtitle: Text(value.isNotEmpty ? value : '—'),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onLogin;

  const _EmptyState({required this.message, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: const Text('Ke Halaman Login'),
            ),
          ],
        ),
      ),
    );
  }
}
