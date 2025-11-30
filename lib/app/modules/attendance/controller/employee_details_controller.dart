import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/services/attendance/attendance_service.dart';
import '../../../data/models/attendance/attendance_record_model.dart';

class EmployeeDetailsController extends GetxController {
  // Employee basic info
  var employeeData = Rxn<EmployeeAttendanceRecord>();
  
  // Loading states
  var isLoading = false.obs;
  var isLoadingReport = false.obs;
  var isProcessingPayment = false.obs;
  
  // Employee report data
  var employeeReport = Rxn<EmployeeReportData>();
  var dailyAttendanceData = <AttendanceDay>[].obs;
  var weeklyBreakdown = <WeeklyBreakdown>[].obs;
  
  // Summary statistics
  var totalDays = 0.obs;
  var presentDays = 0.obs;
  var halfDays = 0.obs;
  var absentDays = 0.obs;
  var attendancePercentage = 0.0.obs;
  var totalWagesEarned = 0.0.obs;
  var totalWagesPaid = 0.0.obs;
  var totalWagesPending = 0.0.obs;
  var paymentPercentage = 0.0.obs;
  
  // Date range for report (default: last 28 days)
  var startDate = DateTime.now().subtract(const Duration(days: 27)).obs;
  var endDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _initializeEmployee();
  }

  /// Initialize employee data from arguments
  void _initializeEmployee() {
    try {
      final arguments = Get.arguments;
      print('Arguments received: $arguments'); // Debug log
      
      if (arguments != null) {
        // Handle different argument types
        if (arguments is EmployeeAttendanceRecord) {
          employeeData.value = arguments;
          print('Employee ID: ${arguments.id}'); // Debug log
        } else if (arguments is Map<String, dynamic>) {
          // If arguments are passed as a map
          final employeeId = arguments['employeeId'] ?? arguments['id'];
          if (employeeId != null) {
            // Create a temporary employee record if we only have ID
            employeeData.value = EmployeeAttendanceRecord(
              id: employeeId.toString(),
              name: arguments['name'] ?? 'Unknown Employee', 
              dailyWage: 0, 
              hasWage: true,
            );
          }
        } else if (arguments is String) {
          // If only ID is passed as string
          employeeData.value = EmployeeAttendanceRecord(
            id: arguments,
            name: 'Loading...', 
            dailyWage: 0, 
            hasWage: true,
          );
        }
        
        if (employeeData.value != null) {
          fetchEmployeeReport();
        } else {
          _showErrorMessage('Invalid employee data format');
          Get.back();
        }
      } else {
        _showErrorMessage('Employee data not found');
        Get.back();
      }
    } catch (e) {
      print('Error initializing employee: $e');
      _showErrorMessage('Failed to initialize employee data');
      Get.back();
    }
  }

  /// Fetch comprehensive employee report
  Future<void> fetchEmployeeReport() async {
    if (employeeData.value == null) {
      _showErrorMessage('Employee data is null');
      return;
    }
    
    final employeeId = employeeData.value!.id;
    if (employeeId.isEmpty) {
      _showErrorMessage('Employee ID is empty');
      return;
    }
    
    isLoadingReport.value = true;
    
    try {
      print('Fetching report for employee ID: $employeeId'); // Debug log
      print('Date range: ${startDate.value} to ${endDate.value}'); // Debug log
      
      final response = await AttendanceService.getSingleEmployeeReport(
        employeeId: employeeId,
        startDate: startDate.value,
        endDate: endDate.value,
      );
      
      print('API Response: $response'); // Debug log
      
      if (response != null && response is Map<String, dynamic>) {
        // Check for success flag first
        if (response['success'] == true) {
          final data = response['data'];
          if (data != null && data is Map<String, dynamic>) {
            await _processEmployeeReport(data);
            _showSuccessMessage('Employee report loaded successfully');
          } else {
            _showErrorMessage('No data received from server');
          }
        } else {
          // Handle error response
          final errorMessage = response['error']?.toString() ?? 'Unknown error occurred';
          _showErrorMessage(errorMessage);
        }
      } else {
        _showErrorMessage('Invalid response format from server');
      }
    } catch (e) {
      print('Exception in fetchEmployeeReport: $e'); // Debug log
      _handleException('Failed to fetch employee report', e);
    } finally {
      isLoadingReport.value = false;
    }
  }

  /// Process employee report data with better error handling
  Future<void> _processEmployeeReport(Map<String, dynamic> reportData) async {
    try {
      print('Processing report data: $reportData'); // Debug log
      
      // Reset all data first
      _resetReportData();
      
      // Parse summary data - now using the correct field names from API
      final summary = reportData['period_summary'];
      if (summary != null && summary is Map<String, dynamic>) {
        totalDays.value = _parseIntSafely(summary['total_days']);
        presentDays.value = _parseIntSafely(summary['present_days']);
        halfDays.value = _parseIntSafely(summary['half_days']);
        absentDays.value = _parseIntSafely(summary['absent_days']);
        attendancePercentage.value = _parseDoubleSafely(summary['attendance_percentage']);
        totalWagesEarned.value = _parseDoubleSafely(summary['total_wages_earned']);
        totalWagesPaid.value = _parseDoubleSafely(summary['total_wages_paid']);
        totalWagesPending.value = _parseDoubleSafely(summary['total_wages_pending']);
        paymentPercentage.value = _parseDoubleSafely(summary['payment_percentage']);
      }

      // Parse daily attendance data - using correct field name
      final dailyAttendance = reportData['daily_attendance'];
      if (dailyAttendance != null && dailyAttendance is List) {
        try {
          dailyAttendanceData.value = dailyAttendance
              .where((day) => day != null && day is Map<String, dynamic>)
              .map((day) => AttendanceDay.fromJson(day as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing daily attendance: $e');
          dailyAttendanceData.value = [];
        }
      }

      // Parse weekly breakdown - using correct field name
      final weeklyData = reportData['weekly_breakdown'];
      if (weeklyData != null && weeklyData is List) {
        try {
          weeklyBreakdown.value = weeklyData
              .where((week) => week != null && week is Map<String, dynamic>)
              .map((week) => WeeklyBreakdown.fromJson(week as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing weekly breakdown: $e');
          weeklyBreakdown.value = [];
        }
      }

      // Update employee data with information from API
      final currentEmployee = employeeData.value!;
      employeeData.value = EmployeeAttendanceRecord(
        id: currentEmployee.id,
        name: reportData['employee_name']?.toString() ?? currentEmployee.name,
        dailyWage: _parseDoubleSafely(reportData['daily_wage']),
        hasWage: true,
      );

      // Create employee report object
      employeeReport.value = EmployeeReportData(
        employeeId: reportData['employee_id']?.toString() ?? employeeData.value!.id,
        employeeName: reportData['employee_name']?.toString() ?? employeeData.value!.name,
        dailyWage: _parseDoubleSafely(reportData['daily_wage']),
        periodSummary: summary,
        dailyAttendance: dailyAttendanceData,
        weeklyBreakdown: weeklyBreakdown,
      );
      
      print('Report processed successfully'); // Debug log
      
    } catch (e) {
      print('Error processing employee report: $e');
      _handleException('Failed to process employee report data', e);
    }
  }

  /// Reset report data to default values
  void _resetReportData() {
    totalDays.value = 0;
    presentDays.value = 0;
    halfDays.value = 0;
    absentDays.value = 0;
    attendancePercentage.value = 0.0;
    totalWagesEarned.value = 0.0;
    totalWagesPaid.value = 0.0;
    totalWagesPending.value = 0.0;
    paymentPercentage.value = 0.0;
    dailyAttendanceData.clear();
    weeklyBreakdown.clear();
  }

  /// Safe integer parsing
  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Safe double parsing
  double _parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Format week start with better error handling
  String _formatWeekStart() {
    try {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      return DateFormat('yyyy-MM-dd').format(monday);
    } catch (e) {
      print('Error formatting week start: $e');
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  /// Pay employee wages with improved error handling
  Future<void> payEmployeeWages(double amount, {
    String paymentMode = 'Cash',
    String? paymentReference,
    String? remarks,
  }) async {
    if (employeeData.value == null || isProcessingPayment.value) return;

    if (amount <= 0) {
      _showErrorMessage('Payment amount must be greater than 0');
      return;
    }

    isProcessingPayment.value = true;

    try {
      final request = WagePaymentRequest(
        employeeId: employeeData.value!.id,
        amount: amount,
        paymentMode: paymentMode,
        paymentReference: paymentReference,
        remarks: remarks,
        weekStart: _formatWeekStart(),
        payAll: false,
      );

      final response = await AttendanceService.payWages(request: request);

      if (response != null && response['success'] == true) {
        await fetchEmployeeReport(); // Refresh data
        _showPaymentSuccessDialog(amount);
      } else {
        final errorMessage = response?['error']?.toString() ?? 'Payment failed';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      _handleException('Failed to process payment', e);
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Update date range and refresh data
  Future<void> updateDateRange(DateTime newStartDate, DateTime newEndDate) async {
    if (newStartDate.isAfter(newEndDate)) {
      _showErrorMessage('Start date cannot be after end date');
      return;
    }
    
    startDate.value = newStartDate;
    endDate.value = newEndDate;
    await fetchEmployeeReport();
  }

  /// Refresh data manually
  Future<void> refreshData() async {
    await fetchEmployeeReport();
  }

  /// Get attendance status text
  String getAttendanceStatusText(int? status) {
    switch (status) {
      case 0: return 'Absent';
      case 1: return 'Present';
      case 2: return 'Half Day';
      case 3: return 'Late';
      default: return 'Not Marked';
    }
  }

  /// Get attendance status color
  Color getAttendanceStatusColor(int? status) {
    switch (status) {
      case 0: return Colors.red;
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      default: return Colors.grey;
    }
  }

  /// Get attendance status icon
  IconData getAttendanceStatusIcon(int? status) {
    switch (status) {
      case 0: return Icons.close;
      case 1: return Icons.check;
      case 2: return Icons.schedule;
      case 3: return Icons.access_time;
      default: return Icons.help_outline;
    }
  }

  /// Get formatted date range
  String get formattedDateRange {
    try {
      return '${DateFormat('dd MMM yyyy').format(startDate.value)} - ${DateFormat('dd MMM yyyy').format(endDate.value)}';
    } catch (e) {
      return 'Invalid date range';
    }
  }

  /// Check if employee has pending wages
  bool get hasPendingWages => totalWagesPending.value > 0;

  /// Get weekly attendance summary
  Map<String, double> getWeeklyAttendanceSummary() {
    if (weeklyBreakdown.isEmpty) return {
      'average_attendance': 0.0,
      'total_weeks': 0.0,
      'valid_weeks': 0.0,
    };
    
    double avgAttendance = 0.0;
    int validWeeks = 0;
    
    for (var week in weeklyBreakdown) {
      final totalDays = week.presentDays + week.halfDays + week.absentDays;
      if (totalDays > 0) {
        avgAttendance += (week.presentDays + week.halfDays * 0.5) / totalDays * 100;
        validWeeks++;
      }
    }
    
    return {
      'average_attendance': validWeeks > 0 ? avgAttendance / validWeeks : 0.0,
      'total_weeks': weeklyBreakdown.length.toDouble(),
      'valid_weeks': validWeeks.toDouble(),
    };
  }

  // MARK: - Dialog Methods
  
  void _showPaymentSuccessDialog(double amount) {
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Successful'),
        content: Text('₹${amount.toStringAsFixed(0)} paid to ${employeeData.value?.name}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // MARK: - Error Handling
  
  void _handleException(String context, dynamic error) {
    final errorMessage = '$context: ${error.toString()}';
    print('Exception: $errorMessage'); // Debug log
    _showErrorMessage(errorMessage);
  }

  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}

// MARK: - Data Models (Updated with better null safety)

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
      statusCode: json['status_code'] is int ? json['status_code'] : 
                  (json['status_code'] != null ? int.tryParse(json['status_code'].toString()) : null),
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

// Extension methods
extension DateTimeExtensions on DateTime {
  DateTime get mondayOfWeek {
    return subtract(Duration(days: weekday - 1));
  }
  
  String toDateString() {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}