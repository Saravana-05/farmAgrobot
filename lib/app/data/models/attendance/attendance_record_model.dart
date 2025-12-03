class EmployeeAttendanceRecord {
  final String id;
  final String name;
  final String? tamilName;
  final String? profileImageUrl;  
  final double dailyWage;
  final bool hasWage;
  final bool status;

  EmployeeAttendanceRecord({
    required this.id,
    required this.name,
    this.tamilName,
    this.profileImageUrl,  
    required this.dailyWage,
    required this.hasWage,
    this.status = true,
  });

  factory EmployeeAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceRecord(
      id: json['employee_id'].toString(),
      name: json['employee_name'] ?? '',
      tamilName: json['tamil_name'],
      profileImageUrl: json['profile_image_url'],  
      dailyWage: (json['daily_wage'] ?? 0).toDouble(),
      hasWage: json['has_wage'] ?? false,
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': id,
      'employee_name': name,
      'tamil_name': tamilName,
      'profile_image_url': profileImageUrl,  
      'daily_wage': dailyWage,
      'has_wage': hasWage,
      'status': status,
    };
  }
}

class AttendanceData {
  final String employeeId;
  final String employeeName;
  final Map<String, int?> attendance; // date -> status
  final int presentDays;
  final int halfDays;
  final double totalWages;
  final String paymentStatus;
  final double partialPayment;
  final double remainingAmount;
  final double dailyWage;

