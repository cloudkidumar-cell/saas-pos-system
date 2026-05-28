import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _namaKedaiController = TextEditingController();
  final _noSsmController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noTelController = TextEditingController();
  final _emailController = TextEditingController();
  final _footerController = TextEditingController(
    text: 'Your transaction has been completed',
  );
  String? _qrBankPath;
  String? _tngPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaKedaiController.text = prefs.getString('nama_kedai') ?? '';
      _noSsmController.text = prefs.getString('no_ssm') ?? '';
      _alamatController.text = prefs.getString('alamat') ?? '';
      _noTelController.text = prefs.getString('no_tel') ?? '';
      _emailController.text = prefs.getString('email_kedai') ?? '';
      _footerController.text =
          prefs.getString('footer') ?? 'Your transaction has been completed';
      _qrBankPath = prefs.getString('qr_bank_path');
      _tngPath = prefs.getString('tng_path');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama_kedai', _namaKedaiController.text.trim());
    await prefs.setString('no_ssm', _noSsmController.text.trim());
    await prefs.setString('alamat', _alamatController.text.trim());
    await prefs.setString('no_tel', _noTelController.text.trim());
    await prefs.setString('email_kedai', _emailController.text.trim());
    await prefs.setString('footer', _footerController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setting berjaya disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _pickQRImage(String type) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = type == 'bank' ? 'qr_bank_path' : 'tng_path';
      await prefs.setString(key, picked.path);
      setState(() {
        if (type == 'bank') {
          _qrBankPath = picked.path;
        } else {
          _tngPath = picked.path;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR berjaya diupload'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _removeQR(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'bank' ? 'qr_bank_path' : 'tng_path';
    await prefs.remove(key);
    setState(() {
      if (type == 'bank') {
        _qrBankPath = null;
      } else {
        _tngPath = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview template
          _SectionTitle(title: 'Preview Template Resit'),
          const SizedBox(height: 8),
          _ReceiptPreview(
            namaKedai: _namaKedaiController.text,
            noSsm: _noSsmController.text,
            alamat: _alamatController.text,
            noTel: _noTelController.text,
            email: _emailController.text,
            footer: _footerController.text,
          ),
          const SizedBox(height: 24),

          // Maklumat kedai
          _SectionTitle(title: 'Maklumat Kedai'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SettingField(
                  controller: _namaKedaiController,
                  label: 'Nama Kedai',
                  hint: 'Contoh: Kedai Makan Ali',
                  icon: Icons.store_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _SettingField(
                  controller: _noSsmController,
                  label: 'No. Pendaftaran SSM',
                  hint: 'Contoh: 002345678-A',
                  icon: Icons.badge_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _SettingField(
                  controller: _alamatController,
                  label: 'Alamat Kedai',
                  hint: 'Contoh: No 12, Jalan Maju...',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _SettingField(
                  controller: _noTelController,
                  label: 'No Telefon',
                  hint: 'Contoh: 012-3456789',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _SettingField(
                  controller: _emailController,
                  label: 'Email Kedai',
                  hint: 'Contoh: kedai@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _SettingField(
                  controller: _footerController,
                  label: 'Mesej Footer',
                  hint: 'Your transaction has been completed',
                  icon: Icons.message_outlined,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Payment
          _SectionTitle(title: 'QR Code Pembayaran'),
          const SizedBox(height: 12),
          _QRUploadCard(
            title: 'QR Bank',
            subtitle: 'Maybank, CIMB, RHB, dan lain-lain',
            icon: Icons.account_balance_outlined,
            imagePath: _qrBankPath,
            onUpload: () => _pickQRImage('bank'),
            onRemove: () => _removeQR('bank'),
          ),
          const SizedBox(height: 12),
          _QRUploadCard(
            title: 'Touch n Go',
            subtitle: 'TnG eWallet QR',
            icon: Icons.touch_app_outlined,
            imagePath: _tngPath,
            onUpload: () => _pickQRImage('tng'),
            onRemove: () => _removeQR('tng'),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Setting'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Section title widget
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    );
  }
}

// Setting field widget
class _SettingField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final Function(String) onChanged;

  const _SettingField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}

// Receipt preview widget
class _ReceiptPreview extends StatelessWidget {
  final String namaKedai;
  final String noSsm;
  final String alamat;
  final String noTel;
  final String email;
  final String footer;

  const _ReceiptPreview({
    required this.namaKedai,
    required this.noSsm,
    required this.alamat,
    required this.noTel,
    required this.email,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Nama kedai
          Text(
            namaKedai.isEmpty ? 'Nama Kedai' : namaKedai,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
          ),

          // No SSM
          if (noSsm.isNotEmpty)
            Text(
              'SSM: $noSsm',
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),

          // Alamat
          if (alamat.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                alamat,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 8),
          const _Divider(),
          const SizedBox(height: 6),

          const Text(
            'RECEIPT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 6),
          const _Divider(),
          const SizedBox(height: 8),

          // Sample items
          _ReceiptRow(left: 'Milo Tin x2', right: 'RM 11.00'),
          _ReceiptRow(left: 'Roti Gardenia x1', right: 'RM 2.50'),
          const SizedBox(height: 6),
          const _Divider(),
          const SizedBox(height: 6),

          _ReceiptRow(left: 'TOTAL', right: 'RM 13.50', bold: true),
          _ReceiptRow(left: 'Tunai', right: 'RM 20.00'),
          _ReceiptRow(left: 'Baki', right: 'RM 6.50', bold: true),

          const SizedBox(height: 8),
          const _Divider(),
          const SizedBox(height: 8),

          // Footer message
          Text(
            footer.isEmpty ? 'Your transaction has been completed' : footer,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),
          const _Divider(),
          const SizedBox(height: 8),

          // No tel + email
          if (noTel.isNotEmpty)
            Text(
              'Tel: $noTel',
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          if (email.isNotEmpty)
            Text(
              email,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        30,
        (_) => const Expanded(
          child: Text(
            '-',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String left;
  final String right;
  final bool bold;

  const _ReceiptRow({
    required this.left,
    required this.right,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// QR Upload card
class _QRUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _QRUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imagePath,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (imagePath != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath!),
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload, size: 14),
                    label: const Text('Tukar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Padam'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload, size: 16),
                label: Text('Upload QR $title'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
