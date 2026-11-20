import 'package:flutter/material.dart';
import 'package:project_kelompok_kamu/screens/dashboard_page.dart';
import 'package:project_kelompok_kamu/screens/wardrobe_page.dart';
import 'package:project_kelompok_kamu/screens/lifecycle_page.dart';
import 'package:project_kelompok_kamu/screens/garment_form_screen.dart';
import 'package:project_kelompok_kamu/screens/worth_to_buy_screen.dart';
import 'package:project_kelompok_kamu/screens/analysis_detail_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;

  // Daftar halaman utama (Modul 1, Dashboard, Modul 4)
  final List<Widget> _pages = [
    const DashboardPage(),
    const WardrobePage(),
    const LifecyclePage(),
  ];

  // Fitur tambahan yang ditaruh di Drawer biar gak penuhin layar
  void _onDrawerItemTapped(String routeName, BuildContext context) {
    Navigator.pop(context); // Tutup drawer dulu

    Widget page;
    switch (routeName) {
      case 'garment_form':
        page = const GarmentFormScreen();
        break;
      case 'worth_to_buy':
        page = const WorthToBuyScreen();
        break;
      case 'analysis_detail':
        page = const AnalysisDetailScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EcoWardrobe', // Ganti dengan nama aplikasi kelompokmu
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1C1917), // Warna tema gelap
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Drawer buat fitur-fitur sekunder
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1C1917)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Menu Tambahan',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Tambah Pakaian'),
              onTap: () => _onDrawerItemTapped('garment_form', context),
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Worth to Buy'),
              onTap: () => _onDrawerItemTapped('worth_to_buy', context),
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Analysis Detail'),
              onTap: () => _onDrawerItemTapped('analysis_detail', context),
            ),
          ],
        ),
      ),
      // Body berubah sesuai tab yang dipilih
      body: _pages[_selectedIndex],
      
      // Navigasi bawah
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1C1917),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recycling),
            label: 'Lifecycle',
          ),
        ],
      ),
    );
  }
}