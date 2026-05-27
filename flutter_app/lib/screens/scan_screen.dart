import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanned = false;
  bool _loading = false;

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_scanned || _loading) return;

    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() {
      _scanned = true;
      _loading = true;
    });

    try {
      final data = await ApiService.getProductByBarcode(barcode);
      final product = Product.fromJson(data);

      if (mounted) {
        // Add ke cart
        context.read<CartProvider>().addProduct(product);

        // Show result
        showModalBottomSheet(
          context: context,
          builder: (_) => _ProductFound(
            product: product,
            onAddMore: () {
              Navigator.pop(context);
              setState(() => _scanned = false);
            },
            onDone: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk tidak dijumpai'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _scanned = false);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(onDetect: _onBarcodeDetected),

          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Loading
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Instruction
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFound extends StatelessWidget {
  final Product product;
  final VoidCallback onAddMore;
  final VoidCallback onDone;

  const _ProductFound({
    required this.product,
    required this.onAddMore,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text(
            product.nama,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'RM ${product.harga.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.green[700], fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Stok: ${product.stok}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddMore,
                  child: const Text('Scan Lagi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
