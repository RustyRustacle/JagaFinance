import 'dart:io';
import 'dart:async';
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
  bool _isOcrProcessing = false; 
  
  // Kontroler Form Input
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategoryId; 
  
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      provider.clearError();
      provider.loadCategories(); 
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _merchantController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 2048, maxHeight: 2048);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _showExtraction = true; 
        _isOcrProcessing = true; 
        
        _merchantController.clear();
        _dateController.clear();
        _amountController.clear();
        _selectedCategoryId = null; 
      });
      
      if (!mounted) return;
      final provider = context.read<DashboardProvider>();
      provider.clearError();
      
      final success = await provider.uploadReceipt(image.path);
      if (success && mounted) {
        _startPollingOCR(); 
      } else {
        setState(() => _isOcrProcessing = false); 
      }
    }
  }

  void _startPollingOCR() {
    _pollingTimer?.cancel();
    int secondsElapsed = 0;
    final provider = context.read<DashboardProvider>();
    final targetReceiptId = provider.lastUploadedReceiptId;

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      secondsElapsed += 2;
      if (!mounted || secondsElapsed >= 30) {
        timer.cancel();
        if (mounted) setState(() => _isOcrProcessing = false);
        return;
      }

      await provider.loadReceipts(refresh: true);
      provider.clearError();

      final matching = provider.receipts.where((r) => r.id == targetReceiptId).toList();
      if (matching.isEmpty) return;

      final receipt = matching.first;
      final statusStr = receipt.status.toUpperCase();

      if (statusStr == 'COMPLETED') {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _isOcrProcessing = false;
          final data = receipt.receiptData;
          if (data != null) {
            _merchantController.text = data.merchantName ?? '';
            final rawDate = data.transactionDate?.toIso8601String() ?? '';
            _dateController.text = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
            _amountController.text = data.totalAmount.toStringAsFixed(0);
          }
        });
      } else if (statusStr == 'FAILED' || statusStr == 'REJECTED') {
        timer.cancel();
        if (mounted) setState(() => _isOcrProcessing = false);
      }
    });
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Pilih Sumber Struk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
      appBar: AppBar(
        title: const Text('Pindai Struk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unggah struk untuk ekstraksi otomatis atau lakukan pengisian data secara mandiri',
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
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
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
                            const Text('PNG, JPG hingga 10MB',
                                style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(Icons.camera_alt_rounded, 'Kamera', () => _showPickerSheet()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(Icons.photo_library_rounded, 'Galeri', () => _showPickerSheet()),
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
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warning)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Menyimpan ke cloud storage (${(dash.uploadProgress * 100).toInt()}%)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C2D12))),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_showExtraction && _selectedImage != null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detail Transaksi Struk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    if (_isOcrProcessing)
                      const Row(
                        children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary)),
                          SizedBox(width: 6),
                          Text('Memproses AI...', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                        ],
                      )
                    else
                      const Text('Mode Edit Manual', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                  ],
                ),
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
                      _editableRow(Icons.store_outlined, 'Merchant', _merchantController, isOcrLoading: _isOcrProcessing),
                      const SizedBox(height: 16),
                      _editableRow(Icons.calendar_today_outlined, 'Tanggal', _dateController, isOcrLoading: _isOcrProcessing, hintText: 'YYYY-MM-DD'),
                      const SizedBox(height: 16),
                      _editableRow(Icons.attach_money_outlined, 'Jumlah (Rp)', _amountController, isOcrLoading: _isOcrProcessing, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      
                      Consumer<DashboardProvider>(
                        builder: (context, dash, _) {
                          return Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
                                child: const Icon(Icons.category_outlined, size: 18, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(flex: 2, child: Text('Kategori', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategoryId,
                                      hint: const Text('Pilih kategori', style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                      items: dash.categories.map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      )).toList(),
                                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<DashboardProvider>(
                  builder: (context, dash, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: dash.isUploading
    ? null
    : () async {
        _pollingTimer?.cancel();
        final messenger = ScaffoldMessenger.of(context);
        final provider = context.read<DashboardProvider>();
        final title = _merchantController.text.trim();
        final amountStr = _amountController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
        final dateStr = _dateController.text.trim();

        if (title.isEmpty || amountStr.isEmpty || dateStr.isEmpty || _selectedCategoryId == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Lengkapi data merchant, tanggal, jumlah, dan kategori'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final amount = double.tryParse(amountStr);
        if (amount == null || amount <= 0) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Jumlah tidak valid'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final navigator = Navigator.of(context);
        final ok = await provider.createExpense(
          title: title,
          amount: amount,
          expenseDate: dateStr,
          receiptId: provider.lastUploadedReceiptId,
          categoryId: _selectedCategoryId, 
        );

        if (mounted) {
          if (ok) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Pengeluaran berhasil disimpan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );

            // ===================================================================
            // ===================================================================
            navigator.popUntil((route) => route.isFirst);

            // Pemicu otomatis agar data grafik di halaman Beranda langsung ter-refresh segar
            provider.loadExpenses(refresh: true);
            
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Gagal menyimpan pengeluaran'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: dash.isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                        label: Text(
                          dash.isUploading ? 'Mengunggah...' : 'Simpan Ke JagaFinance',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
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

  Widget _editableRow(IconData icon, String label, TextEditingController controller, {required bool isOcrLoading, String hintText = '', TextInputType keyboardType = TextInputType.text}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Expanded(
          flex: 5,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: isOcrLoading ? 'Mengekstrak otomatis...' : (hintText.isEmpty ? 'Isi manual di sini' : hintText),
              hintStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: isOcrLoading ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary)),
            ),
          ),
        ),
      ],
    );
  }
}