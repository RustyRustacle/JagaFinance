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
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String,
      uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String,
      fileName: json['file_name'] as String? ?? json['fileName'] as String,
      fileType: json['file_type'] as String? ?? json['fileType'] as String,
      fileSize: (json['file_size'] ?? json['fileSize'] ?? 0) as int,
      status: json['status'] as String? ?? 'UPLOADED',
      ocrConfidence: _parseDouble(json['ocr_confidence'] ?? json['ocrConfidence']),
      errorMessage: json['error_message'] as String? ?? json['errorMessage'] as String?,
      processedAt: _parseDate(json['processed_at'] ?? json['processedAt']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now(),
      blockchainTxHash: json['blockchain_tx_hash'] as String? ?? json['blockchainTxHash'] as String?,
      blockchainStatus: json['blockchain_status'] as String? ?? json['blockchainStatus'] as String?,
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
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String? ?? json['receiptId'] as String,
      merchantName: json['merchant_name'] as String? ?? json['merchantName'] as String?,
      merchantAddress: json['merchant_address'] as String? ?? json['merchantAddress'] as String?,
      merchantPhone: json['merchant_phone'] as String? ?? json['merchantPhone'] as String?,
      receiptNumber: json['receipt_number'] as String? ?? json['receiptNumber'] as String?,
      transactionDate: _parseDate(json['transaction_date'] ?? json['transactionDate']),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? (json['taxAmount'] as num?)?.toDouble(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? (json['taxRate'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? (json['discountAmount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] ?? json['totalAmount'] ?? 0).runtimeType == double
          ? (json['total_amount'] ?? json['totalAmount']) as double
          : ((json['total_amount'] ?? json['totalAmount']) as num).toDouble(),
      currency: json['currency'] as String? ?? 'IDR',
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      verificationNotes: json['verification_notes'] as String? ?? json['verificationNotes'] as String?,
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
    return Expense(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String,
      receiptId: json['receipt_id'] as String? ?? json['receiptId'] as String?,
      categoryId: json['category_id'] as String? ?? json['categoryId'] as String,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'IDR',
      expenseDate: _parseDate(json['expense_date'] ?? json['expenseDate']) ?? DateTime.now(),
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      taxDeductible: json['tax_deductible'] as bool? ?? json['taxDeductible'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      costCenter: json['cost_center'] as String? ?? json['costCenter'] as String?,
      projectCode: json['project_code'] as String? ?? json['projectCode'] as String?,
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
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String? ?? json['nameEn'] as String?,
      color: json['color'] as String? ?? '#6B7280',
      icon: json['icon'] as String?,
      parentId: json['parent_id'] as String? ?? json['parentId'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
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
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String,
      categoryId: json['category_id'] as String? ?? json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'IDR',
      period: json['period'] as String? ?? 'MONTHLY',
      startDate: _parseDate(json['start_date'] ?? json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date'] ?? json['endDate']) ?? DateTime.now(),
      alertThreshold: (json['alert_threshold'] as num?)?.toDouble() ?? (json['alertThreshold'] as num?)?.toDouble() ?? 80,
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
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      alertTriggered: json['alertTriggered'] as bool? ?? false,
      nextThreshold: (json['nextThreshold'] as num?)?.toDouble() ?? 80,
      categoryName: json['category']?['name'] as String? ?? 'Unknown',
      categoryNameEn: json['category']?['nameEn'] as String?,
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
      category: json['category'] as String? ?? 'Unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
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
      month: json['month'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
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
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      totalReceipts: (json['total_receipts'] as int?) ?? 0,
      pendingReviews: (json['pending_reviews'] as int?) ?? 0,
      budgetAlerts: (json['budget_alerts'] as int?) ?? 0,
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
