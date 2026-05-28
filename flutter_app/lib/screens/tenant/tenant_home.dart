import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../staff_screen.dart';
import 'pos_screen.dart';
import 'report_screen.dart';
import 'product_screen.dart';
import 'setting_screen.dart';

class TenantHome extends StatefulWidget {
  const TenantHome({super.key});

  @override
  State<TenantHome> createState() => _TenantHomeState();
}

class _TenantHomeState extends State<TenantHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PosScreen(),
    const ReportScreen(),
    const ProductScreen(),
    const SettingScreen(),
  ];

  final List<String> _titles = ['POS', 'Report', 'Produk', 'Setting'];

  Future<void> _logout() async {
    await ApiService.removeToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _goToStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StaffScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Staff button
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Staff',
            onPressed: _goToStaff,
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
            label: 'POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
