import 'package:flutter/material.dart';

/// Halaman Dashboard Utama Pengguna.
/// 
/// Menampilkan ringkasan profil (dari model User & Profile di Django)
/// serta statistik keberlanjutan (wears, avg cost per wear, score).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Halo, Brigitta!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Selamat datang di pusat kendali portofolio fashion-mu. '
            'Pantau statistik pakaian dan kelola profilmu di sini.',
          ),
          const SizedBox(height: 24),

          // === SECTION: STATISTIK WARDROBE ===
          Text(
            'Ringkasan Wardrobe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          
          // (Nanti angka-angka ini kita ambil dari API Django)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                title: 'Total Item',
                value: '0',
                icon: Icons.checkroom,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Total Wears',
                value: '0',
                icon: Icons.repeat,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Skor',
                value: '0',
                icon: Icons.eco,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === SECTION: PROFIL & KONTAK ===
          Text(
            'Informasi Profil',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          const _FeatureCard(
            icon: Icons.person_outline,
            title: 'Data Akun',
            description: 'Nama: Alice Wonder\nEmail: alice@example.com',
          ),
          const _FeatureCard(
            icon: Icons.phone_outlined,
            title: 'Kontak & Alamat',
            description: 'Phone: +62 812 3456 7890\nAlamat: Jl. Merdeka No. 1, Jakarta',
          ),
          
          const SizedBox(height: 16),
          
          // === TOMBOL EDIT PROFIL ===
          ElevatedButton.icon(
            onPressed: () {
              // Nanti diarahkan ke halaman Edit Profile
              // Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage()));
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KOMPONEN KUSTOM (Biar Rapi)
// ==========================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: MediaQuery.of(context).size.width / 3.5,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}