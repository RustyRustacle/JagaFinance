import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final budgets = provider.budgets;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadBudgets(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budgets', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: Text('${budgets.length} active', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.loading && budgets.isEmpty)
                const SliverFillRemaining(child: LoadingOverlay(message: 'Loading budgets...'))
              else if (budgets.isEmpty)
                const SliverFillRemaining(child: EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No budgets set', subtitle: 'Create budgets to track spending limits'))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final b = budgets[index];
                        final spent = _estimateSpent(b, provider.expenses);
                        final progress = b.amount > 0 ? (spent / b.amount).clamp(0.0, 1.0) : 0.0;
                        final color = progress > 0.9 ? AppTheme.danger : progress > 0.7 ? AppTheme.warning : AppTheme.primary;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(b.category?.name ?? 'Uncategorized',
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                    AmountText(amount: b.amount),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${(progress * 100).toStringAsFixed(0)}% used', style: TextStyle(fontSize: 12, color: progress > 0.9 ? AppTheme.danger : AppTheme.textSecondary)),
                                    Text(_periodLabel(b.period), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: budgets.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _estimateSpent(Budget budget, List<Expense> expenses) {
    if (budget.category == null) return 0;
    return expenses
        .where((e) => e.category?.id == budget.category!.id)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'MONTHLY': return 'This month';
      case 'QUARTERLY': return 'This quarter';
      case 'YEARLY': return 'This year';
      default: return period;
    }
  }
}
