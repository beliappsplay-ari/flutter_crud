import 'package:flutter/material.dart';
// TIDAK mengimport halaman_produk.dart untuk menghindari circular import.

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya'), centerTitle: true),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Header(name: 'Nama User', role: 'Posisi / Jabatan'),
          const SizedBox(height: 16),

          const _SectionTitle('Informasi Pribadi'),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: theme.colorScheme.surface,
            child: const Column(
              children: [
                _InfoTile(icon: Icons.badge, label: 'Employee No', value: '—'),
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: '—',
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: '—',
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: '—',
                ),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: '—',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const _SectionTitle('Organisasi'),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: theme.colorScheme.surface,
            child: const Column(
              children: [
                _InfoTile(
                  icon: Icons.apartment_outlined,
                  label: 'Department',
                  value: '—',
                ),
                _InfoTile(
                  icon: Icons.work_outline,
                  label: 'Position',
                  value: '—',
                ),
                _InfoTile(
                  icon: Icons.schedule_outlined,
                  label: 'Join Date',
                  value: '—',
                ),
                _InfoTile(
                  icon: Icons.place_outlined,
                  label: 'Office Location',
                  value: '—',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: null, // TODO: aktifkan saat form siap
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profil'),
          ),
        ],
      ),

      // >>> PENTING: bottomNavigationBar dipasang DI SINI
      bottomNavigationBar: _buildBottomNavBar(context, currentIndex: 3),
    );
  }

  /// Builder BottomNavigationBar untuk halaman ini
  BottomNavigationBar _buildBottomNavBar(
    BuildContext context, {
    int currentIndex = 3,
  }) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'About'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
      ],
      onTap: (index) {
        if (index == currentIndex) return; // sudah di tab yang sama

        switch (index) {
          case 0:
            // Kembali ke halaman sebelumnya (HalamanProduk) tanpa circular import
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // fallback: tampilkan pesan / nanti bisa pakai named route
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada halaman sebelumnya')),
              );
            }
            break;
          case 1:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings: coming soon')),
            );
            break;
          case 2:
            showAboutDialog(
              context: context,
              applicationName: 'HRIS DGE',
              applicationVersion: '1.0.0',
            );
            break;
          case 3:
          default:
            break;
        }
      },
    );
  }
}

/// ===== Widget-Widget kecil untuk membangun UI =====

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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(role),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: null, // TODO: quick edit / ubah avatar
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
      subtitle: Text(value),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
