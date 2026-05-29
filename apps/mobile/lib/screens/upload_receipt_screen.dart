import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/dashboard_provider.dart';

class UploadReceiptScreen extends StatefulWidget {
  const UploadReceiptScreen({super.key});

  @override
  State<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends State<UploadReceiptScreen> {
  XFile? _selectedImage;
  bool _showExtraction = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 2048, maxHeight: 2048);
    if (image != null) {
      setState(() => _selectedImage = image);
      if (!mounted) return;
      final success = await context.read<DashboardProvider>().uploadReceipt(image.path);
      if (success && mounted) {
        setState(() => _showExtraction = true);
        context.read<DashboardProvider>().loadDashboard();
      }
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Pilih Sumber', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _sourceButton(Icons.camera_alt_rounded, 'Kamera', () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _sourceButton(Icons.photo_library_rounded, 'Galeri', () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Pindai Struk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Unggah struk dan kami akan mengekstrak detailnya secara otomatis',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showPickerSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.cloud_upload_outlined, size: 28, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text('Ketuk untuk unggah struk',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            const Text('PNG, JPG, PDF hingga 10MB',
                                style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(Icons.camera_alt_outlined, 'Kamera', () => _pickImage(ImageSource.camera)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(Icons.photo_library_outlined, 'Galeri', () => _pickImage(ImageSource.gallery)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<DashboardProvider>(
                builder: (context, dash, _) {
                  if (dash.isUploading) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA)),
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
                                  color: AppTheme.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.hourglass_top_rounded, size: 20, color: AppTheme.warning),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Mengunggah struk...',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7C2D12))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: dash.uploadProgress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (dash.errorMessage != null) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 20, color: AppTheme.danger),
                          const SizedBox(width: 12),
                          Expanded(child: Text(dash.errorMessage!, style: const TextStyle(fontSize: 13, color: AppTheme.danger))),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_showExtraction && _selectedImage != null) ...[
                const SizedBox(height: 20),
                const Text('Hasil Ekstraksi AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _extractionRow(Icons.store_outlined, 'Merchant', 'Menunggu OCR...'),
                      const Divider(height: 24),
                      _extractionRow(Icons.calendar_today_outlined, 'Tanggal', 'Diproses'),
                      const Divider(height: 24),
                      _extractionRow(Icons.attach_money_outlined, 'Jumlah', 'Dihitung'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Simpan Struk'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _extractionRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }
}