  AttendanceData({
    required this.employeeId,
    required this.employeeName,
    required this.attendance,
    required this.presentDays,
    required this.halfDays,
    required this.totalWages,
    required this.dailyWage,
    this.paymentStatus = 'pending',
    this.partialPayment = 0.0,
    this.remainingAmount = 0.0,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    print('=== AttendanceData.fromJson DEBUG ===');
    print('Input JSON: $json');
    print('Employee ID: ${json['employee_id']}');
    print('Employee Name: ${json['employee_name']}');

    Map<String, int?> attendanceMap = {};
    if (json['attendance'] != null) {
      print('Attendance data exists: ${json['attendance']}');
      Map<String, dynamic> attendance = json['attendance'];
      attendance.forEach((date, value) {
        // Handle different value types from API
        if (value == null) {
          attendanceMap[date] = null;
        } else if (value is int) {
          attendanceMap[date] = value;
        } else if (value is String) {
          attendanceMap[date] = int.tryParse(value);
        } else if (value is Map) {
          // API returns attendance as object with 'status' field
          final statusValue = value['status'];
          if (statusValue == null) {
            attendanceMap[date] = null;
          } else if (statusValue is int) {
            attendanceMap[date] = statusValue;
          } else if (statusValue is String) {
            attendanceMap[date] = int.tryParse(statusValue);
          } else if (statusValue is double) {
            attendanceMap[date] = statusValue.toInt();
          }
        } else if (value is double) {
          attendanceMap[date] = value.toInt();
        }
      });
      print('Parsed attendance entries: ${attendanceMap.length}');
    }

    final result = AttendanceData(
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'] ?? '',
      attendance: attendanceMap,
      presentDays: json['present_days'] ?? 0,
      halfDays: json['half_days'] ?? 0,
      totalWages: (json['total_wages'] ?? 0).toDouble(),
      dailyWage: (json['daily_wage'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'pending',
      partialPayment: (json['partial_payment'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
    );

    print('✅ AttendanceData created for: ${result.employeeName}');
    print('   Payment Status: ${result.paymentStatus}');
    print('   Partial Payment: ₹${result.partialPayment}');
    print('   Remaining: ₹${result.remainingAmount}');
    return result;
  }
}

class WeeklyData {
  final String weekStartDate;
  final String weekEndDate;
  final List<AttendanceData> employees;
  final Map<String, int> dailyCounts;
  final double totalWages;
  final bool wagesPaid;
  final int weeklyEmployeeCount;

  WeeklyData({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.employees,
    required this.dailyCounts,
    required this.totalWages,
    required this.wagesPaid,
    required this.weeklyEmployeeCount,
  });

  factory WeeklyData.fromJson(Map<String, dynamic> json) {
    print('=== WeeklyData.fromJson START ===');
    print('Input JSON keys: ${json.keys}');

    // Parse employees
    List<AttendanceData> employees = [];
    if (json['employees'] != null && json['employees'] is List) {
      List employeesList = json['employees'] as List;
      print('Processing ${employeesList.length} employees...');

      for (int i = 0; i < employeesList.length; i++) {
        try {
          final attendanceData = AttendanceData.fromJson(employeesList[i]);
          employees.add(attendanceData);
        } catch (e, stackTrace) {
          print('❌ Error parsing employee $i: $e');
          print('Stack trace: $stackTrace');
        }
      }
    }

    print('✅ Successfully parsed ${employees.length} employees');

    // Parse daily counts
    Map<String, int> dailyCounts = {};
    if (json['daily_counts'] != null && json['daily_counts'] is Map) {
      Map<String, dynamic> counts = json['daily_counts'];
      counts.forEach((date, count) {
        dailyCounts[date] =
            count is int ? count : int.tryParse(count.toString()) ?? 0;
      });
    }

    final result = WeeklyData(
      weekStartDate: json['week_start_date']?.toString() ?? '',
      weekEndDate: json['week_end_date']?.toString() ?? '',
      employees: employees,
      dailyCounts: dailyCounts,
      totalWages: _parseDoubleFromJson(json['total_wages']) ?? 0.0,
      wagesPaid: json['wages_paid'] ?? false,
      weeklyEmployeeCount: json['weekly_employee_count'] ?? 0,
    );

    print('=== WeeklyData.fromJson COMPLETE ===');
    print('Total employees: ${result.employees.length}');
    print('Total wages: ₹${result.totalWages}');
    print('Wages paid: ${result.wagesPaid}');
    print('Weekly employee count: ${result.weeklyEmployeeCount}');

    // Print payment summary from employees
    int paidCount = 0;
    int partialCount = 0;
    int pendingCount = 0;
    double totalPaid = 0;
    double totalRemaining = 0;

    for (var emp in result.employees) {
      switch (emp.paymentStatus) {
        case 'paid':
          paidCount++;
          break;
        case 'partial':
          partialCount++;
          break;
        default:
          pendingCount++;
      }
      totalPaid += emp.partialPayment;
      totalRemaining += emp.remainingAmount;
    }

    print('\n📊 Payment Summary:');
    print('  Fully Paid: $paidCount');
    print('  Partially Paid: $partialCount');
    print('  Pending: $pendingCount');
    print('  Total Paid: ₹$totalPaid');
    print('  Total Remaining: ₹$totalRemaining');

    return result;
  }

  /// Helper method to safely parse double values
  static double? _parseDoubleFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'week_start_date': weekStartDate,
      'week_end_date': weekEndDate,
      'employees': employees
          .map((e) => {
                'employee_id': e.employeeId,
                'employee_name': e.employeeName,
                'daily_wage': e.dailyWage,
                'attendance': e.attendance,
                'present_days': e.presentDays,
                'half_days': e.halfDays,
                'total_wages': e.totalWages,
                'payment_status': e.paymentStatus,
                'partial_payment': e.partialPayment,
                'remaining_amount': e.remainingAmount,
              })
          .toList(),
      'daily_counts': dailyCounts,
      'total_wages': totalWages,
      'wages_paid': wagesPaid,
      'weekly_employee_count': weeklyEmployeeCount,
    };
  }
}

class AttendanceRecord {
  final String date;
  final int totalEmployees;
  final AttendanceSummary summary;
  final List<EmployeeAttendance> attendanceData;

  AttendanceRecord({
    required this.date,
    required this.totalEmployees,
    required this.summary,
    required this.attendanceData,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      summary: AttendanceSummary.fromJson(json['attendance_summary'] ?? {}),
      attendanceData: (json['attendance_data'] as List<dynamic>? ?? [])
          .map((e) => EmployeeAttendance.fromJson(e))
          .toList(),
    );
  }
}

class EmployeeAttendance {
  final String employeeId;
  final String employeeName;
  final int status;
  final double wageAmount;

  EmployeeAttendance({
    required this.employeeId,
    required this.employeeName,
    required this.status,
    required this.wageAmount,
  });

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendance(
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'] ?? '',
      status: json['status'] ?? 0,
      wageAmount: (json['wage_amount'] ?? 0).toDouble(),
    );
  }

  /// 🔥 Add this method
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'status': status,
      'wage_amount': wageAmount,
    };
  }
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int halfDay;
  final double totalWages;

