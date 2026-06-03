class Receipt {
  final String id;
  final String tenantId;
  final String uploadedBy;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String status;
  final double? ocrConfidence;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? blockchainTxHash;
  final String? blockchainStatus;
  final ReceiptData? receiptData;
  final Map<String, dynamic>? uploader;

  const Receipt({
    required this.id,
    required this.tenantId,
    required this.uploadedBy,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.status,
    this.ocrConfidence,
    this.errorMessage,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    this.blockchainTxHash,
    this.blockchainStatus,
    this.receiptData,
    this.uploader,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id']?.toString() ?? '',
      tenantId: (json['tenant_id'] ?? json['tenantId'] ?? '').toString(),
      uploadedBy: (json['uploaded_by'] ?? json['uploadedBy'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'] ?? '').toString(),
      fileName: (json['file_name'] ?? json['fileName'] ?? '').toString(),
      fileType: (json['file_type'] ?? json['fileType'] ?? '').toString(),
      fileSize: int.tryParse(json['file_size']?.toString() ?? json['fileSize']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'UPLOADED',
      ocrConfidence: _parseDouble(json['ocr_confidence'] ?? json['ocrConfidence']),
      errorMessage: json['error_message']?.toString() ?? json['errorMessage']?.toString(),
      processedAt: _parseDate(json['processed_at'] ?? json['processedAt']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
      blockchainTxHash: json['blockchain_tx_hash']?.toString() ?? json['blockchainTxHash']?.toString(),
      blockchainStatus: json['blockchain_status']?.toString() ?? json['blockchainStatus']?.toString(),
      receiptData: json['receiptData'] != null
          ? ReceiptData.fromJson(json['receiptData'] as Map<String, dynamic>)
          : json['receipt_data'] != null
              ? ReceiptData.fromJson(json['receipt_data'] as Map<String, dynamic>)
              : null,
      uploader: json['uploader'] as Map<String, dynamic>?,
    );
  }
}

class ReceiptData {
  final String id;
  final String receiptId;
  final String? merchantName;
  final String? merchantAddress;
  final String? merchantPhone;
  final String? receiptNumber;
  final DateTime? transactionDate;
  final double? subtotal;
  final double? taxAmount;
  final double? taxRate;
  final double? discountAmount;
  final double totalAmount;
  final String currency;
  final String? paymentMethod;
  final bool isVerified;
  final String? verificationNotes;

  const ReceiptData({
    required this.id,
    required this.receiptId,
    this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
    this.receiptNumber,
    this.transactionDate,
    this.subtotal,
    this.taxAmount,
    this.taxRate,
    this.discountAmount,
    required this.totalAmount,
    this.currency = 'IDR',
    this.paymentMethod,
    this.isVerified = false,
    this.verificationNotes,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      id: json['id']?.toString() ?? '',
      receiptId: (json['receipt_id'] ?? json['receiptId'] ?? '').toString(),
      merchantName: json['merchant_name']?.toString() ?? json['merchantName']?.toString(),
      merchantAddress: json['merchant_address']?.toString() ?? json['merchantAddress']?.toString(),
      merchantPhone: json['merchant_phone']?.toString() ?? json['merchantPhone']?.toString(),
      receiptNumber: json['receipt_number']?.toString() ?? json['receiptNumber']?.toString(),
      transactionDate: _parseDate(json['transaction_date'] ?? json['transactionDate']),
      subtotal: _parseDouble(json['subtotal']),
      taxAmount: _parseDouble(json['tax_amount'] ?? json['taxAmount']),
      taxRate: _parseDouble(json['tax_rate'] ?? json['taxRate']),
      discountAmount: _parseDouble(json['discount_amount'] ?? json['discountAmount']),
      totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']) ?? 0.0,
      currency: json['currency']?.toString() ?? 'IDR',
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString(),
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      verificationNotes: json['verification_notes']?.toString() ?? json['verificationNotes']?.toString(),
    );
  }
}

class Expense {
  final String id;
  final String tenantId;
  final String? receiptId;
  final String categoryId;
  final String createdBy;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final String? paymentMethod;
  final String status;
  final bool taxDeductible;
  final List<String> tags;
  final String? costCenter;
  final String? projectCode;
  final DateTime createdAt;
  final ExpenseCategory? category;
  final Receipt? receipt;
  final Map<String, dynamic>? creator;

  const Expense({
    required this.id,
    required this.tenantId,
    this.receiptId,
    required this.categoryId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.amount,
    this.currency = 'IDR',
    required this.expenseDate,
    this.paymentMethod,
    this.status = 'DRAFT',
    this.taxDeductible = false,
    this.tags = const [],
    this.costCenter,
    this.projectCode,
    required this.createdAt,
    this.category,
    this.receipt,
    this.creator,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // PROTEKSI: Mencegah error Parsing Date yang sering menyebabkan Black Screen
    DateTime parsedDate;
    try {
      parsedDate = _parseDate(json['expense_date'] ?? json['expenseDate']) ?? DateTime.now();
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Expense(
      id: json['id']?.toString() ?? '',
      tenantId: (json['tenant_id'] ?? json['tenantId'] ?? '').toString(),
      receiptId: (json['receipt_id'] ?? json['receiptId'])?.toString(),
      categoryId: (json['category_id'] ?? json['categoryId'] ?? '').toString(),
      createdBy: (json['created_by'] ?? json['createdBy'] ?? '').toString(),
      // PROTEKSI: Fallback Title yang aman untuk UI
      title: json['title']?.toString().isNotEmpty == true 
          ? json['title'].toString() 
          : 'Transaksi Tanpa Nama',
      description: json['description']?.toString(),
      amount: _parseDouble(json['amount']) ?? 0.0,
      currency: json['currency']?.toString() ?? 'IDR',
      expenseDate: parsedDate,
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      taxDeductible: json['tax_deductible'] as bool? ?? json['taxDeductible'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      costCenter: json['cost_center']?.toString() ?? json['costCenter']?.toString(),
      projectCode: json['project_code']?.toString() ?? json['projectCode']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      receipt: json['receipt'] != null
          ? Receipt.fromJson(json['receipt'] as Map<String, dynamic>)
          : null,
      creator: json['creator'] as Map<String, dynamic>?,
    );
  }
}

class ExpenseCategory {
  final String id;
  final String tenantId;
  final String name;
  final String? nameEn;
  final String color;
  final String? icon;
  final String? parentId;
  final bool isActive;
  final int sortOrder;

  const ExpenseCategory({
    required this.id,
    required this.tenantId,
    required this.name,
    this.nameEn,
    this.color = '#6B7280',
    this.icon,
    this.parentId,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id']?.toString() ?? '',
      tenantId: (json['tenant_id'] ?? json['tenantId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? json['nameEn']?.toString(),
      color: json['color']?.toString() ?? '#6B7280',
      icon: json['icon']?.toString(),
      parentId: json['parent_id']?.toString() ?? json['parentId']?.toString(),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? json['sortOrder']?.toString() ?? '0') ?? 0,
    );
  }
}

class Budget {
  final String id;
  final String tenantId;
  final String categoryId;
  final double amount;
  final String currency;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final double alertThreshold;
  final bool isActive;
  final ExpenseCategory? category;

  const Budget({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.amount,
    this.currency = 'IDR',
    this.period = 'MONTHLY',
    required this.startDate,
    required this.endDate,
    this.alertThreshold = 80,
    this.isActive = true,
    this.category,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id']?.toString() ?? '',
      tenantId: (json['tenant_id'] ?? json['tenantId'] ?? '').toString(),
      categoryId: (json['category_id'] ?? json['categoryId'] ?? '').toString(),
      amount: _parseDouble(json['amount']) ?? 0.0,
      currency: json['currency']?.toString() ?? 'IDR',
      period: json['period']?.toString() ?? 'MONTHLY',
      startDate: _parseDate(json['start_date'] ?? json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date'] ?? json['endDate']) ?? DateTime.now(),
      alertThreshold: _parseDouble(json['alert_threshold'] ?? json['alertThreshold']) ?? 80.0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BudgetUsage {
  final double spent;
  final double remaining;
  final double percentage;
  final bool alertTriggered;
  final double nextThreshold;
  final String categoryName;
  final String? categoryNameEn;

  const BudgetUsage({
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.alertTriggered,
    required this.nextThreshold,
    required this.categoryName,
    this.categoryNameEn,
  });

  factory BudgetUsage.fromJson(Map<String, dynamic> json) {
    return BudgetUsage(
      spent: _parseDouble(json['spent']) ?? 0.0,
      remaining: _parseDouble(json['remaining']) ?? 0.0,
      percentage: _parseDouble(json['percentage']) ?? 0.0,
      alertTriggered: json['alertTriggered'] as bool? ?? false,
      nextThreshold: _parseDouble(json['nextThreshold']) ?? 80.0,
      categoryName: json['category']?['name']?.toString() ?? 'Unknown',
      categoryNameEn: json['category']?['nameEn']?.toString(),
    );
  }
}

class CategoryExpense {
  final String category;
  final double amount;
  final double percentage;

  const CategoryExpense({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) {
    return CategoryExpense(
      category: json['category']?.toString() ?? 'Unknown',
      amount: _parseDouble(json['amount']) ?? 0.0,
      percentage: _parseDouble(json['percentage']) ?? 0.0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final double amount;

  const MonthlyTrend({
    required this.month,
    required this.amount,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month']?.toString() ?? '',
      amount: _parseDouble(json['amount']) ?? 0.0,
    );
  }
}

class DashboardData {
  final double totalExpenses;
  final int totalReceipts;
  final int pendingReviews;
  final int budgetAlerts;
  final List<CategoryExpense> expensesByCategory;
  final List<MonthlyTrend> monthlyTrend;

  const DashboardData({
    this.totalExpenses = 0,
    this.totalReceipts = 0,
    this.pendingReviews = 0,
    this.budgetAlerts = 0,
    this.expensesByCategory = const [],
    this.monthlyTrend = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalExpenses: _parseDouble(json['total_expenses'] ?? json['totalExpenses']) ?? 0.0,
      totalReceipts: int.tryParse(json['total_receipts']?.toString() ?? json['totalReceipts']?.toString() ?? '0') ?? 0,
      pendingReviews: int.tryParse(json['pending_reviews']?.toString() ?? json['pendingReviews']?.toString() ?? '0') ?? 0,
      budgetAlerts: int.tryParse(json['budget_alerts']?.toString() ?? json['budgetAlerts']?.toString() ?? '0') ?? 0,
      expensesByCategory: (json['expenses_by_category'] as List<dynamic>?)
              ?.map((e) => CategoryExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyTrend: (json['monthly_trend'] as List<dynamic>?)
              ?.map((e) => MonthlyTrend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}