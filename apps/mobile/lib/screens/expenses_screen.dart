import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final expenses = provider.expenses;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadExpenses(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expenses', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: Text('${expenses.length} total', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.loading && expenses.isEmpty)
                const SliverFillRemaining(child: LoadingOverlay(message: 'Loading expenses...'))
              else if (provider.error != null && expenses.isEmpty)
                SliverFillRemaining(child: ErrorView(message: provider.error!, onRetry: () => provider.loadExpenses()))
              else if (expenses.isEmpty)
                const SliverFillRemaining(child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses yet', subtitle: 'Upload a receipt to get started'))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final e = expenses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
                                      child: const Icon(Icons.receipt_outlined, size: 20, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text('${e.category?.name ?? '-'} \u2022 ${_formatDate(e.expenseDate)}',
                                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppTheme.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    AmountText(amount: e.amount),
                                  ],
                                ),
                                if (e.tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: e.tags.map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                                      child: Text(t, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                    )).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: expenses.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }
}
