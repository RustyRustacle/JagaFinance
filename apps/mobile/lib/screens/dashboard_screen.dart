import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/receipt.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      provider.loadDashboard();
      provider.loadExpenses();
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<DashboardProvider>();
    await Future.wait([
      provider.loadDashboard(),
      provider.loadExpenses(),
      provider.loadReceipts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTopBar(auth),
                const SizedBox(height: 20),
                _buildMainCard(provider),
                const SizedBox(height: 16),
                _buildStatsRow(provider),
                const SizedBox(height: 20),
                if (provider.loading && provider.dashboard == null)
                  const LoadingOverlay(message: 'Loading dashboard...')
                else if (provider.dashboard != null) ...[
                  _buildBudgetProgress(provider.dashboard!),
                  const SizedBox(height: 20),
                  _buildCategoryBreakdown(provider.dashboard!),
                  const SizedBox(height: 20),
                  _buildRecentExpenses(provider),
                ] else if (provider.error != null)
                  ErrorView(message: provider.error!, onRetry: _onRefresh),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning,',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              auth.user?.name ?? 'User',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => auth.logout(),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (auth.user?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(DashboardProvider provider) {
    final dash = provider.dashboard;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Spending', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            AmountText(amount: dash?.totalExpenses ?? 0).data,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _cardStat('Receipts', '${dash?.totalReceipts ?? 0}'),
              const SizedBox(width: 16),
              _cardStat('Pending', '${dash?.pendingReviews ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DashboardProvider provider) {
    final dash = provider.dashboard;
    if (dash == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(child: _statCard(Icons.document_scanner_outlined, 'OCR Success', '${dash.totalReceipts}', AppTheme.success, const Color(0xFFD1FAE5))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.warning_amber_rounded, 'Alerts', '${dash.budgetAlerts}', AppTheme.warning, const Color(0xFFFEF3C7))),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(DashboardData dash) {
    if (dash.expensesByCategory.isEmpty) return const SizedBox.shrink();

    final totalBudget = dash.expensesByCategory.fold<double>(0, (sum, c) => sum + (c.amount > 0 ? c.amount / (c.percentage / 100) : 0));
    final totalSpent = dash.totalExpenses;
    final progress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('This Month', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? AppTheme.danger : progress > 0.7 ? AppTheme.warning : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toStringAsFixed(1)}% used', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('${dash.budgetAlerts} alert${dash.budgetAlerts != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: dash.budgetAlerts > 0 ? AppTheme.danger : AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(DashboardData dash) {
    if (dash.expensesByCategory.isEmpty) return const EmptyState(icon: Icons.pie_chart_outline, title: 'No expense data', subtitle: 'Start uploading receipts to see breakdown');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Category Breakdown'),
          const SizedBox(height: 12),
          ...dash.expensesByCategory.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(c.category, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                ),
                SizedBox(
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.percentage / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text('${c.percentage.toStringAsFixed(1)}%', textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses(DashboardProvider provider) {
    final recent = provider.expenses.take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Expenses', actionLabel: 'See All'),
        const SizedBox(height: 8),
        ...recent.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: Row(
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
                      Text(e.category?.name ?? '-', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                AmountText(amount: e.amount),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

extension on AmountText {
  String get data {
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${amount.toInt()}';
  }
}
