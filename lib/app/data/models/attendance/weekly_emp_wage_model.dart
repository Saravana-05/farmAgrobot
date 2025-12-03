class WeeklyEmployeeWage {
  final String employeeId;
  final String employeeName;
  final String? tamilName;
  final double dailyWage;
  final Map<String, dynamic> attendance;
  final int presentDays;
  final int halfDays;
  final double grossWages;
  final double advanceDeduction;
  final double netWages;
  final String paymentStatus;
  final double partialPayment;
  final double remainingAmount;
  final bool hasAdvanceDeduction;
  final List<AdvanceApplied> advancesApplied;

  WeeklyEmployeeWage({
    required this.employeeId,
    required this.employeeName,
    this.tamilName,
    required this.dailyWage,
    required this.attendance,
    required this.presentDays,
    required this.halfDays,
    required this.grossWages,
    this.advanceDeduction = 0.0,
    required this.netWages,
    required this.paymentStatus,
    this.partialPayment = 0.0,
    this.remainingAmount = 0.0,
    this.hasAdvanceDeduction = false,
    this.advancesApplied = const [],
  });

  factory WeeklyEmployeeWage.fromJson(Map<String, dynamic> json) {
    List<AdvanceApplied> advances = [];
    if (json['advances_applied'] != null && json['advances_applied'] is List) {
      advances = (json['advances_applied'] as List)
          .map((e) => AdvanceApplied.fromJson(e))
          .toList();
    }

    return WeeklyEmployeeWage(
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      tamilName: json['tamil_name']?.toString(),
      dailyWage: _parseDouble(json['daily_wage']),
      attendance: json['attendance'] ?? {},
      presentDays: json['present_days'] ?? 0,
      halfDays: json['half_days'] ?? 0,
      grossWages: _parseDouble(json['gross_wages']),
      advanceDeduction: _parseDouble(json['advance_deduction']),
      netWages: _parseDouble(json['net_wages']),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      partialPayment: _parseDouble(json['partial_payment']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      hasAdvanceDeduction: json['has_advance_deduction'] ?? false,
      advancesApplied: advances,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get hasAdvance => hasAdvanceDeduction && advanceDeduction > 0;
  double get totalWages => netWages; // For backward compatibility
}

/// Model for advance deduction details
class AdvanceApplied {
  final String advanceId;
  final DateTime advanceDate;
  final double originalAmount;
  final double remainingBefore;
  final double deductionAmount;
  final double remainingAfter;

  AdvanceApplied({
    required this.advanceId,
    required this.advanceDate,
    required this.originalAmount,
    required this.remainingBefore,
    required this.deductionAmount,
    required this.remainingAfter,
  });

  factory AdvanceApplied.fromJson(Map<String, dynamic> json) {
    return AdvanceApplied(
      advanceId: json['advance_id']?.toString() ?? '',
      advanceDate: DateTime.parse(json['advance_date']),
      originalAmount: _parseDouble(json['original_amount']),
      remainingBefore: _parseDouble(json['remaining_before']),
      deductionAmount: _parseDouble(json['deduction_amount']),
      remainingAfter: _parseDouble(json['remaining_after']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get isFullyDeducted => remainingAfter == 0;
}

/// Weekly data response with advance information
class WeeklyDataResponse {
  final String weekStartDate;
  final String weekEndDate;
  final List<WeeklyEmployeeWage> employees;
  final Map<String, int> dailyCounts;
  final double totalGrossWages;
  final double totalAdvanceDeductions;
  final double totalNetWages;
  final bool wagesPaid;
  final String paymentType;
  final int weeklyEmployeeCount;
  final bool advanceDeductionsApplied;
  final WageRecordInfo? wageRecordInfo;

  WeeklyDataResponse({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.employees,
    required this.dailyCounts,
    required this.totalGrossWages,
    this.totalAdvanceDeductions = 0.0,
    required this.totalNetWages,
    required this.wagesPaid,
    required this.paymentType,
    required this.weeklyEmployeeCount,
    this.advanceDeductionsApplied = false,
    this.wageRecordInfo,
  });

  factory WeeklyDataResponse.fromJson(Map<String, dynamic> json) {
    List<WeeklyEmployeeWage> employees = [];
    if (json['employees'] != null && json['employees'] is List) {
      employees = (json['employees'] as List)
          .map((e) => WeeklyEmployeeWage.fromJson(e))
          .toList();
    }

    Map<String, int> dailyCounts = {};
    if (json['daily_counts'] != null && json['daily_counts'] is Map) {
      final counts = json['daily_counts'] as Map;
      counts.forEach((key, value) {
        dailyCounts[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return WeeklyDataResponse(
      weekStartDate: json['week_start_date']?.toString() ?? '',
      weekEndDate: json['week_end_date']?.toString() ?? '',
      employees: employees,
      dailyCounts: dailyCounts,
      totalGrossWages: _parseDouble(json['total_gross_wages']),
      totalAdvanceDeductions: _parseDouble(json['total_advance_deductions']),
      totalNetWages: _parseDouble(json['total_net_wages']),
      wagesPaid: json['wages_paid'] ?? false,
      paymentType: json['payment_type']?.toString() ?? 'none',
      weeklyEmployeeCount: json['weekly_employee_count'] ?? 0,
      advanceDeductionsApplied: json['advance_deductions_applied'] ?? false,
      wageRecordInfo: json['wage_record_info'] != null
          ? WageRecordInfo.fromJson(json['wage_record_info'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int get employeesWithAdvances => employees.where((e) => e.hasAdvance).length;
  double get totalAdvanceSavings => totalAdvanceDeductions;
}

/// Wage record info
class WageRecordInfo {
  final String id;
  final String paymentStatus;
  final int totalEmployees;
  final double totalGrossAmount;
  final double totalAdvanceDeductions;
  final double totalNetAmount;
  final double totalPaidAmount;
  final double totalRemainingAmount;
  final String dataStructure;

  WageRecordInfo({
    required this.id,
    required this.paymentStatus,
    required this.totalEmployees,
    required this.totalGrossAmount,
    this.totalAdvanceDeductions = 0.0,
    required this.totalNetAmount,
    required this.totalPaidAmount,
    required this.totalRemainingAmount,
    required this.dataStructure,
  });

  factory WageRecordInfo.fromJson(Map<String, dynamic> json) {
    return WageRecordInfo(
      id: json['id']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      totalEmployees: json['total_employees'] ?? 0,
      totalGrossAmount: _parseDouble(json['total_gross_amount']),
      totalAdvanceDeductions: _parseDouble(json['total_advance_deductions']),
      totalNetAmount: _parseDouble(json['total_net_amount']),
      totalPaidAmount: _parseDouble(json['total_paid_amount']),
      totalRemainingAmount: _parseDouble(json['total_remaining_amount']),
      dataStructure: json['data_structure']?.toString() ?? '',
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