import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/receipt.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onTabChange});

  final void Function(int)? onTabChange;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>()..loadDashboard()..loadExpenses(refresh: true)..loadBudgets();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<DashboardProvider>().loadExpenses(refresh: true),
      context.read<DashboardProvider>().loadBudgets(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                Consumer<DashboardProvider>(
                  builder: (context, dash, _) {
                    if (dash.isLoading) return const SizedBox(height: 200, child: LoadingOverlay(message: 'Memuat dashboard...'));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalSpendingCard(dash.dashboard),
                        const SizedBox(height: 16),
                        _buildStatsRow(dash.dashboard),
                        const SizedBox(height: 20),
                        if (dash.dashboard.monthlyTrend.isNotEmpty) ...[
                          _buildTrendChart(dash.dashboard.monthlyTrend),
                          const SizedBox(height: 20),
                        ],
                        if (dash.budgets.isNotEmpty) ...[
                          _buildBudgetSection(dash),
                          const SizedBox(height: 20),
                        ],
                        _buildRecentExpenses(dash.expenses),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
    final initial = (auth.user?.name ?? auth.user?.email ?? 'U')[0].toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              auth.user?.name ?? 'Pengguna',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          onSelected: (v) async {
            if (v == 'profile') {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Profil'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileRow('Nama', auth.user?.name ?? '-'),
                      const SizedBox(height: 8),
                      _profileRow('Email', auth.user?.email),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            } else if (v == 'logout') {
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: ListTile(
              leading: Icon(Icons.person_outline_rounded, size: 20),
              title: Text('Profil', style: TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: ListTile(
              leading: Icon(Icons.logout_rounded, size: 20, color: AppTheme.danger),
              title: Text('Keluar', style: TextStyle(fontSize: 14, color: AppTheme.danger)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
          ],
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi,';
    if (hour < 15) return 'Selamat siang,';
    if (hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  Widget _buildTotalSpendingCard(DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Pengeluaran Bulan Ini', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          AmountText(
            amount: data.totalExpenses,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _cardStat('Struk Diproses', '${data.pendingReviews}'),
              const SizedBox(width: 16),
              _cardStat('Anggaran Terpakai', '${data.budgetAlerts}'),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DashboardData data) {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.description_outlined, 'Struk', '${data.totalReceipts}', AppTheme.success, const Color(0xFFD1FAE5))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.pie_chart_rounded, 'Kategori', '${data.expensesByCategory.length}', AppTheme.secondary, const Color(0xFFEDE9FE))),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<MonthlyTrend> trends) {
    final maxAmount = trends.fold<double>(0, (max, t) => t.amount > max ? t.amount : max);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren Pengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100, 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(trends.length, (i) {
                final t = trends[i];
                final height = maxAmount > 0 ? (t.amount / maxAmount) * 80 : 0.0; 
                final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                final monthNum = int.tryParse(t.month.split('-')[1]) ?? 0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == trends.length - 1 ? 0 : 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.decimalPattern('id').format(t.amount.round()),
                          style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height.clamp(8.0, 70.0), 
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          monthNum >= 1 && monthNum <= 12 ? monthNames[monthNum] : t.month,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(DashboardProvider dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Anggaran',
          actionLabel: 'Lihat Semua',
          onAction: () => _switchTab(3),
        ),
        const SizedBox(height: 12),
        ...dash.budgets.take(3).map((b) {
          final catName = b.category?.name ?? 'Kategori';
          final spent = dash.dashboard.expensesByCategory.where((c) => c.category == catName).fold<double>(0, (sum, c) => sum + c.amount);
          final pct = b.amount > 0 ? (spent / b.amount).clamp(0.0, 1.0) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _budgetBar(catName, pct, b.amount, spent),
          );
        }),
      ],
    );
  }

  Widget _budgetBar(String label, double progress, double budget, double spent) {
    final exceeded = progress >= 1.0;
    final warning = progress >= 0.8 && !exceeded;
    final barColor = exceeded ? AppTheme.danger : warning ? AppTheme.warning : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ),
              AmountText(amount: spent, fontSize: 13, color: AppTheme.textSecondary),
              const Text(' / ', style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
              AmountText(amount: budget, fontSize: 13, color: AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses(List<Expense> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pengeluaran Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        if (expenses.isEmpty)
          const EmptyState(icon: Icons.receipt_long_rounded, title: 'Belum ada pengeluaran', subtitle: 'Mulai dengan mengunggah struk pertama Anda')
        else
          ...expenses.take(5).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _expenseItem(e),
          )),
      ],
    );
  }

  Widget _expenseItem(Expense exp) {
    final iconMap = <String, IconData>{
      'Transportasi': Icons.directions_car_rounded,
      'Makanan': Icons.restaurant_rounded,
      'Kantor': Icons.inventory_2_rounded,
      'Utilitas': Icons.bolt_rounded,
      'Marketing': Icons.campaign_rounded,
      'Gaji': Icons.account_balance_wallet_rounded,
      'Sewa': Icons.home_rounded,
      'Perjalanan': Icons.flight_rounded,
    };
    final catName = exp.category?.name ?? '';
    final icon = iconMap.entries.firstWhere((e) => catName.contains(e.key), orElse: () => const MapEntry('', Icons.receipt_outlined)).value;

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
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
            child: Icon(icon, size: 20, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(catName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(amount: exp.amount, fontSize: 14, fontWeight: FontWeight.w600),
              const SizedBox(height: 2),
              Text(
                DateFormat('d MMM', 'id').format(exp.expenseDate),
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _switchTab(int index) {
    widget.onTabChange?.call(index);
  }

  Widget _profileRow(String label, String? value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}