  AttendanceSummary({
    required this.present,
    required this.absent,
    required this.halfDay,
    required this.totalWages,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      halfDay: json['half_day'] ?? 0,
      totalWages: (json['total_wages'] ?? 0).toDouble(),
    );
  }
}

class WagePaymentRequest {
  final String? employeeId;
  final double amount;
  final String paymentMode;
  final String? paymentReference;
  final String? remarks;
  final String weekStart;
  final bool payAll;

  WagePaymentRequest({
    this.employeeId,
    required this.amount,
    this.paymentMode = 'Cash',
    this.paymentReference,
    this.remarks,
    required this.weekStart,
    this.payAll = false,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'week_start': weekStart,
      'pay_all': payAll,
      'payment_mode': paymentMode,
    };

    if (!payAll) {
      data.addAll({
        'employee_id': employeeId,
        'amount': amount,
        if (paymentReference != null) 'payment_reference': paymentReference,
        if (remarks != null) 'remarks': remarks,
      });
    }

    return data;
  }
}

class WageSummary {
  final String weekStartDate;
  final int totalEmployees;
  final double totalGrossWages;
  final double totalPaidAmount;
  final double totalRemainingAmount;
  final int fullyPaidCount;
  final int partiallyPaidCount;
  final int pendingCount;
  final List<WagePaymentDetail> payments;

  WageSummary({
    required this.weekStartDate,
    required this.totalEmployees,
    required this.totalGrossWages,
    required this.totalPaidAmount,
    required this.totalRemainingAmount,
    required this.fullyPaidCount,
    required this.partiallyPaidCount,
    required this.pendingCount,
    required this.payments,
  });

  factory WageSummary.fromJson(Map<String, dynamic> json) {
    List<WagePaymentDetail> payments = [];
    if (json['payments'] != null) {
      payments = (json['payments'] as List)
          .map((e) => WagePaymentDetail.fromJson(e))
          .toList();
    }

    return WageSummary(
      weekStartDate: json['week_start_date'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      totalGrossWages: (json['total_gross_wages'] ?? 0).toDouble(),
      totalPaidAmount: (json['total_paid_amount'] ?? 0).toDouble(),
      totalRemainingAmount: (json['total_remaining_amount'] ?? 0).toDouble(),
      fullyPaidCount: json['fully_paid_count'] ?? 0,
      partiallyPaidCount: json['partially_paid_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      payments: payments,
    );
  }
}

class WagePaymentDetail {
  final String employeeId;
  final String employeeName;
  final int presentDays;
  final int halfDays;
  final double dailyWage;
  final double grossAmount;
  final double netAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;

  WagePaymentDetail({
    required this.employeeId,
    required this.employeeName,
    required this.presentDays,
    required this.halfDays,
    required this.dailyWage,
    required this.grossAmount,
    required this.netAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
  });

  factory WagePaymentDetail.fromJson(Map<String, dynamic> json) {
    return WagePaymentDetail(
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'] ?? '',
      presentDays: json['present_days'] ?? 0,
      halfDays: json['half_days'] ?? 0,
      dailyWage: (json['daily_wage'] ?? 0).toDouble(),
      grossAmount: (json['gross_amount'] ?? 0).toDouble(),
      netAmount: (json['net_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'pending',
    );
  }
}

class AttendanceExport {
  final List<ExportRecord> data;
  final String fromDate;
  final String toDate;
  final int totalRecords;

  AttendanceExport({
    required this.data,
    required this.fromDate,
    required this.toDate,
    required this.totalRecords,
  });

  factory AttendanceExport.fromJson(Map<String, dynamic> json) {
    List<ExportRecord> data = [];
    if (json['data'] != null) {
      data =
          (json['data'] as List).map((e) => ExportRecord.fromJson(e)).toList();
    }

    return AttendanceExport(
      data: data,
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      totalRecords: json['total_records'] ?? 0,
    );
  }
}

class ExportRecord {
  final String date;
  final String employeeId;
  final String employeeName;
  final String status;
  final double wageAmount;

  ExportRecord({
    required this.date,
    required this.employeeId,
    required this.employeeName,
    required this.status,
    required this.wageAmount,
  });

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      date: json['date'] ?? '',
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'] ?? '',
      status: json['status'] ?? '',
      wageAmount: (json['wage_amount'] ?? 0).toDouble(),
    );
  }
}

// API Response models
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}

class AttendanceStatistics {
  final String fromDate;
  final String toDate;
  final int totalEmployees;
  final int totalWorkingDays;
  final double totalPossibleAttendance;
  final double actualAttendance;
  final double attendancePercentage;
  final AttendanceBreakdown breakdown;
  final List<DailyStatistics> dailyStats;
  final List<EmployeeStatistics> employeeStats;

