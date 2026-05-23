class Receipt {
  final String id;
  final String fileName;
  final String fileUrl;
  final String status;
  final int fileSize;
  final double? ocrConfidence;
  final ReceiptData? receiptData;
  final String createdAt;

  Receipt({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.status,
    required this.fileSize,
    this.ocrConfidence,
    this.receiptData,
    required this.createdAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      status: json['status'] as String,
      fileSize: json['fileSize'] as int? ?? 0,
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
      receiptData: json['receiptData'] != null
          ? ReceiptData.fromJson(json['receiptData'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String,
    );
  }
}

class ReceiptData {
  final String? merchantName;
  final String? merchantAddress;
  final String? receiptNumber;
  final String? transactionDate;
  final double? subtotal;
  final double? taxAmount;
  final double? totalAmount;
  final String? currency;
  final String? paymentMethod;

  ReceiptData({
    this.merchantName,
    this.merchantAddress,
    this.receiptNumber,
    this.transactionDate,
    this.subtotal,
    this.taxAmount,
    this.totalAmount,
    this.currency,
    this.paymentMethod,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      merchantName: json['merchantName'] as String?,
      merchantAddress: json['merchantAddress'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
      transactionDate: json['transactionDate'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
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

  DashboardData({
    required this.totalExpenses,
    required this.totalReceipts,
    required this.pendingReviews,
    required this.budgetAlerts,
    required this.expensesByCategory,
    required this.monthlyTrend,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      totalReceipts: (json['total_receipts'] as num?)?.toInt() ?? 0,
      pendingReviews: (json['pending_reviews'] as num?)?.toInt() ?? 0,
      budgetAlerts: (json['budget_alerts'] as num?)?.toInt() ?? 0,
      expensesByCategory: (json['expenses_by_category'] as List<dynamic>?)
              ?.map((e) =>
                  CategoryExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyTrend: (json['monthly_trend'] as List<dynamic>?)
              ?.map(
                  (m) => MonthlyTrend.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CategoryExpense {
  final String category;
  final double amount;
  final double percentage;

  CategoryExpense({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) {
    return CategoryExpense(
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final double amount;

  MonthlyTrend({required this.month, required this.amount});

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Expense {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String expenseDate;
  final String status;
  final String? paymentMethod;
  final bool taxDeductible;
  final List<String> tags;
  final String? costCenter;
  final String? projectCode;
  final ExpenseCategory? category;

  Expense({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.expenseDate,
    required this.status,
    this.paymentMethod,
    required this.taxDeductible,
    this.tags = const [],
    this.costCenter,
    this.projectCode,
    this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      expenseDate: json['expenseDate'] as String,
      status: json['status'] as String? ?? 'DRAFT',
      paymentMethod: json['paymentMethod'] as String?,
      taxDeductible: json['taxDeductible'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      costCenter: json['costCenter'] as String?,
      projectCode: json['projectCode'] as String?,
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ExpenseCategory {
  final String id;
  final String name;
  final String? nameEn;
  final String color;
  final String? icon;

  ExpenseCategory({
    required this.id,
    required this.name,
    this.nameEn,
    required this.color,
    this.icon,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String?,
      color: json['color'] as String? ?? '#6B7280',
      icon: json['icon'] as String?,
    );
  }
}

class Budget {
  final String id;
  final double amount;
  final String currency;
  final String period;
  final String startDate;
  final String endDate;
  final double alertThreshold;
  final bool isActive;
  final ExpenseCategory? category;

  Budget({
    required this.id,
    required this.amount,
    required this.currency,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.alertThreshold,
    required this.isActive,
    this.category,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      period: json['period'] as String? ?? 'MONTHLY',
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 80,
      isActive: json['isActive'] as bool? ?? true,
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}
