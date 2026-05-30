import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../utils/date_helper.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> sale;

  const ReceiptScreen({super.key, required this.sale});

  static const String _cmsBaseUrl = 'https://admin.nbyte-tech.com';

  Future<Uint8List> _generatePDFBytes(SharedPreferences prefs) async {
    final namaKedai = prefs.getString('nama_kedai') ?? 'Kedai Saya';
    final noSsm = prefs.getString('no_ssm') ?? '';
    final alamat = prefs.getString('alamat') ?? '';
    final noTel = prefs.getString('no_tel') ?? '';
    final emailKedai = prefs.getString('email_kedai') ?? '';
    final footer = prefs.getString('footer') ?? 'Terima Kasih Kerana Membeli!';

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

    final baseStyle = pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10);

    final boldStyle = pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 10);

    // Fixed divider using Container
    pw.Widget divider() => pw.Container(
      height: 0.5,
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(color: PdfColors.black),
    );

    final totalQty = items.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── Nama Kedai ──
            pw.Text(
              namaKedai,
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 14),
              textAlign: pw.TextAlign.center,
            ),

            // Alamat
            if (alamat.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  alamat,
                  style: baseStyle.copyWith(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),

            // SSM
            if (noSsm.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  'SSM: $noSsm',
                  style: baseStyle.copyWith(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),

            divider(),

            // ── Receipt Title ──
            pw.Center(
              child: pw.Text(
                'RECEIPT',
                style: boldStyle.copyWith(fontSize: 13, letterSpacing: 2),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                dateFormatter.format(createdAt),
                style: baseStyle.copyWith(fontSize: 9),
              ),
            ),

            divider(),

            // ── Items ──
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
                      child: pw.Text('$nama x$qty', style: baseStyle),
                    ),
                    pw.Text(
                      'RM ${subtotal.toStringAsFixed(2)}',
                      style: baseStyle,
                    ),
                  ],
                ),
              );
            }),

            divider(),

            // ── Total Qty ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Qty', style: baseStyle),
                pw.Text('$totalQty', style: baseStyle),
              ],
            ),

            pw.SizedBox(height: 3),

            // ── Total ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: boldStyle.copyWith(fontSize: 12)),
                pw.Text(
                  'RM ${total.toStringAsFixed(2)}',
                  style: boldStyle.copyWith(fontSize: 12),
                ),
              ],
            ),

            pw.SizedBox(height: 3),

            // ── Jenis Bayaran ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Jenis Bayaran', style: baseStyle),
                pw.Text(paymentLabel(paymentMethod), style: baseStyle),
              ],
            ),

            // ── Cash Details ──
            if (paymentMethod == 'cash' && cashReceived != null) ...[
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Diterima', style: baseStyle),
                  pw.Text(
                    'RM ${(cashReceived as num).toStringAsFixed(2)}',
                    style: baseStyle,
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Baki', style: boldStyle.copyWith(fontSize: 11)),
                  pw.Text(
                    'RM ${(changeAmount as num).toStringAsFixed(2)}',
                    style: boldStyle.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],

            divider(),

            // ── Footer ──
            pw.Center(
              child: pw.Text(
                footer,
                style: baseStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.SizedBox(height: 2),

            // No tel
            if (noTel.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'Tel: $noTel',
                  style: baseStyle.copyWith(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),

            // Email
            if (emailKedai.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  emailKedai,
                  style: baseStyle.copyWith(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),

            divider(),

            // ── Thank You ──
            pw.Center(
              child: pw.Text(
                'Thank You',
                style: boldStyle.copyWith(fontSize: 11),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    return await pdf.save();
  }

  Future<String> _uploadPDFToStorage(Uint8List bytes) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName =
          'receipt-${sale['id']}-${DateTime.now().millisecondsSinceEpoch}.pdf';

      await supabase.storage
          .from('receipts')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage
          .from('receipts')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  Future<void> _sharePDFViaWhatsApp(BuildContext context) async {
    final phoneController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String errorMsg = '';

          return Padding(
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
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFF25D366),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share PDF via WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Customer dapat PDF resit',
                          style: TextStyle(
                            color: AppColors.subtext,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                  'Format: 011-12345678',
                  style: TextStyle(color: AppColors.subtext, fontSize: 11),
                ),
                if (errorMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMsg,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
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

                            if (phone.startsWith('0')) {
                              phone = '6$phone';
                            }
                            if (!phone.startsWith('6')) {
                              phone = '60$phone';
                            }

                            setState(() {
                              isLoading = true;
                              errorMsg = '';
                            });

                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final bytes = await _generatePDFBytes(prefs);
                              final pdfUrl = await _uploadPDFToStorage(bytes);

                              final message =
                                  'Terima kasih kerana membeli! 🛍️\n\nMuat turun resit PDF anda:\n$pdfUrl';
                              final waUrl =
                                  'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              if (await canLaunchUrl(Uri.parse(waUrl))) {
                                await launchUrl(
                                  Uri.parse(waUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                                errorMsg = 'Error: ${e.toString()}';
                              });
                            }
                          },
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(isLoading ? 'Menghantar...' : 'Hantar PDF'),
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
          );
        },
      ),
    );
  }

  Future<void> _shareLinkViaWhatsApp(BuildContext context) async {
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
                    Icons.link,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hantar Link via WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Customer buka resit dalam browser',
                      style: TextStyle(color: AppColors.subtext, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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
              'Format: 011-12345678',
              style: TextStyle(color: AppColors.subtext, fontSize: 11),
            ),
            const SizedBox(height: 24),
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

                  if (phone.startsWith('0')) {
                    phone = '6$phone';
                  }
                  if (!phone.startsWith('6')) {
                    phone = '60$phone';
                  }

                  final receiptUrl = '$_cmsBaseUrl/receipt/${sale['id']}';
                  final message =
                      'Terima kasih kerana membeli! 🛍️\n\nSila klik untuk melihat resit:\n$receiptUrl';
                  final waUrl =
                      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

                  Navigator.pop(context);

                  if (await canLaunchUrl(Uri.parse(waUrl))) {
                    await launchUrl(
                      Uri.parse(waUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Hantar Link'),
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

                  _ReceiptRow(
                    label: 'Total',
                    value: 'RM ${total.toStringAsFixed(2)}',
                    bold: true,
                    valueColor: AppColors.primary,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                    label: 'Kaedah Bayaran',
                    value: _paymentLabel(paymentMethod),
                  ),

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

            // Share PDF via WhatsApp
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _sharePDFViaWhatsApp(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Share PDF via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Share Link via WhatsApp
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _shareLinkViaWhatsApp(context),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Hantar Link via WhatsApp'),
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

            // Sale Baru
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