  AttendanceStatistics({
    required this.fromDate,
    required this.toDate,
    required this.totalEmployees,
    required this.totalWorkingDays,
    required this.totalPossibleAttendance,
    required this.actualAttendance,
    required this.attendancePercentage,
    required this.breakdown,
    required this.dailyStats,
    required this.employeeStats,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    List<DailyStatistics> dailyStats = [];
    if (json['daily_stats'] != null) {
      dailyStats = (json['daily_stats'] as List)
          .map((e) => DailyStatistics.fromJson(e))
          .toList();
    }

    List<EmployeeStatistics> employeeStats = [];
    if (json['employee_stats'] != null) {
      employeeStats = (json['employee_stats'] as List)
          .map((e) => EmployeeStatistics.fromJson(e))
          .toList();
    }

    return AttendanceStatistics(
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      totalWorkingDays: json['total_working_days'] ?? 0,
      totalPossibleAttendance:
          (json['total_possible_attendance'] ?? 0).toDouble(),
      actualAttendance: (json['actual_attendance'] ?? 0).toDouble(),
      attendancePercentage: (json['attendance_percentage'] ?? 0).toDouble(),
      breakdown: AttendanceBreakdown.fromJson(json['breakdown'] ?? {}),
      dailyStats: dailyStats,
      employeeStats: employeeStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_date': fromDate,
      'to_date': toDate,
      'total_employees': totalEmployees,
      'total_working_days': totalWorkingDays,
      'total_possible_attendance': totalPossibleAttendance,
      'actual_attendance': actualAttendance,
      'attendance_percentage': attendancePercentage,
      'breakdown': breakdown.toJson(),
      'daily_stats': dailyStats.map((e) => e.toJson()).toList(),
      'employee_stats': employeeStats.map((e) => e.toJson()).toList(),
    };
  }
}

class AttendanceBreakdown {
  final int totalPresent;
  final int totalAbsent;
  final int totalHalfDay;
  final int totalLate;
  final double presentPercentage;
  final double absentPercentage;
  final double halfDayPercentage;
  final double latePercentage;

  AttendanceBreakdown({
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalHalfDay,
    required this.totalLate,
    required this.presentPercentage,
    required this.absentPercentage,
    required this.halfDayPercentage,
    required this.latePercentage,
  });

