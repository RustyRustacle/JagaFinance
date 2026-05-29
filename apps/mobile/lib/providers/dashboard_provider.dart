import 'package:flutter/foundation.dart';
import '../models/receipt.dart';
import '../services/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;

  DashboardData _dashboard = const DashboardData();
  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<Budget> _budgets = [];
  List<ExpenseCategory> _categories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _page = 1;
  final int _limit = 20;
  double _uploadProgress = 0;
  bool _isUploading = false;

  DashboardProvider(this._api);

  DashboardData get dashboard => _dashboard;
  List<Expense> get expenses => _expenses;
  List<Receipt> get receipts => _receipts;
  List<Budget> get budgets => _budgets;
  List<ExpenseCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;
  bool get isUploading => _isUploading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/dashboard/overview');
      _dashboard = DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      _errorMessage = 'Gagal memuat dashboard';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExpenses({bool refresh = false, String? categoryId, String? status}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    _isLoading = refresh || _expenses.isEmpty;
    _errorMessage = null;
    if (!refresh) _isLoadingMore = true;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': _page,
        'limit': _limit,
        'sort': 'expense_date',
        'order': 'desc',
      };
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (status != null) queryParams['status'] = status;
      final response = await _api.get('/expenses', queryParameters: queryParams);
      final data = response.data;
      final list = (data['data'] as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>;
      final totalPages = meta['totalPages'] as int;

      if (refresh || _page == 1) {
        _expenses = list;
      } else {
        _expenses.addAll(list);
      }
      _hasMore = _page < totalPages;
    } catch (e) {
      _errorMessage = 'Gagal memuat pengeluaran';
    }
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMoreExpenses() async {
    if (_isLoadingMore || !_hasMore) return;
    _page++;
    await loadExpenses();
  }

  Future<void> loadReceipts({bool refresh = false}) async {
    if (refresh) _page = 1;
    _isLoading = refresh || _receipts.isEmpty;
    notifyListeners();

    try {
      final response = await _api.get('/receipts', queryParameters: {
        'page': _page,
        'limit': _limit,
        'sort': 'created_at',
        'order': 'desc',
      });
      final data = response.data;
      _receipts = (data['data'] as List<dynamic>)
          .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat struk';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/budgets');
      _budgets = (response.data['data'] as List<dynamic>)
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat anggaran';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final response = await _api.get('/categories');
      _categories = (response.data['data'] as List<dynamic>)
          .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> uploadReceipt(String filePath) async {
    _isUploading = true;
    _uploadProgress = 0;
    notifyListeners();

    try {
      await _api.upload(
        '/receipts/upload',
        filePath: filePath,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      _isUploading = false;
      _uploadProgress = 1;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      _errorMessage = 'Gagal mengunggah struk';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createBudget({
    required String categoryId,
    required double amount,
    required String period,
    required String startDate,
    required String endDate,
    double alertThreshold = 80,
  }) async {
    try {
      await _api.post('/budgets', data: {
        'category_id': categoryId,
        'amount': amount,
        'period': period,
        'start_date': startDate,
        'end_date': endDate,
        'alert_threshold': alertThreshold,
      });
      await loadBudgets();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
