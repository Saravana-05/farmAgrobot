import 'package:flutter/material.dart';

/// Daily attendance record for all employees
class Attendance {
  final String? id;
  final DateTime date;
  final int totalEmployeesPresent;
  final String? remarks;
  final bool isProcessed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<EmployeeAttendance>? employeeAttendances;

  Attendance({
    this.id,
    required this.date,
    required this.totalEmployeesPresent,
    this.remarks,
    required this.isProcessed,
    this.createdAt,
    this.updatedAt,
    this.employeeAttendances,
  });

  /// Create Attendance from JSON (API response)
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id']?.toString(),
      date: DateTime.parse(json['date']),
      totalEmployeesPresent: json['total_employees_present'] ?? 0,
      remarks: json['remarks'],
      isProcessed: json['is_processed'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      employeeAttendances: json['employee_attendances'] != null
          ? (json['employee_attendances'] as List)
              .map((e) => EmployeeAttendance.fromJson(e))
              .toList()
          : null,
    );
  }

  /// Convert Attendance to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'total_employees_present': totalEmployeesPresent,
      'remarks': remarks,
      'is_processed': isProcessed,
    };
  }

  /// Create a copy of Attendance with updated fields
  Attendance copyWith({
    String? id,
    DateTime? date,
    int? totalEmployeesPresent,
    String? remarks,
    bool? isProcessed,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EmployeeAttendance>? employeeAttendances,
  }) {
    return Attendance(
      id: id ?? this.id,
      date: date ?? this.date,
      totalEmployeesPresent: totalEmployeesPresent ?? this.totalEmployeesPresent,
      remarks: remarks ?? this.remarks,
      isProcessed: isProcessed ?? this.isProcessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeAttendances: employeeAttendances ?? this.employeeAttendances,
    );
  }

  /// Get formatted date
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Get formatted date with day name
  String get formattedDateWithDay {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[date.weekday - 1];
    return '$dayName, $formattedDate';
  }

  /// Check if attendance is for today
  bool get isToday {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  /// Check if attendance has remarks
  bool get hasRemarks {
    return remarks != null && remarks!.isNotEmpty;
  }

  /// Get display remarks or default text
  String get displayRemarks {
    return hasRemarks ? remarks! : 'No remarks';
  }

  @override
  String toString() {
    return 'Attendance{date: $date, totalPresent: $totalEmployeesPresent, isProcessed: $isProcessed}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attendance &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Individual employee attendance for each day
class EmployeeAttendance {
  final String? id;
  final String attendanceId;
  final String employeeId;
  final String employeeName;
  final AttendanceStatus status;
  final double hoursWorked;
  final double overtimeHours;
  final double dailyWageAmount;
  final double overtimeAmount;
  final double totalAmount;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeAttendance({
    this.id,
    required this.attendanceId,
    required this.employeeId,
    required this.employeeName,
    required this.status,
    required this.hoursWorked,
    required this.overtimeHours,
    required this.dailyWageAmount,
    required this.overtimeAmount,
    required this.totalAmount,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  /// Create EmployeeAttendance from JSON (API response)
  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendance(
      id: json['id']?.toString(),
      attendanceId: json['attendance_id']?.toString() ?? json['attendance']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? json['employee']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      status: _parseAttendanceStatus(json['status']),
      hoursWorked: _parseDouble(json['hours_worked']) ?? 8.0,
      overtimeHours: _parseDouble(json['overtime_hours']) ?? 0.0,
      dailyWageAmount: _parseDouble(json['daily_wage_amount']) ?? 0.0,
      overtimeAmount: _parseDouble(json['overtime_amount']) ?? 0.0,
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      remarks: json['remarks'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  /// Helper method to parse attendance status
  static AttendanceStatus _parseAttendanceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'half_day':
        return AttendanceStatus.halfDay;
      case 'overtime':
        return AttendanceStatus.overtime;
      case 'leave':
        return AttendanceStatus.leave;
      default:
        return AttendanceStatus.absent;
    }
  }

  /// Helper method to parse double from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
    
    return null;
  }

  /// Convert EmployeeAttendance to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'status': status.value,
      'hours_worked': hoursWorked,
      'overtime_hours': overtimeHours,
      'daily_wage_amount': dailyWageAmount,
      'overtime_amount': overtimeAmount,
      'total_amount': totalAmount,
      'remarks': remarks,
    };
  }

  /// Create a copy of EmployeeAttendance with updated fields
  EmployeeAttendance copyWith({
    String? id,
    String? attendanceId,
    String? employeeId,
    String? employeeName,
    AttendanceStatus? status,
    double? hoursWorked,
    double? overtimeHours,
    double? dailyWageAmount,
    double? overtimeAmount,
    double? totalAmount,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeAttendance(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      status: status ?? this.status,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      dailyWageAmount: dailyWageAmount ?? this.dailyWageAmount,
      overtimeAmount: overtimeAmount ?? this.overtimeAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted daily wage amount
  String get formattedDailyWage {
    return '₹${dailyWageAmount.toStringAsFixed(2)}';
  }

  /// Get formatted overtime amount
  String get formattedOvertimeAmount {
    return '₹${overtimeAmount.toStringAsFixed(2)}';
  }

  /// Get formatted total amount
  String get formattedTotalAmount {
    return '₹${totalAmount.toStringAsFixed(2)}';
  }

  /// Get clean formatted amounts (without decimals if whole number)
  String get formattedDailyWageClean {
    if (dailyWageAmount == dailyWageAmount.roundToDouble()) {
      return '₹${dailyWageAmount.toInt()}';
    }
    return '₹${dailyWageAmount.toStringAsFixed(2)}';
  }

  String get formattedTotalAmountClean {
    if (totalAmount == totalAmount.roundToDouble()) {
      return '₹${totalAmount.toInt()}';
    }
    return '₹${totalAmount.toStringAsFixed(2)}';
  }

  /// Check if employee has overtime
  bool get hasOvertime {
    return overtimeHours > 0;
  }

  /// Check if attendance has remarks
  bool get hasRemarks {
    return remarks != null && remarks!.isNotEmpty;
  }

  /// Get display remarks or default text
  String get displayRemarks {
    return hasRemarks ? remarks! : 'No remarks';
  }

  /// Get status color
  Color get statusColor {
    return status.color;
  }

  /// Get status icon
  IconData get statusIcon {
    return status.icon;
  }

  /// Get status display text
  String get statusText {
    return status.displayName;
  }

  /// Validate employee attendance data
  List<String> validate() {
    final errors = <String>[];
    
    if (employeeId.isEmpty) {
      errors.add('Employee ID is required');
    }
    
    if (hoursWorked < 0) {
      errors.add('Hours worked cannot be negative');
    }
    
    if (overtimeHours < 0) {
      errors.add('Overtime hours cannot be negative');
    }
    
    if (dailyWageAmount < 0) {
      errors.add('Daily wage amount cannot be negative');
    }
    
    return errors;
  }

  /// Check if attendance data is valid
  bool get isValid {
    return validate().isEmpty;
  }

  @override
  String toString() {
    return 'EmployeeAttendance{employeeName: $employeeName, status: $status, totalAmount: $totalAmount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAttendance &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Attendance status enumeration
enum AttendanceStatus {
  present('present', 'Present', Colors.green, Icons.check_circle),
  absent('absent', 'Absent', Colors.red, Icons.cancel),
  halfDay('half_day', 'Half Day', Colors.orange, Icons.schedule),
  overtime('overtime', 'Overtime', Colors.blue, Icons.work),
  leave('leave', 'Leave', Colors.purple, Icons.event_busy);

  const AttendanceStatus(this.value, this.displayName, this.color, this.icon);

  final String value;
  final String displayName;
  final Color color;
  final IconData icon;

  /// Get status from string value
  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AttendanceStatus.absent,
    );
  }

  /// Get all status options for dropdowns
  static List<AttendanceStatus> get allStatuses => AttendanceStatus.values;

  /// Get present statuses (for counting)
  static List<AttendanceStatus> get presentStatuses => [
    AttendanceStatus.present,
    AttendanceStatus.halfDay,
    AttendanceStatus.overtime,
  ];

  /// Check if status counts as present
  bool get isPresent => presentStatuses.contains(this);

  /// Check if status allows overtime
  bool get allowsOvertime => this == AttendanceStatus.overtime;
}

/// Employee wage summary model
class EmployeeWageSummary {
  final String? id;
  final String employeeId;
  final String employeeName;
  final PeriodType periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalDaysPresent;
  final int totalDaysAbsent;
  final int totalHalfDays;
  final double totalOvertimeHours;
  final double totalWageAmount;
  final double totalOvertimeAmount;
  final double bonusAmount;
  final double deductionAmount;
  final double grossAmount;
  final double netAmount;
  final double paidAmount;
  final double pendingAmount;
  final PaymentStatus paymentStatus;
  final bool isProcessed;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeWageSummary({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.totalDaysPresent,
    required this.totalDaysAbsent,
    required this.totalHalfDays,
    required this.totalOvertimeHours,
    required this.totalWageAmount,
    required this.totalOvertimeAmount,
    required this.bonusAmount,
    required this.deductionAmount,
    required this.grossAmount,
    required this.netAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paymentStatus,
    required this.isProcessed,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  /// Create EmployeeWageSummary from JSON
  factory EmployeeWageSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeWageSummary(
      id: json['id']?.toString(),
      employeeId: json['employee_id']?.toString() ?? json['employee']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      periodType: PeriodType.fromString(json['period_type'] ?? 'weekly'),
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      totalDaysPresent: json['total_days_present'] ?? 0,
      totalDaysAbsent: json['total_days_absent'] ?? 0,
      totalHalfDays: json['total_half_days'] ?? 0,
      totalOvertimeHours: EmployeeAttendance._parseDouble(json['total_overtime_hours']) ?? 0.0,
      totalWageAmount: EmployeeAttendance._parseDouble(json['total_wage_amount']) ?? 0.0,
      totalOvertimeAmount: EmployeeAttendance._parseDouble(json['total_overtime_amount']) ?? 0.0,
      bonusAmount: EmployeeAttendance._parseDouble(json['bonus_amount']) ?? 0.0,
      deductionAmount: EmployeeAttendance._parseDouble(json['deduction_amount']) ?? 0.0,
      grossAmount: EmployeeAttendance._parseDouble(json['gross_amount']) ?? 0.0,
      netAmount: EmployeeAttendance._parseDouble(json['net_amount']) ?? 0.0,
      paidAmount: EmployeeAttendance._parseDouble(json['paid_amount']) ?? 0.0,
      pendingAmount: EmployeeAttendance._parseDouble(json['pending_amount']) ?? 0.0,
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
      isProcessed: json['is_processed'] ?? false,
      remarks: json['remarks'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// Get formatted period
  String get formattedPeriod {
    return '${periodStart.day.toString().padLeft(2, '0')}/'
           '${periodStart.month.toString().padLeft(2, '0')}/'
           '${periodStart.year} - '
           '${periodEnd.day.toString().padLeft(2, '0')}/'
           '${periodEnd.month.toString().padLeft(2, '0')}/'
           '${periodEnd.year}';
  }

  /// Get formatted amounts
  String get formattedNetAmount {
    return '₹${netAmount.toStringAsFixed(2)}';
  }

  String get formattedPaidAmount {
    return '₹${paidAmount.toStringAsFixed(2)}';
  }

  String get formattedPendingAmount {
    return '₹${pendingAmount.toStringAsFixed(2)}';
  }

  /// Get total working days
  int get totalWorkingDays {
    return totalDaysPresent + totalDaysAbsent + totalHalfDays;
  }

  /// Get attendance percentage
  double get attendancePercentage {
    if (totalWorkingDays == 0) return 0.0;
    return (totalDaysPresent + (totalHalfDays * 0.5)) / totalWorkingDays * 100;
  }

  /// Get formatted attendance percentage
  String get formattedAttendancePercentage {
    return '${attendancePercentage.toStringAsFixed(1)}%';
  }
}

/// Period type enumeration
enum PeriodType {
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  custom('custom', 'Custom Period');

  const PeriodType(this.value, this.displayName);

  final String value;
  final String displayName;

  static PeriodType fromString(String value) {
    return PeriodType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PeriodType.weekly,
    );
  }
}

/// Payment status enumeration
enum PaymentStatus {
  pending('pending', 'Pending', Colors.orange, Icons.schedule),
  partial('partial', 'Partially Paid', Colors.blue, Icons.payment),
  paid('paid', 'Fully Paid', Colors.green, Icons.check_circle),
  cancelled('cancelled', 'Cancelled', Colors.red, Icons.cancel);

  const PaymentStatus(this.value, this.displayName, this.color, this.icon);

  final String value;
  final String displayName;
  final Color color;
  final IconData icon;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Wage payment model
class WagePayment {
  final String? id;
  final String wageSummaryId;
  final DateTime paymentDate;
  final double amount;
  final PaymentMode paymentMode;
  final String? referenceNumber;
  final String paidBy;
  final String? remarks;
  final String? receiptUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WagePayment({
    this.id,
    required this.wageSummaryId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paidBy,
    this.remarks,
    this.receiptUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Create WagePayment from JSON
  factory WagePayment.fromJson(Map<String, dynamic> json) {
    return WagePayment(
      id: json['id']?.toString(),
      wageSummaryId: json['wage_summary_id']?.toString() ?? json['wage_summary']?.toString() ?? '',
      paymentDate: DateTime.parse(json['payment_date']),
      amount: EmployeeAttendance._parseDouble(json['amount']) ?? 0.0,
      paymentMode: PaymentMode.fromString(json['payment_mode'] ?? 'cash'),
      referenceNumber: json['reference_number'],
      paidBy: json['paid_by'] ?? '',
      remarks: json['remarks'],
      receiptUrl: json['receipt_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// Get formatted payment date
  String get formattedPaymentDate {
    return '${paymentDate.day.toString().padLeft(2, '0')}/'
           '${paymentDate.month.toString().padLeft(2, '0')}/'
           '${paymentDate.year}';
  }

  /// Get formatted amount
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }
}

/// Payment mode enumeration
enum PaymentMode {
  cash('cash', 'Cash', Icons.money),
  bankTransfer('bank_transfer', 'Bank Transfer', Icons.account_balance),
  upi('upi', 'UPI', Icons.qr_code),
  cheque('cheque', 'Cheque', Icons.receipt),
  card('card', 'Card', Icons.credit_card);

  const PaymentMode(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => PaymentMode.cash,
    );
  }
}