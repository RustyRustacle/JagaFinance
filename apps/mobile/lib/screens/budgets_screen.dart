import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/receipt.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/common_widgets.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadBudgets();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardProvider>().loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dash, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Anggaran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      _filterChip(Icons.add_rounded, 'Buat Anggaran', () => _showCreateSheet()),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Pantau anggaran per kategori pengeluaran',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: dash.isLoading && dash.budgets.isEmpty
                      ? const LoadingOverlay(message: 'Memuat anggaran...')
                      : dash.budgets.isEmpty
                          ? const EmptyState(icon: Icons.pie_chart_rounded, title: 'Belum ada anggaran', subtitle: 'Buat anggaran untuk mulai memantau pengeluaran')
                          : RefreshIndicator(
                              onRefresh: _onRefresh,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: dash.budgets.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return _buildSummary(dash);
                                  }
                                  final budget = dash.budgets[index - 1];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _budgetCard(budget),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(DashboardProvider dash) {
    final totalBudget = dash.budgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = dash.dashboard.totalExpenses;
    final pct = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Anggaran', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Anggaran: Rp ${NumberFormat.decimalPattern('id').format(totalBudget.round())}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Terpakai: Rp ${NumberFormat.decimalPattern('id').format(totalSpent.round())}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(pct >= 1 ? AppTheme.danger : pct >= 0.8 ? AppTheme.warning : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard(Budget budget) {
    final catName = budget.category?.name ?? 'Kategori';
    final spent = context.read<DashboardProvider>().dashboard.expensesByCategory
        .where((c) => c.category == catName)
        .fold<double>(0, (s, c) => s + c.amount);
    final pct = budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
    final exceeded = pct >= 1.0;
    final warning = pct >= (budget.alertThreshold / 100) && !exceeded;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exceeded ? AppTheme.danger.withValues(alpha: 0.3) : warning ? AppTheme.warning.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: exceeded ? AppTheme.danger : warning ? AppTheme.warning : AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(catName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: exceeded ? AppTheme.danger.withValues(alpha: 0.1) : warning ? AppTheme.warning.withValues(alpha: 0.1) : AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  budget.period == 'MONTHLY' ? 'Bulanan' : budget.period == 'QUARTERLY' ? 'Kuartalan' : 'Tahunan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: exceeded ? AppTheme.danger : warning ? AppTheme.warning : AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                exceeded ? AppTheme.danger : warning ? AppTheme.warning : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AmountText(amount: spent, fontSize: 13, color: exceeded ? AppTheme.danger : AppTheme.textPrimary),
              AmountText(amount: budget.amount, fontSize: 13, color: AppTheme.textSecondary),
            ],
          ),
          if (exceeded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.danger),
                    SizedBox(width: 4),
                    Text('Anggaran terlampaui!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                  ],
                ),
              ),
            )
          else if (warning)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.warning),
                    const SizedBox(width: 4),
                    Text('Mendekati batas (${budget.alertThreshold.round()}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.warning)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => const _CreateBudgetSheet(),
    );
  }
}

class _CreateBudgetSheet extends StatefulWidget {
  const _CreateBudgetSheet();

  @override
  State<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends State<_CreateBudgetSheet> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  String _period = 'MONTHLY';
  final double _alertThreshold = 80;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategoryId == null || _amountController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final dash = context.read<DashboardProvider>();
      final now = DateTime.now();
      final endDate = _period == 'MONTHLY'
          ? DateTime(now.year, now.month + 1, 0)
          : _period == 'QUARTERLY'
              ? DateTime(now.year, now.month + 3, 0)
              : DateTime(now.year + 1, 0, 0);
      final ok = await dash.createBudget(
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text),
        period: _period,
        startDate: DateTime(now.year, now.month, 1).toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
        alertThreshold: _alertThreshold,
      );
      if (mounted) {
        if (ok) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat anggaran')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat anggaran')),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.read<DashboardProvider>();
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Buat Anggaran Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const Text('Kategori', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              hintText: 'Pilih kategori',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: dash.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 16),
          const Text('Jumlah Anggaran', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: 'Rp ', prefixStyle: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          const Text('Periode', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: ['MONTHLY', 'QUARTERLY', 'YEARLY'].map((p) {
              final labels = {'MONTHLY': 'Bulanan', 'QUARTERLY': 'Kuartalan', 'YEARLY': 'Tahunan'};
              final selected = _period == p;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: p == 'YEARLY' ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _period = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text(
                        labels[p]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Anggaran'),
            ),
          ),
        ],
      ),
    );
  }
}
