import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final List<CartItem> items;

  const PaymentScreen({super.key, required this.total, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = '';
  final _cashController = TextEditingController();
  double _cashReceived = 0;
  double _change = 0;
  String? _qrBankPath;
  String? _tngPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadQRImages();
  }

  Future<void> _loadQRImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _qrBankPath = prefs.getString('qr_bank_path');
      _tngPath = prefs.getString('tng_path');
    });
  }

  void _onCashChanged(String value) {
    final amount = double.tryParse(value) ?? 0;
    setState(() {
      _cashReceived = amount;
      _change = amount - widget.total;
    });
  }

  List<double> _quickAmounts() {
    final amounts = <double>{};
    amounts.add(widget.total);
    for (final base in [5, 10, 20, 50, 100]) {
      final rounded = (widget.total / base).ceil() * base.toDouble();
      amounts.add(rounded);
      if (amounts.length >= 5) break;
    }
    final sorted = amounts.toList()..sort();
    return sorted.take(5).toList();
  }

  Future<void> _confirmPayment() async {
    if (_selectedMethod == 'cash' && _cashReceived < widget.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah cash tidak mencukupi'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final items = widget.items
          .map(
            (item) => {
              'product_id': item.product.id.startsWith('manual')
                  ? null
                  : item.product.id,
              'quantity': item.quantity,
              'harga': item.product.harga,
              'nama': item.product.nama,
            },
          )
          .toList();

      final sale = await ApiService.createSale(
        items,
        paymentMethod: _selectedMethod,
        cashReceived: _selectedMethod == 'cash' ? _cashReceived : null,
        change: _selectedMethod == 'cash' ? _change : null,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Jumlah Bayaran',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment method title
            const Text(
              'Pilih Kaedah Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),

            // Payment options
            Row(
              children: [
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.payments_outlined,
                    label: 'Cash',
                    selected: _selectedMethod == 'cash',
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.qr_code,
                    label: 'QR Bank',
                    selected: _selectedMethod == 'qr_bank',
                    onTap: () => setState(() => _selectedMethod = 'qr_bank'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentOption(
                    icon: Icons.touch_app_outlined,
                    label: 'TnG',
                    selected: _selectedMethod == 'tng',
                    onTap: () => setState(() => _selectedMethod = 'tng'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CASH section
            if (_selectedMethod == 'cash') ...[
              const Text(
                'Jumlah Diterima',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cashController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: _onCashChanged,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  prefixText: 'RM  ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 12),

              // Quick amount buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickAmounts()
                      .map(
                        (amount) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              _cashController.text = amount.toStringAsFixed(2);
                              _onCashChanged(amount.toStringAsFixed(2));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('RM ${amount.toStringAsFixed(0)}'),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Baki display
              if (_cashReceived > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _change >= 0
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _change >= 0
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.danger.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _change >= 0 ? 'Baki' : 'Kurang',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _change >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      Text(
                        'RM ${_change.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _change >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // QR BANK section
            if (_selectedMethod == 'qr_bank')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (_qrBankPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_qrBankPath!),
                          width: 260,
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                      )
                    else ...[
                      Icon(Icons.qr_code, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        'QR Bank belum diupload',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pergi Setting → Upload QR Bank',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Tunjukkan QR ini kepada pembeli',
                      style: TextStyle(color: AppColors.subtext, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // TNG section
            if (_selectedMethod == 'tng')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (_tngPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_tngPath!),
                          width: 260,
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                      )
                    else ...[
                      Icon(
                        Icons.touch_app_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'QR TnG belum diupload',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pergi Setting → Upload QR TnG',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Tunjukkan QR ini kepada pembeli',
                      style: TextStyle(color: AppColors.subtext, fontSize: 13),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Confirm button
            if (_selectedMethod.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmPayment,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedMethod == 'cash'
                              ? 'Confirm Bayaran'
                              : 'Pembeli Dah Bayar',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.subtext,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.primary : AppColors.subtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