  factory AttendanceBreakdown.fromJson(Map<String, dynamic> json) {
    return AttendanceBreakdown(
      totalPresent: json['total_present'] ?? 0,
      totalAbsent: json['total_absent'] ?? 0,
      totalHalfDay: json['total_half_day'] ?? 0,
      totalLate: json['total_late'] ?? 0,
      presentPercentage: (json['present_percentage'] ?? 0).toDouble(),
      absentPercentage: (json['absent_percentage'] ?? 0).toDouble(),
      halfDayPercentage: (json['half_day_percentage'] ?? 0).toDouble(),
      latePercentage: (json['late_percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_present': totalPresent,
      'total_absent': totalAbsent,
      'total_half_day': totalHalfDay,
      'total_late': totalLate,
      'present_percentage': presentPercentage,
      'absent_percentage': absentPercentage,
      'half_day_percentage': halfDayPercentage,
      'late_percentage': latePercentage,
    };
  }
}

class DailyStatistics {
  final String date;
  final int totalEmployees;
  final int present;
  final int absent;
  final int halfDay;
  final int late;
  final double attendancePercentage;
  final double totalWages;

  DailyStatistics({
    required this.date,
    required this.totalEmployees,
    required this.present,
    required this.absent,
    required this.halfDay,
    required this.late,
    required this.attendancePercentage,
    required this.totalWages,
  });

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      date: json['date'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      halfDay: json['half_day'] ?? 0,
      late: json['late'] ?? 0,
      attendancePercentage: (json['attendance_percentage'] ?? 0).toDouble(),
      totalWages: (json['total_wages'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'total_employees': totalEmployees,
      'present': present,
      'absent': absent,
      'half_day': halfDay,
      'late': late,
      'attendance_percentage': attendancePercentage,
      'total_wages': totalWages,
    };
  }
}

class EmployeeStatistics {
  final String employeeId;
  final String employeeName;
  final int totalPossibleDays;
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final int lateDays;
  final double attendancePercentage;
  final double totalWagesEarned;
  final double averageDailyWage;

  EmployeeStatistics({
    required this.employeeId,
    required this.employeeName,
    required this.totalPossibleDays,
    required this.presentDays,
    required this.absentDays,
    required this.halfDays,
    required this.lateDays,
    required this.attendancePercentage,
    required this.totalWagesEarned,
    required this.averageDailyWage,
  });

  factory EmployeeStatistics.fromJson(Map<String, dynamic> json) {
    return EmployeeStatistics(
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'] ?? '',
      totalPossibleDays: json['total_possible_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      halfDays: json['half_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      attendancePercentage: (json['attendance_percentage'] ?? 0).toDouble(),
      totalWagesEarned: (json['total_wages_earned'] ?? 0).toDouble(),
      averageDailyWage: (json['average_daily_wage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'total_possible_days': totalPossibleDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'half_days': halfDays,
      'late_days': lateDays,
      'attendance_percentage': attendancePercentage,
      'total_wages_earned': totalWagesEarned,
      'average_daily_wage': averageDailyWage,
    };
  }
}

/// Bulk payment information model
class BulkPaymentInfo {
  final int id;
  final DateTime paymentDate;
  final String paymentMode;
  final String paymentReference;
  final double totalAmount;

  BulkPaymentInfo({
    required this.id,
    required this.paymentDate,
    required this.paymentMode,
    required this.paymentReference,
    required this.totalAmount,
  });
}

class EmployeeReportData {
  final String employeeId;
  final String employeeName;
  final double dailyWage;
  final Map<String, dynamic>? periodSummary;
  final List<AttendanceDay> dailyAttendance;
  final List<WeeklyBreakdown> weeklyBreakdown;

  EmployeeReportData({
    required this.employeeId,
    required this.employeeName,
    required this.dailyWage,
    this.periodSummary,
    required this.dailyAttendance,
    required this.weeklyBreakdown,
  });
}

class AttendanceDay {
  final String date;
  final String dayName;
  final String status;
  final int? statusCode;
  final double wageEarned;

  AttendanceDay({
    required this.date,
    required this.dayName,
    required this.status,
    this.statusCode,
    required this.wageEarned,
  });

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    return AttendanceDay(
      date: json['date']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Not Marked',
      statusCode: json['status_code'] is int
          ? json['status_code']
          : (json['status_code'] != null
              ? int.tryParse(json['status_code'].toString())
              : null),
      wageEarned: _parseDoubleSafelyStatic(json['wage_earned']),
    );
  }

  static double _parseDoubleSafelyStatic(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class WeeklyBreakdown {
  final String weekStart;
  final String weekEnd;
  final int presentDays;
  final int halfDays;
  final int absentDays;
  final double totalWagesEarned;
  final double wagesPaid;
  final double wagesPending;
  final String paymentStatus;

  WeeklyBreakdown({
    required this.weekStart,
    required this.weekEnd,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.totalWagesEarned,
    required this.wagesPaid,
    required this.wagesPending,
    required this.paymentStatus,
  });

  factory WeeklyBreakdown.fromJson(Map<String, dynamic> json) {
    return WeeklyBreakdown(
      weekStart: json['week_start']?.toString() ?? '',
      weekEnd: json['week_end']?.toString() ?? '',
      presentDays: _parseIntSafelyStatic(json['present_days']),
      halfDays: _parseIntSafelyStatic(json['half_days']),
      absentDays: _parseIntSafelyStatic(json['absent_days']),
      totalWagesEarned: _parseDoubleSafelyStatic(json['total_wages_earned']),
      wagesPaid: _parseDoubleSafelyStatic(json['wages_paid']),
      wagesPending: _parseDoubleSafelyStatic(json['wages_pending']),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
    );
  }

  static int _parseIntSafelyStatic(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDoubleSafelyStatic(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
