import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/receipt.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/common_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategoryId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>()..loadExpenses(refresh: true)..loadCategories();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<DashboardProvider>().loadMoreExpenses();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardProvider>().loadExpenses(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pengeluaran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Row(
                    children: [
                      _filterChip(Icons.filter_list_rounded, 'Filter', () => _showFilterSheet()),
                      const SizedBox(width: 8),
                      _filterChip(Icons.add_rounded, 'Tambah', () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<DashboardProvider>(
              builder: (context, dash, _) {
                return Expanded(
                  child: dash.isLoading && dash.expenses.isEmpty
                      ? const LoadingOverlay(message: 'Memuat pengeluaran...')
                      : dash.expenses.isEmpty
                          ? const EmptyState(icon: Icons.receipt_long_rounded, title: 'Belum ada pengeluaran', subtitle: 'Mulai dengan mengunggah struk')
                          : RefreshIndicator(
                              onRefresh: _onRefresh,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: dash.expenses.length + (dash.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= dash.expenses.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _expenseCard(dash.expenses[index]),
                                  );
                                },
                              ),
                            ),
                );
              },
            ),
          ],
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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _expenseCard(Expense exp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _categoryColor(exp.category?.name ?? '').withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon(exp.category?.name ?? ''), size: 20, color: _categoryColor(exp.category?.name ?? '')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(exp.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ),
                    StatusBadge(status: exp.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(exp.category?.name ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMM yyyy', 'id').format(exp.expenseDate),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AmountText(amount: exp.amount, fontSize: 14),
        ],
      ),
    );
  }

  Color _categoryColor(String name) {
    const colors = [AppTheme.primary, AppTheme.success, AppTheme.warning, AppTheme.secondary, AppTheme.danger];
    return colors[name.hashCode % colors.length];
  }

  IconData _categoryIcon(String name) {
    const icons = {
      'Transportasi': Icons.directions_car_rounded,
      'Makanan': Icons.restaurant_rounded,
      'Kantor': Icons.inventory_2_rounded,
      'Utilitas': Icons.bolt_rounded,
      'Marketing': Icons.campaign_rounded,
      'Gaji': Icons.account_balance_wallet_rounded,
      'Sewa': Icons.home_rounded,
      'Perjalanan': Icons.flight_rounded,
    };
    return icons.entries.firstWhere((e) => name.contains(e.key), orElse: () => const MapEntry('', Icons.receipt_outlined)).value;
  }

  void _showFilterSheet() {
    final dash = context.read<DashboardProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Kategori', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterOption('Semua', _selectedCategoryId == null, () {
                  setState(() => _selectedCategoryId = null);
                  Navigator.pop(context);
                  dash.loadExpenses(refresh: true);
                }),
                ...dash.categories.map((c) => _filterOption(c.name, _selectedCategoryId == c.id, () {
                  setState(() => _selectedCategoryId = c.id);
                  Navigator.pop(context);
                  dash.loadExpenses(refresh: true);
                })),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Semua', 'DRAFT', 'CONFIRMED', 'RECONCILED'].map((s) {
                final selected = _selectedStatus == s || (_selectedStatus == null && s == 'Semua');
                return _filterOption(s == 'Semua' ? 'Semua' : s, selected, () {
                  setState(() => _selectedStatus = s == 'Semua' ? null : s);
                  Navigator.pop(context);
                  dash.loadExpenses(refresh: true);
                });
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
