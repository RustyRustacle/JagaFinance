import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'upload_receipt_screen.dart';
import 'expenses_screen.dart';
import 'budgets_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    UploadReceiptScreen(),
    ExpensesScreen(),
    BudgetsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: _buildBottomNav(context, auth),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, AuthProvider auth) {
    final items = [
      ('Dashboard', Icons.grid_view_rounded),
      ('Scan', Icons.camera_alt_rounded),
      ('Expenses', Icons.receipt_long_rounded),
      ('Budgets', Icons.account_balance_wallet_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = _currentIndex == i;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFDBEAFE) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$2,
                    size: 22,
                    color: isActive ? AppTheme.primary : AppTheme.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppTheme.primary : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
