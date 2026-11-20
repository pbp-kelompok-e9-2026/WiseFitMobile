import 'package:flutter/material.dart';

/// Halaman Modul 4: Repair & Clothing Lifecycle.
///
/// Checkpoint 1: kerangka halaman. Data dari endpoint
/// `/api/v1/lifecycle/records/` dan `/api/v1/lifecycle/guides/`
/// akan disambungkan di tahap berikutnya.
class LifecyclePage extends StatelessWidget {
  const LifecyclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair & Lifecycle'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rawat pakaianmu lebih lama',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Catat kondisi pakaian dan dapatkan rekomendasi untuk '
            'repair, reuse, atau recycle supaya pakaian tidak langsung dibuang.',
          ),
          const SizedBox(height: 16),
          const _FeatureCard(
            icon: Icons.checkroom,
            title: 'Catatan kondisi pakaian',
            description: 'Catat kondisi pakaian dan lihat riwayatnya.',
          ),
          const _FeatureCard(
            icon: Icons.recycling,
            title: 'Rekomendasi repair / reuse / recycle',
            description: 'Rekomendasi otomatis berdasarkan kondisi pakaian.',
          ),
          const _FeatureCard(
            icon: Icons.build,
            title: 'Repair guide',
            description: 'Panduan langkah demi langkah untuk tiap rekomendasi.',
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
