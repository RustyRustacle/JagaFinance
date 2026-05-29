import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'upload_receipt_screen.dart';
import 'expenses_screen.dart';
import 'budgets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(onTabChange: (i) => setState(() => _currentIndex = i)),
    const UploadReceiptScreen(),
    const ExpensesScreen(),
    const BudgetsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      ('Beranda', Icons.grid_view_rounded),
      ('Pindai', Icons.document_scanner_rounded),
      ('Pengeluaran', Icons.receipt_long_rounded),
      ('Anggaran', Icons.pie_chart_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -4)),
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
                  Icon(items[i].$2, size: 22, color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8)),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
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
