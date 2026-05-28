import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../tenant/pos_screen.dart';

class CashierHome extends StatelessWidget {
  const CashierHome({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService.removeToken();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const PosScreen(),
    );
  }
}
