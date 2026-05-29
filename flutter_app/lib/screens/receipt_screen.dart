import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../utils/date_helper.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> sale;

  const ReceiptScreen({super.key, required this.sale});

  static const String _cmsBaseUrl = 'https://saas-pos-system-tau.vercel.app';

  Future<void> _sharePDF(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final namaKedai = prefs.getString('nama_kedai') ?? 'Kedai Saya';
    final noSsm = prefs.getString('no_ssm') ?? '';
    final alamat = prefs.getString('alamat') ?? '';
    final noTel = prefs.getString('no_tel') ?? '';
    final emailKedai = prefs.getString('email_kedai') ?? '';
    final footer =
        prefs.getString('footer') ?? 'Your transaction has been completed';

    final pdf = pw.Document();
    final items = sale['sale_items'] as List;
    final createdAt = parseDateTime(sale['created_at']);
    final dateFormatter = DateFormat('dd/MM/yyyy hh:mm a');
    final paymentMethod = sale['payment_method'] ?? 'cash';
    final cashReceived = sale['cash_received'];
    final changeAmount = sale['change_amount'];
    final total = (sale['total'] as num).toDouble();

    String paymentLabel(String method) {
      switch (method) {
        case 'qr_bank':
          return 'QR Bank';
        case 'tng':
          return 'Touch n Go';
        default:
          return 'Tunai';
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              namaKedai,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            if (noSsm.isNotEmpty)
              pw.Text(
                'SSM: $noSsm',
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            if (alamat.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  alamat,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              '--------------------------------',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'RECEIPT',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.Text(
              dateFormatter.format(createdAt),
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '--------------------------------',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            ...items.map((item) {
              final nama = item['products'] != null
                  ? item['products']['nama']
                  : item['nama'] ?? '-';
              final qty = item['quantity'];
              final harga = (item['harga'] as num).toDouble();
              final subtotal = qty * harga;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '$nama x$qty',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      'RM ${subtotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 4),
            pw.Text(
              '--------------------------------',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'RM ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bayaran', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  paymentLabel(paymentMethod),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            if (paymentMethod == 'cash' && cashReceived != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Diterima', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    'RM ${(cashReceived as num).toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            if (paymentMethod == 'cash' && changeAmount != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Baki',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    'RM ${(changeAmount as num).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            pw.SizedBox(height: 8),
            pw.Text(
              '-----------------------------------------',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              footer,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '--------------------------------',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 6),
            if (noTel.isNotEmpty)
              pw.Text(
                'Tel: $noTel',
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            if (emailKedai.isNotEmpty)
              pw.Text(
                emailKedai,
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              '--------------------------------',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Thank You',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              textAlign: pw.TextAlign.center,
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

  Future<void> _sendWhatsApp(BuildContext context) async {
    final phoneController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_outlined,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hantar Resit via WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Customer boleh tengok resit online',
                      style: TextStyle(color: AppColors.subtext, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Phone field
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'No Telefon Customer',
                hintText: '011-12345678',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Format: 011-12345678 atau 601112345678',
              style: TextStyle(color: AppColors.subtext, fontSize: 11),
            ),
            const SizedBox(height: 24),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  var phone = phoneController.text
                      .trim()
                      .replaceAll('-', '')
                      .replaceAll(' ', '');

                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sila masukkan no telefon'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  // Format phone number
                  if (phone.startsWith('0')) {
                    phone = '6$phone';
                  }
                  if (!phone.startsWith('6')) {
                    phone = '60$phone';
                  }

                  // Receipt web link
                  final receiptUrl = '$_cmsBaseUrl/receipt/${sale['id']}';

                  // WhatsApp message
                  final message =
                      'Terima kasih kerana membeli! 🛍️\n\nSila klik link untuk melihat resit anda:\n$receiptUrl';

                  final waUrl =
                      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

                  Navigator.pop(context);

                  if (await canLaunchUrl(Uri.parse(waUrl))) {
                    await launchUrl(
                      Uri.parse(waUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('WhatsApp tidak dijumpai'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Buka WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'qr_bank':
        return 'QR Bank';
      case 'tng':
        return 'Touch n Go';
      default:
        return 'Tunai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = sale['sale_items'] as List;
    final total = (sale['total'] as num).toDouble();
    final createdAt = parseDateTime(sale['created_at']);
    final formatter = DateFormat('dd/MM/yyyy hh:mm a');
    final paymentMethod = sale['payment_method'] ?? 'cash';
    final cashReceived = sale['cash_received'];
    final changeAmount = sale['change_amount'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resit'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _sharePDF(context),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success card
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pembayaran Berjaya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(createdAt),
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Receipt detail card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Dibeli',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    final nama = item['products'] != null
                        ? item['products']['nama']
                        : item['nama'] ?? '-';
                    final qty = item['quantity'];
                    final harga = (item['harga'] as num).toDouble();
                    final subtotal = qty * harga;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$nama x$qty',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'RM ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),

                  // Total
                  _ReceiptRow(
                    label: 'Total',
                    value: 'RM ${total.toStringAsFixed(2)}',
                    bold: true,
                    valueColor: AppColors.primary,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 8),

                  // Payment method
                  _ReceiptRow(
                    label: 'Kaedah Bayaran',
                    value: _paymentLabel(paymentMethod),
                  ),

                  // Cash details
                  if (paymentMethod == 'cash' && cashReceived != null) ...[
                    const SizedBox(height: 4),
                    _ReceiptRow(
                      label: 'Diterima',
                      value: 'RM ${(cashReceived as num).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Baki',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'RM ${(changeAmount as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share PDF button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _sharePDF(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Share PDF Resit'),
              ),
            ),
            const SizedBox(height: 12),

            // WhatsApp button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _sendWhatsApp(context),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Hantar via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // New sale button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Sale Baru'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final double fontSize;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.text : AppColors.subtext,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.text,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
