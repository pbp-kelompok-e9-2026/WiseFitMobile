import 'package:flutter/material.dart';

/// Halaman Modul 1: Wardrobe Management.
///
/// Checkpoint 1: kerangka halaman. Data dari endpoint
/// `/api/v1/wardrobe/` akan disambungkan di tahap berikutnya.
class WardrobePage extends StatelessWidget {
  const WardrobePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Kelola koleksi pakaianmu',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Pantau pakaian yang kamu miliki, frekuensi pemakaian, '
            'dan nilai Cost per Wear untuk keputusan belanja yang lebih bijak.',
          ),
          const SizedBox(height: 16),
          const _FeatureCard(
            icon: Icons.checkroom,
            title: 'Koleksi pakaian digital',
            description:
                'Lihat seluruh daftar pakaian dan saring berdasarkan kategori.',
          ),
          const _FeatureCard(
            icon: Icons.add_circle_outline,
            title: 'Tambah & kelola item pakaian',
            description:
                'Catat nama, kategori, material, harga, tanggal beli, dan foto.',
          ),
          const _FeatureCard(
            icon: Icons.repeat,
            title: 'Wear count & Cost per Wear',
            description:
                'Catat jumlah pemakaian harian dan hitung Cost per Wear otomatis.',
          ),
        ],
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
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}