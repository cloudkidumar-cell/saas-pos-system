import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> sale;

  const ReceiptScreen({super.key, required this.sale});

  Future<void> _sharePDF(BuildContext context) async {
    final pdf = pw.Document();

    final items = sale['sale_items'] as List;
    final createdAt = DateTime.parse(sale['created_at']);
    final formatter = DateFormat('dd/MM/yyyy hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'RECEIPT',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              formatter.format(createdAt),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Items
            ...items.map((item) {
              final product = item['products'];
              final qty = item['quantity'];
              final harga = (item['harga'] as num).toDouble();
              final subtotal = qty * harga;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${product['nama']} x$qty',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                    pw.Text(
                      'RM ${subtotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }),

            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  'RM ${(sale['total'] as num).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Terima Kasih!',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt-${sale['id']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = sale['sale_items'] as List;
    final total = (sale['total'] as num).toDouble();
    final createdAt = DateTime.parse(sale['created_at']);
    final formatter = DateFormat('dd/MM/yyyy hh:mm a');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'Pembayaran Berjaya',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Items
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ...items.map((item) {
                    final product = item['products'];
                    final qty = item['quantity'];
                    final harga = (item['harga'] as num).toDouble();
                    final subtotal = qty * harga;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${product['nama']} x$qty',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'RM ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'RM ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _sharePDF(context),
                icon: const Icon(Icons.share),
                label: const Text('Share PDF Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  // Balik ke home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Sale Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
