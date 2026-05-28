import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../tenant/pos_screen.dart';
import '../receipt_screen.dart';

class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  int _currentIndex = 0;

  final List<String> _titles = ['POS', 'Report Hari Ini'];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0
          ? const PosScreen()
          : const _CashierReportScreen(),
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
        ],
      ),
    );
  }
}

class _CashierReportScreen extends StatefulWidget {
  const _CashierReportScreen();

  @override
  State<_CashierReportScreen> createState() => _CashierReportScreenState();
}

class _CashierReportScreenState extends State<_CashierReportScreen> {
  List<dynamic> _sales = [];
  bool _loading = true;

  final _timeFormatter = DateFormat('hh:mm a');
  final _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      setState(() => _loading = true);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data = await ApiService.getSalesByDate(today);
      setState(() => _sales = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _totalRevenue =>
      _sales.fold(0, (sum, sale) => sum + (sale['total'] as num).toDouble());

  String _paymentLabel(String method) {
    switch (method) {
      case 'qr_bank':
        return 'QR Bank';
      case 'tng':
        return 'TnG';
      default:
        return 'Tunai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.card,
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _dateFormatter.format(DateTime.now()),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadReport,
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.subtext,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Summary cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Transaksi',
                  value: '${_sales.length}',
                  icon: Icons.receipt_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Pendapatan',
                  value: 'RM ${_totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // Sales list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tiada transaksi hari ini',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      final createdAt = DateTime.parse(sale['created_at']);
                      final items = sale['sale_items'] as List;
                      final total = (sale['total'] as num).toDouble();
                      final method = sale['payment_method'] ?? 'cash';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptScreen(sale: sale),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              // Time + method
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _timeFormatter.format(createdAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: method == 'cash'
                                          ? AppColors.successLight
                                          : AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _paymentLabel(method),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: method == 'cash'
                                            ? AppColors.success
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // Items
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      items.take(2).map((item) {
                                        final nama = item['products'] != null
                                            ? item['products']['nama']
                                            : item['nama'] ?? '-';
                                        return Text(
                                          '$nama x${item['quantity']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.text,
                                          ),
                                        );
                                      }).toList()..addAll(
                                        items.length > 2
                                            ? [
                                                Text(
                                                  '+${items.length - 2} lagi',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.subtext,
                                                  ),
                                                ),
                                              ]
                                            : [],
                                      ),
                                ),
                              ),

                              // Total + arrow
                              Row(
                                children: [
                                  Text(
                                    'RM ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.subtext,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
