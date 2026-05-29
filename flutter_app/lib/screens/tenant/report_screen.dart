import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/date_helper.dart';
import '../receipt_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<dynamic> _sales = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  bool _dayClosed = false;

  final _dateFormatter = DateFormat('dd MMM yyyy');
  final _timeFormatter = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.getSalesByDate(
        DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      setState(() => _sales = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dayClosed = false;
      });
      _loadReport();
    }
  }

  double get _totalRevenue =>
      _sales.fold(0, (sum, sale) => sum + (sale['total'] as num).toDouble());

  int get _totalQty => _sales.fold(
    0,
    (sum, sale) =>
        sum +
        (sale['sale_items'] as List).fold(
          0,
          (s, item) => s + (item['quantity'] as int),
        ),
  );

  // Generate EOD PDF
  Future<Uint8List> _generateEODPDF() async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());

    final baseStyle = pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10);

    final boldStyle = pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 10);

    pw.Widget divider() => pw.Container(
      height: 0.5,
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(color: PdfColors.black),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Text(
                'LAPORAN JUALAN HARIAN',
                style: boldStyle.copyWith(fontSize: 16),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'End of Day Report',
                style: baseStyle.copyWith(fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Tarikh: $dateStr   Dijana: $timeStr',
                style: baseStyle.copyWith(fontSize: 9),
              ),
            ),

            divider(),

            // Summary
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Jumlah Transaksi',
                          style: baseStyle.copyWith(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          '${_sales.length}',
                          style: boldStyle.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Jumlah Item',
                          style: baseStyle.copyWith(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          '$_totalQty',
                          style: boldStyle.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Jumlah Pendapatan',
                          style: baseStyle.copyWith(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          'RM ${_totalRevenue.toStringAsFixed(2)}',
                          style: boldStyle.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            divider(),

            // Table header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              color: PdfColors.grey200,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Masa',
                      style: boldStyle.copyWith(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      'Item',
                      style: boldStyle.copyWith(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Kaedah',
                      style: boldStyle.copyWith(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Total',
                      style: boldStyle.copyWith(fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Table rows
            ..._sales.map((sale) {
              final createdAt = parseDateTime(sale['created_at']);
              final items = sale['sale_items'] as List;
              final total = (sale['total'] as num).toDouble();
              final method = sale['payment_method'] ?? 'cash';

              String methodLabel(String m) {
                switch (m) {
                  case 'qr_bank':
                    return 'QR Bank';
                  case 'tng':
                    return 'TnG';
                  default:
                    return 'Tunai';
                }
              }

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _timeFormatter.format(createdAt),
                        style: baseStyle.copyWith(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: items.map((item) {
                          final nama = item['products'] != null
                              ? item['products']['nama']
                              : item['nama'] ?? '-';
                          return pw.Text(
                            '$nama x${item['quantity']}',
                            style: baseStyle.copyWith(fontSize: 9),
                          );
                        }).toList(),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        methodLabel(method),
                        style: baseStyle.copyWith(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'RM ${total.toStringAsFixed(2)}',
                        style: boldStyle.copyWith(fontSize: 9),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 6),
            divider(),

            // Total row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'JUMLAH KESELURUHAN',
                    style: boldStyle.copyWith(fontSize: 11),
                  ),
                  pw.Text(
                    'RM ${_totalRevenue.toStringAsFixed(2)}',
                    style: boldStyle.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),

            divider(),
            pw.SizedBox(height: 8),

            pw.Center(
              child: pw.Text(
                'Laporan ini dijana secara automatik oleh POS System',
                style: baseStyle.copyWith(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return await pdf.save();
  }

  // Upload PDF ke Supabase Storage
  Future<String> _uploadReportToStorage(Uint8List bytes) async {
    final supabase = Supabase.instance.client;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final fileName =
        'eod-report-$dateStr-${DateTime.now().millisecondsSinceEpoch}.pdf';

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

    return supabase.storage.from('receipts').getPublicUrl(fileName);
  }

  // EOD — generate PDF dan hantar ke WhatsApp
  Future<void> _closeDay() async {
    final isToday =
        DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (!isToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EOD hanya untuk hari ini'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End of Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan hari ini:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Transaksi: ${_sales.length}'),
            Text('Item: $_totalQty'),
            Text('Pendapatan: RM ${_totalRevenue.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text(
              'Laporan EOD akan dihantar ke WhatsApp selepas tutup hari.',
              style: TextStyle(color: AppColors.subtext, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup Hari'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Masuk no phone bos
    if (!mounted) return;
    final phoneController = TextEditingController();
    bool isUploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.summarize_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hantar Laporan EOD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'PDF report dihantar ke WhatsApp bos',
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
                  labelText: 'No Telefon Bos',
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
                  onPressed: isUploading
                      ? null
                      : () async {
                          var phone = phoneController.text
                              .trim()
                              .replaceAll('-', '')
                              .replaceAll(' ', '');

                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sila masukkan no telefon bos'),
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

                          setState(() => isUploading = true);

                          try {
                            // Generate PDF
                            final bytes = await _generateEODPDF();

                            // Upload
                            final pdfUrl = await _uploadReportToStorage(bytes);

                            final dateStr = _dateFormatter.format(
                              _selectedDate,
                            );
                            final message =
                                'Laporan EOD - $dateStr 📊\n\nTransaksi: ${_sales.length}\nItem: $_totalQty\nPendapatan: RM ${_totalRevenue.toStringAsFixed(2)}\n\nMuat turun laporan penuh:\n$pdfUrl';

                            final waUrl =
                                'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            setState(() => _dayClosed = true);

                            if (await canLaunchUrl(Uri.parse(waUrl))) {
                              await launchUrl(
                                Uri.parse(waUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Laporan EOD dihantar!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(isUploading ? 'Menghantar...' : 'Hantar Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
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
      ),
    );
  }

  Future<void> _generatePDF() async {
    final bytes = await _generateEODPDF();
    // Share locally
    final supabase = Supabase.instance.client;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final fileName =
        'eod-report-$dateStr-${DateTime.now().millisecondsSinceEpoch}.pdf';

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
  }

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
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.card,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dateFormatter.format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.subtext,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sales.isEmpty ? null : _generatePDF,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _sales.isEmpty
                        ? AppColors.background
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _sales.isEmpty
                          ? AppColors.border
                          : AppColors.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 16,
                        color: _sales.isEmpty
                            ? AppColors.subtext
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _sales.isEmpty
                              ? AppColors.subtext
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Summary cards
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.background,
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
                        'Tiada transaksi',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormatter.format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.subtext,
                          fontSize: 13,
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
                      final createdAt = parseDateTime(sale['created_at']);
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

        // EOD Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: AppColors.card,
          child: _dayClosed
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hari telah ditutup — Laporan dihantar',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _closeDay,
                    icon: const Icon(Icons.lock_clock, size: 18),
                    label: const Text('End of Day'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
