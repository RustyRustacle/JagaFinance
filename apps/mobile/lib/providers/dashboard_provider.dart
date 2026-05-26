import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;

  DashboardData? _dashboard;
  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<Budget> _budgets = [];
  bool _loading = false;
  String? _error;

  DashboardProvider(this._api);

  DashboardData? get dashboard => _dashboard;
  List<Expense> get expenses => _expenses;
  List<Receipt> get receipts => _receipts;
  List<Budget> get budgets => _budgets;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/dashboard/overview');
      _dashboard = DashboardData.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load dashboard';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    try {
      final response = await _api.get('/expenses');
      final data = response['data'] as List<dynamic>? ?? [];
      _expenses = data.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadReceipts() async {
    try {
      final response = await _api.get('/receipts');
      final data = (response['data'] as List<dynamic>?) ?? [];
      _receipts = data.map((r) => Receipt.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadBudgets() async {
    try {
      final response = await _api.get('/budgets');
      final data = response['data'] as List<dynamic>? ?? [];
      _budgets = data.map((b) => Budget.fromJson(b as Map<String, dynamic>)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> uploadReceipt(String filePath, String fileName) async {
    try {
      await _api.uploadFile('/receipts/upload',
          filePath: filePath, fieldName: 'file', fileName: fileName);
      await loadReceipts();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
