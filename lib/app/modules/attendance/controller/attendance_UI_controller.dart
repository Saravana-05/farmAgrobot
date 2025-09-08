import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../data/services/attendance/attendance_service.dart';
import '../../../data/models/attendance/attendance_record_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AttendanceUIController extends GetxController {
  // Core data observables
  var employees = <EmployeeAttendanceRecord>[].obs;
  var weeklyData = Rxn<WeeklyData>();
  var attendanceRecords = <String, Map<DateTime, int>>{}.obs;
  var selectedWeekStart = DateTime.now().obs;

  // Loading states
  var isLoading = false.obs;
  var isExporting = false.obs;
  var isUpdatingAttendance = false.obs;
  var isProcessingPayment = false.obs;

  // Wage management
  var grandTotalWages = 0.0.obs;
  var wagesPaid = false.obs;
  var paymentType = 'none'.obs;
  var employeePaymentStatus = <String, String>{}.obs;
  var employeePartialPayments = <String, double>{}.obs;
  var employeeRemainingAmounts = <String, double>{}.obs;

  // Bulk payment info
  var bulkPaymentInfo = Rxn<BulkPaymentInfo>();

  // Statistics and counts
  var dailyEmployeeCount = <DateTime, int>{}.obs;
  var weeklyEmployeeCount = 0.obs;
  var attendanceStatistics = Rxn<AttendanceStatistics>();

  // Employee ordering
  var customEmployeeOrder = <String>[].obs;
  var useCustomOrder = false.obs;
  var isReorderMode = false.obs;

  // Export settings
  var fromDate = Rxn<DateTime>();
  var toDate = Rxn<DateTime>();

  var isPdfGenerating = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// Initialize controller with default values
  void _initializeController() {
    selectedWeekStart.value = DateTime.now().mondayOfWeek;
    _setDefaultDateRange();
    loadEmployeeOrder();
    fetchWeeklyData();
  }

  /// Set default date range for exports (current month)
  void _setDefaultDateRange() {
    final now = DateTime.now();
    fromDate.value = DateTime(now.year, now.month, 1);
    toDate.value = DateTime(now.year, now.month + 1, 0);
  }

  // MARK: - Data Fetching Methods

  Future<void> fetchWeeklyData() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      print('Starting fetchWeeklyData for week: ${selectedWeekStart.value}');

      final response = await AttendanceService.getWeeklyData(
        weekStart: selectedWeekStart.value,
      );

      print('=== CONTROLLER DEBUG ===');
      print('Response success: ${response['success']}');

      if (response['success'] == true && response['data'] != null) {
        print('API call successful, processing data...');

        final rawData = response['data'];
        final weeklyDataModel = WeeklyData.fromJson(rawData);

        weeklyData.value = weeklyDataModel;
        await _processWeeklyData(weeklyDataModel);

        // CRITICAL: Ensure UI updates after processing
        _refreshPaymentUI();

        _showSuccessMessage('Weekly data loaded successfully');
      } else {
        print('API Error Response: $response');
        _handleApiError(response);
      }
    } catch (e, stackTrace) {
      print('Exception in fetchWeeklyData: $e');
      print('Stack trace: $stackTrace');
      _handleException('Failed to fetch weekly data', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Process weekly data and update local state
  /// Process weekly data and update local state
  Future<void> _processWeeklyData(WeeklyData data) async {
    _clearLocalData();

    Map<String, EmployeeAttendanceRecord> employeeMap = {};

    // Process employees from the weekly data response
    for (int i = 0; i < data.employees.length; i++) {
      try {
        var empData = data.employees[i];
        
        print('Processing employee $i: ${empData.employeeId}');
        print('Employee data type check:');
        print('  employeeId: ${empData.employeeId.runtimeType}');
        print('  employeeName: ${empData.employeeName.runtimeType}');
        print('  dailyWage: ${empData.dailyWage.runtimeType}');
        print('  attendance: ${empData.attendance.runtimeType}');

        // Create employee record with validation
        final employeeId = empData.employeeId?.toString() ?? '';
        final employeeName = empData.employeeName?.toString() ?? 'Unknown';
        final dailyWage = _parseDouble(empData.dailyWage) ?? 0.0;

        if (employeeId.isEmpty) {
          print('Warning: Empty employee ID for employee at index $i, skipping');
          continue;
        }

        employeeMap[employeeId] = EmployeeAttendanceRecord(
          id: employeeId,
          name: employeeName,
          dailyWage: dailyWage,
          hasWage: true,
        );

        // Store attendance records with proper parsing
        attendanceRecords[employeeId] = {};
        
        // Handle attendance data safely
        if (empData.attendance != null) {
          if (empData.attendance is Map) {
            final attendanceMap = empData.attendance as Map;
            attendanceMap.forEach((key, value) {
              final dateString = key.toString();
              final date = DateTime.tryParse(dateString);
              
              if (date != null) {
                // Parse status value safely
                int? status;
                if (value is int) {
                  status = value;
                } else if (value is String) {
                  status = int.tryParse(value);
                } else if (value is double) {
                  status = value.toInt();
                } else {
                  // print('Warning: Unknown attendance status type for $employeeId on $dateString: ${value.runtimeType}');
                  // continue;
                }
                
                if (status != null && [0, 1, 2, 3].contains(status)) {
                  attendanceRecords[employeeId]![date] = status;
                } else {
                  print('Warning: Invalid attendance status $status for $employeeId on $dateString');
                }
              } else {
                print('Warning: Invalid date format $dateString for employee $employeeId');
              }
            });
          } else {
            print('Warning: Expected Map for attendance data, got ${empData.attendance.runtimeType}');
          }
        }

        // Store payment information with safe parsing and validation
        final paymentStatus = empData.paymentStatus?.toString() ?? 'pending';
        final partialPayment = _parseDouble(empData.partialPayment) ?? 0.0;
        final remainingAmount = _parseDouble(empData.remainingAmount) ?? 0.0;

        employeePaymentStatus[employeeId] = paymentStatus;
        employeePartialPayments[employeeId] = partialPayment;
        employeeRemainingAmounts[employeeId] = remainingAmount;

        print('Successfully processed employee payment data:');
        print('  ID: $employeeId');
        print('  Name: $employeeName');
        print('  Daily Wage: $dailyWage');
        print('  Payment Status: $paymentStatus');
        print('  Partial Payment: $partialPayment');
        print('  Remaining Amount: $remainingAmount');
        print('  Attendance Records: ${attendanceRecords[employeeId]?.length ?? 0}');

      } catch (e, stackTrace) {
        print('Error processing employee $i: $e');
        print('Stack trace: $stackTrace');
        print('Employee data: ${data.employees[i]}');
        
        // Continue processing other employees instead of failing completely
        continue;
      }
    }

    // Handle case where no employees in weekly data
    if (employeeMap.isEmpty) {
      await _loadActiveEmployeesAsFallback(employeeMap);
    }

    // Convert map back to list
    employees.value = employeeMap.values.toList();

    // Ensure all employees have initialized payment data
    _ensurePaymentDataInitialized();

    // Apply employee ordering
    _applyEmployeeOrdering();

    // Set wage information
    grandTotalWages.value = data.totalWages;
    wagesPaid.value = data.wagesPaid;

    // Calculate counts
    _calculateEmployeeCounts(data);

    print('=== PROCESSING COMPLETE ===');
    print('Final employees count: ${employees.length}');
    print('Employees processed: ${employees.map((e) => '${e.id}:${e.name}').join(', ')}');
  }

  /// Helper method to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    
    print('Warning: Cannot parse double from ${value.runtimeType}: $value');
    return null;
  }

  /// Enhanced method to ensure payment data is initialized for all employees
  void _ensurePaymentDataInitialized() {
    for (var employee in employees) {
      // Initialize payment status if not exists
      if (!employeePaymentStatus.containsKey(employee.id)) {
        employeePaymentStatus[employee.id] = 'pending';
        print('Initialized payment status for ${employee.id}: pending');
      }

      // Initialize partial payment if not exists
      if (!employeePartialPayments.containsKey(employee.id)) {
        employeePartialPayments[employee.id] = 0.0;
        print('Initialized partial payment for ${employee.id}: 0.0');
      }

      // Initialize or calculate remaining amount
      if (!employeeRemainingAmounts.containsKey(employee.id)) {
        final totalWages = getTotalWages(employee.id);
        final partialPayment = employeePartialPayments[employee.id] ?? 0.0;
        employeeRemainingAmounts[employee.id] = totalWages - partialPayment;
        print('Calculated remaining amount for ${employee.id}: ${employeeRemainingAmounts[employee.id]}');
      }

      // Initialize attendance records if not exists
      if (!attendanceRecords.containsKey(employee.id)) {
        attendanceRecords[employee.id] = {};
        print('Initialized attendance records for ${employee.id}');
      }

      // Validate payment data consistency
      _validatePaymentDataConsistency(employee.id);
    }
  }

  /// Validate payment data consistency for an employee
  void _validatePaymentDataConsistency(String employeeId) {
    final totalWages = getTotalWages(employeeId);
    final partialPayment = employeePartialPayments[employeeId] ?? 0.0;
    final remainingAmount = employeeRemainingAmounts[employeeId] ?? 0.0;
    final paymentStatus = employeePaymentStatus[employeeId] ?? 'pending';

    // Check if calculations are consistent
    final expectedRemaining = totalWages - partialPayment;
    
    if ((expectedRemaining - remainingAmount).abs() > 0.01) {
      print('Warning: Payment data inconsistency for $employeeId');
      print('  Total Wages: $totalWages');
      print('  Partial Payment: $partialPayment');
      print('  Stored Remaining: $remainingAmount');
      print('  Expected Remaining: $expectedRemaining');
      
      // Auto-correct the remaining amount
      employeeRemainingAmounts[employeeId] = expectedRemaining > 0 ? expectedRemaining : 0.0;
    }

    // Check if status matches payment amounts
    if (partialPayment >= totalWages && paymentStatus != 'paid') {
      print('Auto-correcting payment status for $employeeId from $paymentStatus to paid');
      employeePaymentStatus[employeeId] = 'paid';
      employeeRemainingAmounts[employeeId] = 0.0;
    } else if (partialPayment > 0 && partialPayment < totalWages && paymentStatus == 'pending') {
      print('Auto-correcting payment status for $employeeId from $paymentStatus to partial');
      employeePaymentStatus[employeeId] = 'partial';
    }
  }

  

  /// NEW METHOD: Load active employees as fallback
  Future<void> _loadActiveEmployeesAsFallback(
      Map<String, EmployeeAttendanceRecord> employeeMap) async {
    try {
      final response = await AttendanceService.getActiveEmployees();
      if (response['success'] == true && response['data'] != null) {
        final apiData = response['data'];

        if (apiData.containsKey('employees') && apiData['employees'] is List) {
          final employeeList = apiData['employees'] as List;

          for (var empJson in employeeList) {
            final employeeId = empJson['employee_id'].toString();
            final employee = EmployeeAttendanceRecord(
              id: employeeId,
              name: empJson['employee_name'].toString(),
              dailyWage:
                  double.tryParse(empJson['daily_wage'].toString()) ?? 0.0,
              hasWage: empJson['has_wage'] ?? false,
            );

            employeeMap[employee.id] = employee;

            // Initialize payment data for fallback employees
            employeePaymentStatus[employeeId] = 'pending';
            employeePartialPayments[employeeId] = 0.0;
            employeeRemainingAmounts[employeeId] = 0.0;
          }

          print('Loaded ${employeeMap.length} active employees as fallback');
        }
      }
    } catch (e) {
      print('Error loading active employees: $e');
    }
  }

  /// Fetch active employees
  Future<void> fetchActiveEmployees() async {
    try {
      final response = await AttendanceService.getActiveEmployees();

      if (response['success'] == true && response['data'] != null) {
        // FIXED: Use the corrected parsing method
        final employeeList =
            AttendanceService.employeeListFromJson(response['data']);
        employees.value = employeeList;
        _applyEmployeeOrdering();
        _showSuccessMessage('Active employees loaded successfully');

        print('Fetched ${employeeList.length} active employees');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to fetch active employees', e);
    }
  }

  /// Fetch attendance statistics
  Future<void> fetchAttendanceStatistics(
      {DateTime? fromDate, DateTime? toDate}) async {
    try {
      final response = await AttendanceService.getAttendanceStatistics(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response['success'] == true && response['data'] != null) {
        // Process attendance statistics (implement based on your model)
        _showSuccessMessage('Statistics loaded successfully');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to fetch attendance statistics', e);
    }
  }

  /// Update single employee attendance
  Future<void> updateAttendance(
    String employeeId,
    String employeeName,
    DateTime date,
    int status,
  ) async {
    // Validation checks
    if (employeeId.isEmpty) {
      _showErrorMessage('Employee ID cannot be empty');
      return;
    }

    if (employeeName.isEmpty) {
      _showErrorMessage('Employee name cannot be empty');
      return;
    }

    if (![0, 1, 2, 3].contains(status)) {
      _showErrorMessage('Invalid attendance status: $status');
      return;
    }

    if (_checkWagesPaidRestriction()) return;
    if (isUpdatingAttendance.value) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    isUpdatingAttendance.value = true;

    try {
      print('Updating attendance for:');
      print('  Employee ID: $employeeId');
      print('  Employee Name: $employeeName');
      print('  Date: $normalizedDate');
      print('  Status: $status');

      final response = await AttendanceService.updateSingleAttendance(
        employeeId: employeeId,
        employeeName: employeeName,
        date: normalizedDate,
        status: status,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        // Success case
        _updateLocalAttendance(employeeId, normalizedDate, status);
        await fetchWeeklyData();

        final successMessage =
            response['data']['message'] ?? 'Attendance updated successfully';
        _showSuccessMessage(successMessage);
      } else {
        // Handle API errors (400, 404, etc.)
        final responseData = response['data'] ?? {};

        // Extract error message from API response
        String errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Failed to update attendance';

        // Add status code context for debugging if needed
        final statusCode = response['statusCode'];
        if (statusCode != null && statusCode >= 500) {
          errorMessage = 'Server error occurred. Please try again later.';
        }

        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      print('Error in updateAttendance: $e');

      // This catch block should now only handle unexpected errors
      // since network/timeout errors are already handled in the service
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      isUpdatingAttendance.value = false;
    }
  }

  /// Mark attendance for multiple employees on a specific date
  Future<void> markAttendanceForDate(
    DateTime date,
    List<EmployeeAttendance> employeeAttendances,
  ) async {
    // Validation
    if (employeeAttendances.isEmpty) {
      _showErrorMessage('No attendance data to mark');
      return;
    }

    // Validate each attendance entry
    for (var attendance in employeeAttendances) {
      if (attendance.employeeId.isEmpty) {
        _showErrorMessage('Invalid employee data found');
        return;
      }
      if (![0, 1, 2, 3].contains(attendance.status)) {
        _showErrorMessage(
            'Invalid attendance status found: ${attendance.status}');
        return;
      }
    }

    if (_checkWagesPaidRestriction()) return;
    if (isUpdatingAttendance.value) return;

    isUpdatingAttendance.value = true;

    try {
      print(
          'Marking attendance for ${employeeAttendances.length} employees on $date');

      final response = await AttendanceService.markAttendance(
        date: date,
        employeeAttendances: employeeAttendances,
      );

      if (response != null && response['success'] == true) {
        // Update local state for all employees
        for (var attendance in employeeAttendances) {
          _updateLocalAttendance(
              attendance.employeeId, date, attendance.status);
        }

        await fetchWeeklyData();
        _showSuccessMessage(
            response['data']?['message'] ?? 'Attendance marked successfully');
      } else {
        if (response == null) {
          throw Exception('No response received from server');
        } else {
          final errorMessage = response['data']?['message'] ??
              response['error'] ??
              'Failed to mark attendance';
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      print('Error in markAttendanceForDate: $e');
      _handleException('Failed to mark attendance', e);
    } finally {
      isUpdatingAttendance.value = false;
    }
  }

  /// Update attendance for multiple employees
  Future<void> updateAttendanceForDate(
    DateTime date,
    List<EmployeeAttendance> employeeAttendances,
  ) async {
    if (_checkWagesPaidRestriction()) return;
    if (isUpdatingAttendance.value) return;

    isUpdatingAttendance.value = true;

    try {
      final response = await AttendanceService.updateAttendance(
        date: date,
        employeeAttendances: employeeAttendances,
      );

      if (response['success'] == true) {
        await fetchWeeklyData();
        _showSuccessMessage(
            response['data']['message'] ?? 'Attendance updated successfully');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to update attendance', e);
    } finally {
      isUpdatingAttendance.value = false;
    }
  }

  // Add a method to check attendance service health
  Future<bool> checkServiceHealth() async {
    try {
      // You can add a health check endpoint call here
      // For now, we'll just return true
      return true;
    } catch (e) {
      print('Service health check failed: $e');
      return false;
    }
  }

// Enhanced validation method for attendance data
  bool validateAttendanceData(String employeeId, DateTime date, int status) {
    // Check employee exists
    final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
    if (employee == null) {
      _showErrorMessage('Employee not found: $employeeId');
      return false;
    }

    // Check date is valid
    if (date.isAfter(DateTime.now())) {
      _showErrorMessage('Cannot mark attendance for future dates');
      return false;
    }

    // Check status is valid
    if (![0, 1, 2, 3].contains(status)) {
      _showErrorMessage('Invalid attendance status: $status');
      return false;
    }

    // Check if date is within reasonable range
    final today = DateTime.now();
    final sixMonthsAgo = today.subtract(const Duration(days: 180));
    if (date.isBefore(sixMonthsAgo)) {
      _showErrorMessage('Cannot mark attendance for dates older than 6 months');
      return false;
    }

    return true;
  }

  /// Get attendance for a specific date
  Future<void> getAttendanceForDate(DateTime date) async {
    try {
      final response = await AttendanceService.getAttendance(date: date);

      if (response['success'] == true && response['data'] != null) {
        final attendanceRecord =
            AttendanceService.attendanceRecordFromJson(response['data']);
        // Process attendance record as needed
        _showSuccessMessage(
            'Attendance data loaded for ${DateFormat('dd/MM/yyyy').format(date)}');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to get attendance for date', e);
    }
  }

  // MARK: - Wage Management

  /// Pay individual employee wages
  Future<void> payEmployeeWages(
    String employeeId,
    double amount, {
    String paymentMode = 'Cash',
    String? paymentReference,
    String? remarks,
  }) async {
    if (isProcessingPayment.value) return;

    isProcessingPayment.value = true;

    try {
      final request = WagePaymentRequest(
        employeeId: employeeId,
        amount: amount,
        paymentMode: paymentMode,
        paymentReference: paymentReference,
        remarks: remarks,
        weekStart: selectedWeekStart.value.toDateString(),
        payAll: false,
      );

      print('Sending payment request: ${request.toJson()}');
      final response = await AttendanceService.payWages(request: request);

      print('Payment API Response: $response');

      if (response['success'] == true) {
        print('Payment successful, processing response...');

        // CRITICAL FIX: Extract and process payment data from response
        final responseData = response['data'];
        if (responseData != null) {
          // Update local state immediately with response data
          _updatePaymentStatusFromResponse(employeeId, responseData);

          // Force UI refresh
          _refreshPaymentUI();
        }

        // Then fetch fresh data from backend to ensure consistency
        await Future.delayed(const Duration(
            milliseconds: 500)); // Small delay to ensure DB is updated
        await fetchWeeklyData();

        // Get employee name for success message
        final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
        final employeeName = employee?.name ?? 'Employee';

        print('Payment processed successfully:');
        print('  Status: ${employeePaymentStatus[employeeId]}');
        print('  Partial: ${employeePartialPayments[employeeId]}');
        print('  Remaining: ${employeeRemainingAmounts[employeeId]}');

        _showPaymentSuccessDialog(employeeName, amount);
      } else {
        print('Payment API failed: $response');
        _handleApiError(response);
      }
    } catch (e) {
      print('Payment error: $e');
      _handleException('Failed to process payment', e);
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _updatePaymentStatusFromResponse(
      String employeeId, Map<String, dynamic> responseData) {
    try {
      // Extract payment information from response
      if (responseData.containsKey('payment_status')) {
        employeePaymentStatus[employeeId] = responseData['payment_status'];
      }

      if (responseData.containsKey('partial_payment')) {
        employeePartialPayments[employeeId] =
            double.tryParse(responseData['partial_payment'].toString()) ?? 0.0;
      }

      if (responseData.containsKey('remaining_amount')) {
        employeeRemainingAmounts[employeeId] =
            double.tryParse(responseData['remaining_amount'].toString()) ?? 0.0;
      }

      // Alternative: If response contains employee data directly
      if (responseData.containsKey('employee')) {
        final empData = responseData['employee'];
        employeePaymentStatus[employeeId] =
            empData['payment_status'] ?? 'pending';
        employeePartialPayments[employeeId] =
            double.tryParse(empData['partial_payment'].toString()) ?? 0.0;
        employeeRemainingAmounts[employeeId] =
            double.tryParse(empData['remaining_amount'].toString()) ?? 0.0;
      }

      print('Updated payment status from response:');
      print('  Employee: $employeeId');
      print('  Status: ${employeePaymentStatus[employeeId]}');
      print('  Partial Payment: ${employeePartialPayments[employeeId]}');
      print('  Remaining: ${employeeRemainingAmounts[employeeId]}');
    } catch (e) {
      print('Error updating payment status from response: $e');
    }
  }

  bool _validateBulkPaymentConditions() {
    // Check if there are any employees
    if (employees.isEmpty) {
      _showErrorMessage('No employees found for the selected week');
      return false;
    }

    // Check if wages are already paid
    if (wagesPaid.value) {
      _showErrorMessage('All wages have already been paid for this week');
      return false;
    }

    // Check if there are any unpaid amounts
    double totalUnpaid = getTotalRemainingAmount();
    if (totalUnpaid <= 0) {
      _showErrorMessage('No pending payments found for this week');
      return false;
    }

    // Check if total wages is reasonable
    if (grandTotalWages.value <= 0) {
      _showErrorMessage(
          'Total wages amount is invalid: ₹${grandTotalWages.value}');
      return false;
    }

    print(
        'Validation passed: ₹$totalUnpaid pending for ${employees.length} employees');
    return true;
  }

  /// NEW METHOD: Force refresh payment UI
  void _refreshPaymentUI() {
    // Force refresh of all observable maps
    employeePaymentStatus.refresh();
    employeePartialPayments.refresh();
    employeeRemainingAmounts.refresh();

    // Recalculate grand total wages and payment status
    _recalculateWageSummary();

    // Force rebuild of employees list
    employees.refresh();
  }

  /// NEW METHOD: Recalculate wage summary
  void _recalculateWageSummary() {
    double totalPaid = 0.0;
    bool allPaid = true;

    for (var employee in employees) {
      final paidAmount = getPartialPayment(employee.id);
      final remainingAmount = getRemainingAmount(employee.id);

      totalPaid += paidAmount;

      if (remainingAmount > 0) {
        allPaid = false;
      }
    }

    // Update wages paid status
    wagesPaid.value = allPaid && employees.isNotEmpty;

    print('Recalculated wage summary:');
    print('  Total Paid: $totalPaid');
    print('  All Paid: $allPaid');
    print('  Grand Total: ${grandTotalWages.value}');
  }

  Future<void> payAllWages({
    String paymentMode = 'Cash',
    String? paymentReference,
    String? remarks,
  }) async {
    if (isProcessingPayment.value) return;

    // Pre-validation before API call
    if (!_validateBulkPaymentConditions()) {
      return;
    }

    isProcessingPayment.value = true;

    try {
      print('=== PAY ALL WAGES VALIDATION ===');
      print('Total employees: ${employees.length}');
      print('Grand total wages: ${grandTotalWages.value}');
      print('Currently wages paid status: ${wagesPaid.value}');
      print('Week start: ${selectedWeekStart.value.toDateString()}');

      // Debug current payment status
      _debugCurrentPaymentStatus();

      final request = WagePaymentRequest(
        employeeId: null,
        amount: 0.0,
        paymentMode: paymentMode,
        paymentReference: paymentReference,
        remarks: remarks ??
            'Bulk wage payment for week ${selectedWeekStart.value.toDateString()}',
        weekStart: selectedWeekStart.value.toDateString(),
        payAll: true,
      );

      print('Sending bulk payment request: ${request.toJson()}');

      final response = await AttendanceService.payWages(request: request);

      print('Bulk payment API response: $response');

      if (response['success'] == true) {
        print('Bulk payment successful, refreshing data...');
        await _handleSuccessfulBulkPayment(response['data']);
      } else {
        print('Bulk payment failed: ${response}');
        await _handleBulkPaymentError(response);
      }
    } catch (e) {
      print('Bulk payment exception: $e');
      _handleException('Failed to process bulk payment', e);
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _debugCurrentPaymentStatus() {
    print('=== PAYMENT STATUS DEBUG ===');
    for (var employee in employees) {
      final status = getPaymentStatus(employee.id);
      final partial = getPartialPayment(employee.id);
      final remaining = getRemainingAmount(employee.id);
      final totalWages = getTotalWages(employee.id);

      print('Employee: ${employee.name}');
      print('  Status: $status');
      print('  Total Wages: ₹$totalWages');
      print('  Partial Payment: ₹$partial');
      print('  Remaining: ₹$remaining');
      print('  Has Wage: ${employee.hasWage}');
      print('---');
    }

    print('Total employees: ${employees.length}');
    print('Grand total wages: ₹${grandTotalWages.value}');
    print('Total paid: ₹${getTotalPaidAmount()}');
    print('Total remaining: ₹${getTotalRemainingAmount()}');
    print('Wages paid status: ${wagesPaid.value}');
  }

// 4. Enhanced error handling for bulk payment failures
  Future<void> _handleBulkPaymentError(Map<String, dynamic> response) async {
    final statusCode = response['statusCode'];
    final errorData = response['data'] ?? {};
    String errorMessage =
        errorData['error'] ?? errorData['message'] ?? 'Unknown error';

    switch (statusCode) {
      case 400:
        if (errorMessage.contains('No pending payments')) {
          // This is the specific error you're getting
          await _handleNoPendingPaymentsError();
        } else {
          _showErrorMessage('Invalid request: $errorMessage');
        }
        break;
      case 404:
        _showErrorMessage('Week data not found. Please refresh and try again.');
        await fetchWeeklyData(); // Auto-refresh
        break;
      case 500:
        _showErrorMessage('Server error occurred. Please try again later.');
        break;
      default:
        _handleApiError(response);
    }
  }

// 5. Handle "No pending payments" error specifically
  Future<void> _handleNoPendingPaymentsError() async {
    print('Handling "No pending payments" error...');

    // Force refresh data to sync with backend
    await fetchWeeklyData();

    // Check again after refresh
    if (getTotalRemainingAmount() > 0) {
      // If we still have pending amounts locally, there's a data sync issue
      Get.dialog(
        AlertDialog(
          title: const Text('Data Synchronization Issue'),
          content: const Text(
              'There seems to be a mismatch between local and server data. '
              'The data has been refreshed. Please try the payment again.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // All payments are actually completed
      Get.dialog(
        AlertDialog(
          title: const Text('All Payments Complete'),
          content: const Text('All wages for this week have already been paid. '
              'The payment status has been updated.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

// 6. Enhanced successful bulk payment handler
  Future<void> _handleSuccessfulBulkPayment(
      Map<String, dynamic>? responseData) async {
    // Refresh data from backend
    await fetchWeeklyData();

    // Show success dialog with details
    if (responseData != null) {
      _showBulkPaymentSuccessDialog(responseData);
    } else {
      _showSuccessMessage('All wages paid successfully!');
    }
  }

// Add success dialog for bulk payments
  void _showBulkPaymentSuccessDialog(Map<String, dynamic> responseData) {
    Get.dialog(
      AlertDialog(
        title: const Text('Bulk Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All pending wages have been paid successfully!'),
            const SizedBox(height: 12),
            Text(
                'Total Amount Paid: ₹${responseData['total_amount_paid'] ?? 0}'),
            Text('Total Employees: ${responseData['total_employees'] ?? 0}'),
            Text('Week: ${responseData['week_start_date'] ?? ''}'),
            if (responseData['payment_mode'] != null)
              Text('Payment Mode: ${responseData['payment_mode']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Force refresh of weekly data - useful when you know employees were added
  Future<void> forceRefreshWeeklyData() async {
    print('Force refreshing weekly data...');

    // Clear cached data
    weeklyData.value = null;
    _clearLocalData();

    // Fetch fresh data
    await fetchWeeklyData();
  }

  /// Method to manually sync employees (can be called from UI)
  Future<void> syncEmployeesForCurrentWeek() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      // This will trigger the backend to sync the weekly record with active employees
      await fetchWeeklyData();
      _showSuccessMessage('Employees synchronized successfully');
    } catch (e) {
      _handleException('Failed to sync employees', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Generate weekly wage PDF
  Future<void> generateWeeklyWagePdf() async {
    if (isPdfGenerating.value) return;

    isPdfGenerating.value = true;

    try {
      print('Starting PDF generation for week: ${selectedWeekStart.value}');

      // Check and request storage permissions
      if (!await _checkStoragePermissions()) {
        _showErrorMessage('Storage permission is required to save PDF files');
        return;
      }

      final response = await AttendanceService.generateWeeklyWagePdf(
        weekStart: selectedWeekStart.value,
      );

      if (response['success'] == true) {
        final pdfData = response['data'];

        if (pdfData != null && pdfData.isNotEmpty) {
          await _savePdfFile(pdfData, selectedWeekStart.value);
        } else {
          _showErrorMessage('No PDF data received from server');
        }
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to generate PDF', e);
    } finally {
      isPdfGenerating.value = false;
    }
  }

  /// Check and request storage permissions
  Future<bool> _checkStoragePermissions() async {
    // For Android 11+ (API 30+), we don't need WRITE_EXTERNAL_STORAGE
    // But for older versions, we might need it
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;

      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }

      return status.isGranted;
    }

    // For iOS, no special permissions needed for Documents directory
    return true;
  }

  /// Save PDF file to device storage
  Future<void> _savePdfFile(List<int> pdfBytes, DateTime weekStart) async {
    try {
      final fileName =
          'weekly_wages_${DateFormat('yyyy_MM_dd').format(weekStart)}.pdf';

      Directory? directory;

      if (Platform.isAndroid) {
        // Try to save to Downloads directory
        directory = Directory('/storage/emulated/0/Download');

        // If Downloads directory is not accessible, use app's documents directory
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use app's documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      print('PDF saved to: ${file.path}');

      _showPdfSuccessDialog(file.path, fileName);
    } catch (e) {
      print('Error saving PDF: $e');
      _handleException('Failed to save PDF file', e);
    }
  }

  /// Show PDF generation success dialog
  void _showPdfSuccessDialog(String filePath, String fileName) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('PDF Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly wage PDF has been generated successfully!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saved to: ${Platform.isAndroid ? "Downloads" : "Documents"}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await _openPdfFile(filePath);
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open PDF'),
          ),
        ],
      ),
    );
  }

  /// Open PDF file with default application
  Future<void> _openPdfFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        // If default PDF viewer is not available, show options
        Get.dialog(
          AlertDialog(
            title: const Text('Cannot Open PDF'),
            content: const Text(
              'No PDF viewer app found. Please install a PDF reader app from the Play Store or App Store to view the generated PDF.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error opening PDF: $e');
      _showErrorMessage(
          'Could not open PDF file. Please check if you have a PDF viewer installed.');
    }
  }

  /// Generate and share PDF via sharing options
  Future<void> generateAndSharePdf() async {
    if (isPdfGenerating.value) return;

    isPdfGenerating.value = true;

    try {
      final response = await AttendanceService.generateWeeklyWagePdf(
        weekStart: selectedWeekStart.value,
      );

      if (response['success'] == true) {
        final pdfData = response['data'];

        if (pdfData != null && pdfData.isNotEmpty) {
          await _sharePdfFile(pdfData, selectedWeekStart.value);
        } else {
          _showErrorMessage('No PDF data received from server');
        }
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to generate and share PDF', e);
    } finally {
      isPdfGenerating.value = false;
    }
  }

  /// Share PDF file using system sharing
  Future<void> _sharePdfFile(List<int> pdfBytes, DateTime weekStart) async {
    try {
      final fileName =
          'weekly_wages_${DateFormat('yyyy_MM_dd').format(weekStart)}.pdf';

      // Get temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      _showSuccessMessage(
          'PDF generated successfully. File saved to temporary storage.');
    } catch (e) {
      print('Error sharing PDF: $e');
      _handleException('Failed to share PDF file', e);
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Get wage summary for current week
  Future<void> fetchWageSummary() async {
    try {
      final response = await AttendanceService.getWageSummary(
        weekStart: selectedWeekStart.value,
      );

      if (response['success'] == true && response['data'] != null) {
        final wageSummary =
            AttendanceService.wageSummaryFromJson(response['data']);
        _showWageSummaryDialog(wageSummary);
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to fetch wage summary', e);
    }
  }

  // MARK: - Export Functionality

  /// Export attendance to Excel
  Future<void> exportAttendanceToExcel(
      DateTime fromDate, DateTime toDate) async {
    if (isExporting.value) return;

    isExporting.value = true;

    try {
      final response = await AttendanceService.exportAttendance(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response['success'] == true && response['data'] != null) {
        final exportData =
            AttendanceService.attendanceExportFromJson(response['data']);
        _showExportSuccessDialog(exportData, fromDate, toDate);
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Export failed', e);
    } finally {
      isExporting.value = false;
    }
  }

  // MARK: - Navigation Methods

  /// Navigate to previous week
  void previousWeek() {
    selectedWeekStart.value =
        selectedWeekStart.value.subtract(const Duration(days: 7));
    fetchWeeklyData();
  }

  /// Navigate to next week
  void nextWeek() {
    final now = DateTime.now();
    final nextWeekStart = selectedWeekStart.value.add(const Duration(days: 7));
    if (!nextWeekStart.isAfter(now.mondayOfWeek)) {
      selectedWeekStart.value = nextWeekStart;
      fetchWeeklyData();
    }
  }

  /// Go to current week
  void goToCurrentWeek() {
    selectedWeekStart.value = DateTime.now().mondayOfWeek;
    fetchWeeklyData();
  }

  /// Navigate to specific week
  void goToWeek(DateTime weekStart) {
    selectedWeekStart.value = weekStart.mondayOfWeek;
    fetchWeeklyData();
  }

  // MARK: - Employee Ordering

  /// Show employee order dialog
  void showEmployeeOrderDialog() {
    if (customEmployeeOrder.isEmpty) {
      customEmployeeOrder.value = employees.map((e) => e.id).toList();
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Customize Employee Order'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Obx(() => ReorderableListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employeeId = customEmployeeOrder.isNotEmpty
                      ? customEmployeeOrder[index]
                      : employees[index].id;
                  final employee =
                      employees.firstWhere((e) => e.id == employeeId);

                  return ListTile(
                    key: ValueKey(employee.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(employee.name),
                    subtitle: Text(
                        'Daily Wage: ₹${employee.dailyWage.toStringAsFixed(0)}'),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = customEmployeeOrder.removeAt(oldIndex);
                  customEmployeeOrder.insert(newIndex, item);
                },
              )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _resetEmployeeOrder,
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: _saveEmployeeOrder,
            child: const Text('Save Order'),
          ),
        ],
      ),
    );
  }

  // MARK: - Helper Methods

  /// Check if wages are paid and show restriction message
  bool _checkWagesPaidRestriction() {
    if (wagesPaid.value) {
      Get.dialog(
        AlertDialog(
          title: const Text("Cannot Modify"),
          content: const Text(
              "Wages have already been paid for this week. You cannot update attendance."),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return true;
    }
    return false;
  }

  /// Clear local data before refresh
  void _clearLocalData() {
    employees.clear();
    attendanceRecords.clear();
    employeePaymentStatus.clear();
    employeePartialPayments.clear();
    employeeRemainingAmounts.clear();
    dailyEmployeeCount.clear();
  }

  /// Update local attendance record
  void _updateLocalAttendance(String employeeId, DateTime date, int status) {
    try {
      // Validate inputs
      if (employeeId.isEmpty) {
        print('Warning: Empty employee ID in _updateLocalAttendance');
        return;
      }

      if (![0, 1, 2, 3].contains(status)) {
        print('Warning: Invalid status $status in _updateLocalAttendance');
        return;
      }

      // Ensure attendance record exists
      if (attendanceRecords[employeeId] == null) {
        attendanceRecords[employeeId] = {};
      }

      // Update the record
      attendanceRecords[employeeId]![date] = status;

      // Force observable update
      attendanceRecords.refresh();

      print(
          'Local attendance updated: Employee $employeeId, Date $date, Status $status');
    } catch (e) {
      print('Error in _updateLocalAttendance: $e');
    }
  }

  /// Apply employee ordering
  void _applyEmployeeOrdering() {
    if (!useCustomOrder.value || customEmployeeOrder.isEmpty) {
      employees.sort((a, b) => a.name.compareTo(b.name));
    } else {
      _applyCustomOrder();
    }
  }

  /// Apply custom employee order
  void _applyCustomOrder() {
    final reorderedEmployees = <EmployeeAttendanceRecord>[];

    for (String employeeId in customEmployeeOrder) {
      try {
        final employee = employees.firstWhere((e) => e.id == employeeId);
        reorderedEmployees.add(employee);
      } catch (e) {
        // Employee not found, skip
      }
    }

    // Add any employees not in custom order
    for (EmployeeAttendanceRecord employee in employees) {
      if (!customEmployeeOrder.contains(employee.id)) {
        reorderedEmployees.add(employee);
      }
    }

    employees.value = reorderedEmployees;
  }

  /// Calculate employee counts from weekly data
  void _calculateEmployeeCounts(WeeklyData data) {
    dailyEmployeeCount.clear();

    data.dailyCounts.forEach((dateString, count) {
      final date = DateTime.tryParse(dateString);
      if (date != null) {
        dailyEmployeeCount[date] = count;
      }
    });

    weeklyEmployeeCount.value = data.weeklyEmployeeCount;
  }

  /// Reset employee order
  void _resetEmployeeOrder() {
    customEmployeeOrder.value = employees.map((e) => e.id).toList();
    employees.sort((a, b) => a.name.compareTo(b.name));
    saveEmployeeOrder();
    Get.back();
    useCustomOrder.value = false;
  }

  /// Save employee order
  void _saveEmployeeOrder() {
    saveEmployeeOrder();
    Get.back();
    useCustomOrder.value = true;
    _applyCustomOrder();
  }

  // MARK: - Dialog Methods

  /// Show payment success dialog
  void _showPaymentSuccessDialog(String employeeName, double amount) {
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Successful'),
        content: Text('₹${amount.toStringAsFixed(0)} paid to $employeeName'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show pay all success dialog
  void _showPayAllSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('₹${grandTotalWages.value.toStringAsFixed(0)}'),
        content: const Text('All Wages Paid Successfully'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show wage summary dialog
  void _showWageSummaryDialog(WageSummary summary) {
    Get.dialog(
      AlertDialog(
        title: Text('Wage Summary - Week ${summary.weekStartDate}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                  'Total Employees', summary.totalEmployees.toString()),
              _buildSummaryRow('Gross Wages',
                  '₹${summary.totalGrossWages.toStringAsFixed(2)}'),
              _buildSummaryRow('Paid Amount',
                  '₹${summary.totalPaidAmount.toStringAsFixed(2)}'),
              _buildSummaryRow('Remaining',
                  '₹${summary.totalRemainingAmount.toStringAsFixed(2)}'),
              const Divider(),
              _buildSummaryRow('Fully Paid', summary.fullyPaidCount.toString()),
              _buildSummaryRow(
                  'Partially Paid', summary.partiallyPaidCount.toString()),
              _buildSummaryRow('Pending', summary.pendingCount.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show export success dialog
  void _showExportSuccessDialog(
      AttendanceExport exportData, DateTime fromDate, DateTime toDate) {
    Get.dialog(
      AlertDialog(
        title: const Text('Export Complete'),
        content:
            Text('Exported ${exportData.totalRecords} records for date range:\n'
                '${DateFormat('dd/MM/yyyy').format(fromDate)} to '
                '${DateFormat('dd/MM/yyyy').format(toDate)}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build summary row for dialogs
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // MARK: - Error Handling

  /// Handle API errors
  void _handleApiError(Map<String, dynamic> response) {
    print('API Error Response: $response');

    String message = 'An error occurred';

    // Try to extract error message from various possible locations
    if (response['data'] != null && response['data']['message'] != null) {
      message = response['data']['message'];
    } else if (response['error'] != null) {
      message = response['error'];
    } else if (response['message'] != null) {
      message = response['message'];
    } else if (response['errors'] != null) {
      // Handle validation errors
      if (response['errors'] is Map) {
        final errors = response['errors'] as Map;
        message = errors.values.join(', ');
      } else if (response['errors'] is List) {
        message = (response['errors'] as List).join(', ');
      }
    }

    _showErrorMessage(message);
  }

  /// Handle exceptions
  void _handleException(String context, dynamic error) {
    Get.snackbar(
      'Error',
      '$context: ${error.toString()}',
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // MARK: - Persistence Methods (Mock implementations)

  /// Save employee order to persistent storage
  Future<void> saveEmployeeOrder() async {
    try {
      // TODO: Implement actual persistence (SharedPreferences, Hive, etc.)
      await Future.delayed(const Duration(milliseconds: 200));
      _showSuccessMessage('Employee order saved successfully');
    } catch (e) {
      _handleException('Failed to save employee order', e);
    }
  }

  /// Load employee order from persistent storage
  Future<void> loadEmployeeOrder() async {
    try {
      // TODO: Implement actual persistence loading
      await Future.delayed(const Duration(milliseconds: 200));
      customEmployeeOrder.value = [];
      useCustomOrder.value = false;
    } catch (e) {
      _handleException('Failed to load employee order', e);
    }
  }

  // MARK: - Utility Methods

  /// Get attendance status text for display
  String getAttendanceStatusText(int? status) {
    switch (status) {
      case 0:
        return 'Absent';
      case 1:
        return 'Present';
      case 2:
        return 'Half Day';
      case 3:
        return 'Late';
      default:
        return 'Not Marked';
    }
  }

  /// Get attendance status color
  Color getAttendanceStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Check if all employees are paid
  bool get allEmployeesPaid {
    return employees
        .every((employee) => employeePaymentStatus[employee.id] == 'paid');
  }

  /// Get remaining amount for employee
  double getRemainingAmount(String employeeId) {
    return employeeRemainingAmounts[employeeId] ?? 0.0;
  }

  /// Get payment status for employee
  String getPaymentStatus(String employeeId) {
    return employeePaymentStatus[employeeId] ?? 'pending';
  }

  /// Get partial payment amount for employee
  double getPartialPayment(String employeeId) {
    return employeePartialPayments[employeeId] ?? 0.0;
  }

  /// Check if can navigate to next week
  bool get canNavigateNext {
    final nextWeekStart = selectedWeekStart.value.add(const Duration(days: 7));
    return !nextWeekStart.isAfter(DateTime.now().mondayOfWeek);
  }

  /// Get formatted week range
  String get formattedWeekRange {
    final start = selectedWeekStart.value;
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
  }

  /// Get total present days for employee in current week
  int getTotalPresentDays(String employeeId) {
    if (attendanceRecords[employeeId] == null) return 0;

    return attendanceRecords[employeeId]!
        .values
        .where((status) => status == 1 || status == 2)
        .length;
  }

  /// Get total wages for employee in current week
  double getTotalWages(String employeeId) {
    final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
    if (employee == null || attendanceRecords[employeeId] == null) return 0.0;

    double totalWages = 0.0;
    attendanceRecords[employeeId]!.values.forEach((status) {
      if (status == 1) {
        totalWages += employee.dailyWage;
      } else if (status == 2) {
        totalWages += employee.dailyWage * 0.5;
      }
    });

    return totalWages;
  }

  @override
  void onClose() {
    // Clean up any resources if needed
    super.onClose();
  }

  /// Get total paid amount across all employees
  double getTotalPaidAmount() {
    double totalPaid = 0.0;
    for (var employee in employees) {
      totalPaid += getPartialPayment(employee.id);
    }
    return totalPaid;
  }

  /// Get total remaining amount across all employees
  double getTotalRemainingAmount() {
    return grandTotalWages.value - getTotalPaidAmount();
  }

  /// Check if there are any unpaid employees
  bool get hasUnpaidEmployees {
    return employees.any((employee) => getRemainingAmount(employee.id) > 0);
  }

  /// Get count of employees by payment status
  Map<String, int> getPaymentStatusCounts() {
    int paid = 0;
    int partial = 0;
    int pending = 0;

    for (var employee in employees) {
      final status = getPaymentStatus(employee.id);
      final partialAmount = getPartialPayment(employee.id);

      if (status == 'paid') {
        paid++;
      } else if (partialAmount > 0) {
        partial++;
      } else {
        pending++;
      }
    }

    return {
      'paid': paid,
      'partial': partial,
      'pending': pending,
    };
  }

  /// Update individual employee remaining amount after payment
  void updateEmployeeRemainingAmount(String employeeId, double paidAmount) {
    final currentRemaining = getRemainingAmount(employeeId);
    final newRemaining = currentRemaining - paidAmount;

    if (newRemaining <= 0) {
      employeePaymentStatus[employeeId] = 'paid';
      employeeRemainingAmounts[employeeId] = 0.0;
      employeePartialPayments[employeeId] = getTotalWages(employeeId);
    } else {
      employeePaymentStatus[employeeId] = 'partial';
      employeeRemainingAmounts[employeeId] = newRemaining;
      employeePartialPayments[employeeId] =
          (employeePartialPayments[employeeId] ?? 0.0) + paidAmount;
    }

    // Force UI refresh
    employeePaymentStatus.refresh();
    employeeRemainingAmounts.refresh();
    employeePartialPayments.refresh();
  }
}
