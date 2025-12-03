/// Model for employee advance payment
class EmployeeAdvance {
  final String advanceId;
  final String employeeId;
  final String employeeName;
  final String? tamilName;
  final double amount;
  final DateTime advanceDate;
  final String paymentMode;
  final String? paymentReference;
  final String? reason;
  final String? remarks;
  final String status;
  final String? expenseId;
  final double adjustedAmount;
  final double remainingAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  EmployeeAdvance({
    required this.advanceId,
    required this.employeeId,
    required this.employeeName,
    this.tamilName,
    required this.amount,
    required this.advanceDate,
    required this.paymentMode,
    this.paymentReference,
    this.reason,
    this.remarks,
    required this.status,
    this.expenseId,
    this.adjustedAmount = 0.0,
    this.remainingAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory EmployeeAdvance.fromJson(Map<String, dynamic> json) {
    return EmployeeAdvance(
      advanceId: json['advance_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      tamilName: json['tamil_name']?.toString(),
      amount: _parseDouble(json['amount']),
      advanceDate: DateTime.parse(json['advance_date']),
      paymentMode: json['payment_mode']?.toString() ?? 'Cash',
      paymentReference: json['payment_reference']?.toString(),
      reason: json['reason']?.toString(),
      remarks: json['remarks']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      expenseId: json['expense_id']?.toString(),
      adjustedAmount: _parseDouble(json['adjusted_amount']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advance_id': advanceId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'tamil_name': tamilName,
      'amount': amount,
      'advance_date': advanceDate.toIso8601String().split('T')[0],
      'payment_mode': paymentMode,
      'payment_reference': paymentReference,
      'reason': reason,
      'remarks': remarks,
      'status': status,
      'expense_id': expenseId,
      'adjusted_amount': adjustedAmount,
      'remaining_amount': remainingAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get isFullyAdjusted => remainingAmount == 0;
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isAdjusted => status == 'adjusted';
}

/// Request model for creating employee advance
class CreateAdvanceRequest {
  final String employeeId;
  final double amount;
  final DateTime? advanceDate;
  final String paymentMode;
  final String? paymentReference;
  final String? reason;
  final String? remarks;
  final String status;

  CreateAdvanceRequest({
    required this.employeeId,
    required this.amount,
    this.advanceDate,
    this.paymentMode = 'Cash',
    this.paymentReference,
    this.reason,
    this.remarks,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'employee_id': employeeId,
      'amount': amount,
      'payment_mode': paymentMode,
      'status': status,
    };

    if (advanceDate != null) {
      data['advance_date'] = advanceDate!.toIso8601String().split('T')[0];
    }

    if (paymentReference != null && paymentReference!.isNotEmpty) {
      data['payment_reference'] = paymentReference;
    }

    if (reason != null && reason!.isNotEmpty) {
      data['reason'] = reason;
    }

    if (remarks != null && remarks!.isNotEmpty) {
      data['remarks'] = remarks;
    }

    return data;
  }
}

/// Response model for employee advances list
class EmployeeAdvancesResponse {
  final List<EmployeeAdvance> advances;
  final PaginationInfo pagination;
  final AdvanceSummary summary;

  EmployeeAdvancesResponse({
    required this.advances,
    required this.pagination,
    required this.summary,
  });

  factory EmployeeAdvancesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    List<EmployeeAdvance> advances = [];
    if (data['advances'] != null && data['advances'] is List) {
      advances = (data['advances'] as List)
          .map((e) => EmployeeAdvance.fromJson(e))
          .toList();
    }

    return EmployeeAdvancesResponse(
      advances: advances,
      pagination: PaginationInfo.fromJson(data['pagination'] ?? {}),
      summary: AdvanceSummary.fromJson(data['summary'] ?? {}),
    );
  }
}

/// Pagination information
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
  final int perPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNext,
    required this.hasPrevious,
    required this.perPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalCount: json['total_count'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      perPage: json['per_page'] ?? 20,
    );
  }
}

/// Summary information for advances
class AdvanceSummary {
  final int totalAdvances;
  final double totalAmount;

  AdvanceSummary({
    required this.totalAdvances,
    required this.totalAmount,
  });

  factory AdvanceSummary.fromJson(Map<String, dynamic> json) {
    return AdvanceSummary(
      totalAdvances: json['total_advances'] ?? 0,
      totalAmount: _parseDouble(json['total_amount']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Detailed employee advance summary
class EmployeeAdvanceSummaryData {
  final String employeeId;
  final String employeeName;
  final String? tamilName;
  final AdvanceSummaryStats summary;
  final List<EmployeeAdvance> recentAdvances;
  final DateRange? dateRange;

  EmployeeAdvanceSummaryData({
    required this.employeeId,
    required this.employeeName,
    this.tamilName,
    required this.summary,
    required this.recentAdvances,
    this.dateRange,
  });

  factory EmployeeAdvanceSummaryData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final employee = data['employee'] ?? {};

    List<EmployeeAdvance> recentAdvances = [];
    if (data['recent_advances'] != null && data['recent_advances'] is List) {
      recentAdvances = (data['recent_advances'] as List)
          .map((e) => EmployeeAdvance.fromJson(e))
          .toList();
    }

    DateRange? dateRange;
    if (data['date_range'] != null) {
      dateRange = DateRange.fromJson(data['date_range']);
    }

    return EmployeeAdvanceSummaryData(
      employeeId: employee['employee_id']?.toString() ?? '',
      employeeName: employee['employee_name']?.toString() ?? '',
      tamilName: employee['tamil_name']?.toString(),
      summary: AdvanceSummaryStats.fromJson(data['summary'] ?? {}),
      recentAdvances: recentAdvances,
      dateRange: dateRange,
    );
  }
}

/// Advance summary statistics
class AdvanceSummaryStats {
  final int totalAdvances;
  final double totalAmount;
  final Map<String, StatusBreakdown> statusBreakdown;

  AdvanceSummaryStats({
    required this.totalAdvances,
    required this.totalAmount,
    required this.statusBreakdown,
  });

  factory AdvanceSummaryStats.fromJson(Map<String, dynamic> json) {
    Map<String, StatusBreakdown> breakdown = {};

    if (json['status_breakdown'] != null && json['status_breakdown'] is Map) {
      final breakdownData = json['status_breakdown'] as Map<String, dynamic>;
      breakdownData.forEach((key, value) {
        breakdown[key] = StatusBreakdown.fromJson(value);
      });
    }

    return AdvanceSummaryStats(
      totalAdvances: json['total_advances'] ?? 0,
      totalAmount: _parseDouble(json['total_amount']),
      statusBreakdown: breakdown,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Status breakdown data
class StatusBreakdown {
  final int count;
  final double amount;

  StatusBreakdown({
    required this.count,
    required this.amount,
  });

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      count: json['count'] ?? 0,
      amount: _parseDouble(json['amount']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Date range model
class DateRange {
  final String? fromDate;
  final String? toDate;

  DateRange({
    this.fromDate,
    this.toDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
    );
  }
}

/// Advance detail response
class AdvanceDetailResponse {
  final EmployeeAdvance advance;
  final EmployeeInfo employee;
  final ExpenseInfo? expenseEntry;

  AdvanceDetailResponse({
    required this.advance,
    required this.employee,
    this.expenseEntry,
  });

  factory AdvanceDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return AdvanceDetailResponse(
      advance: EmployeeAdvance.fromJson(data),
      employee: EmployeeInfo.fromJson(data['employee'] ?? {}),
      expenseEntry: data['expense_entry'] != null
          ? ExpenseInfo.fromJson(data['expense_entry'])
          : null,
    );
  }
}

/// Employee basic info
class EmployeeInfo {
  final String employeeId;
  final String employeeName;
  final String? tamilName;
  final String? contact;

  EmployeeInfo({
    required this.employeeId,
    required this.employeeName,
    this.tamilName,
    this.contact,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      tamilName: json['tamil_name']?.toString(),
      contact: json['contact']?.toString(),
    );
  }
}

/// Expense entry info
class ExpenseInfo {
  final String? expenseId;
  final String? category;
  final double? amount;

  ExpenseInfo({
    this.expenseId,
    this.category,
    this.amount,
  });

  factory ExpenseInfo.fromJson(Map<String, dynamic> json) {
    return ExpenseInfo(
      expenseId: json['expense_id']?.toString(),
      category: json['category']?.toString(),
      amount: json['amount'] != null ? _parseDouble(json['amount']) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
