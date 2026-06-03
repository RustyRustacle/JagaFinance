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
  String? _lastUploadedReceiptId;

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
  String? get lastUploadedReceiptId => _lastUploadedReceiptId;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/dashboard/overview');
      _dashboard = DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      _errorMessage = 'Gagal memuat dashboard';
      debugPrint("Error loadDashboard: $e");
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
      debugPrint("Error loadExpenses: $e");
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
    _errorMessage = null; 
    notifyListeners();

    try {
      final response = await _api.get('/receipts', queryParameters: {
        'page': _page,
        'limit': _limit,
        'sort': 'created_at',
        'order': 'desc',
      });
      
      final data = response.data;
      final List<dynamic> rawList = data['data'] as List<dynamic>;
      List<Receipt> parsedReceipts = [];

      for (var item in rawList) {
        try {
          parsedReceipts.add(Receipt.fromJson(item as Map<String, dynamic>));
        } catch (itemError) {
          debugPrint("Safe Parsing Warning (Receipt Ignored): $itemError");
        }
      }

      _receipts = parsedReceipts;
    } catch (e) {
      debugPrint("Quiet Load Receipts Failed: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // ===================================================================
  // Penerapan Safe Parsing Loop untuk Mencegah Layar Blank
  // ===================================================================
  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get('/budgets');
      final List<dynamic> rawList = response.data['data'] as List<dynamic>;
      List<Budget> parsedBudgets = [];

      for (var item in rawList) {
        try {
          parsedBudgets.add(Budget.fromJson(item as Map<String, dynamic>));
        } catch (itemError) {
          debugPrint("Gagal mengurai item anggaran tunggal (Diabaikan agar tidak merusak list): $itemError");
        }
      }
      _budgets = parsedBudgets;
    } catch (e) {
      _errorMessage = 'Gagal memuat anggaran';
      debugPrint("Komponen Utama loadBudgets Error: $e");
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
    _errorMessage = null;
    _lastUploadedReceiptId = null;
    notifyListeners();

    try {
      final response = await _api.upload(
        '/receipts/upload',
        filePath: filePath,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      final receiptData = response.data['data'] as Map<String, dynamic>?;
      _lastUploadedReceiptId = receiptData?['id'] as String?;
      _isUploading = false;
      _uploadProgress = 1;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      _errorMessage = 'Gagal mengunggah struk ke cloud storage';
      notifyListeners();
      return false;
    }
  }

  // ===================================================================
  // SINKRONISASI TOTAL: Pemicu Otomatis Ketika Pengeluaran Baru Disimpan
  // ===================================================================
  Future<bool> createExpense({
    required String title,
    required double amount,
    required String expenseDate,
    String? receiptId,
    String? categoryId,
  }) async {
    try {
      await _api.post('/expenses', data: {
        'title': title,
        'amount': amount,
        'expense_date': expenseDate,
        if (receiptId != null) 'receipt_id': receiptId,
        if (categoryId != null) 'category_id': categoryId,
      });
      
      
      await loadExpenses(refresh: true); 
      await loadBudgets();               
      await loadDashboard();              
      
      return true;
    } catch (e) {
      debugPrint("Gagal menyimpan transaksi pengeluaran: $e");
      return false;
    }
  }

  // ===================================================================
  // Trigger Otomatis Ketika Anggaran Baru Disimpan
  // ===================================================================
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
      await loadDashboard();   
      
      return true;
    } catch (e) {
      debugPrint("Gagal menyimpan data anggaran baru: $e");
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}