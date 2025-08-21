import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/services/attendance/attendance_service.dart';
import '../../../data/models/attendance/attendance_record_model.dart';

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
      print('Response keys: ${response.keys}');
      print('Data exists: ${response['data'] != null}');

      if (response['success'] == true && response['data'] != null) {
        print('API call successful, processing data...');

        // CRITICAL: Debug the data before parsing
        final rawData = response['data'];
        print('Raw data type: ${rawData.runtimeType}');
        print('Raw data keys: ${rawData.keys}');

        if (rawData.containsKey('employees')) {
          print('Raw employees count: ${rawData['employees']?.length ?? 0}');
          print('Raw employees data: ${rawData['employees']}');
        }

        // Parse using the model
        print('Parsing with WeeklyData.fromJson...');
        final weeklyDataModel = WeeklyData.fromJson(rawData);

        // CRITICAL: Debug the parsed model
        print('=== PARSED MODEL DEBUG ===');
        print('Parsed employees count: ${weeklyDataModel.employees.length}');
        for (int i = 0; i < weeklyDataModel.employees.length; i++) {
          final emp = weeklyDataModel.employees[i];
          print(
              'Parsed employee $i: ID=${emp.employeeId}, Name="${emp.employeeName}"');
        }

        weeklyData.value = weeklyDataModel;

        print('Processing weekly data...');
        await _processWeeklyData(weeklyDataModel);

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
  Future<void> _processWeeklyData(WeeklyData data) async {
    print('=== PROCESSING WEEKLY DATA ===');
    print('Input data employees count: ${data.employees.length}');

    _clearLocalData();

    // FIXED: Create employee map from API response data
    Map<String, EmployeeAttendanceRecord> employeeMap = {};

    // Process employees from the weekly data response
    for (int i = 0; i < data.employees.length; i++) {
      var empData = data.employees[i];
      print('Processing employee $i:');
      print('  - ID: ${empData.employeeId}');
      print('  - Name: "${empData.employeeName}"');
      print('  - Daily Wage: ${empData.dailyWage}');
      print('  - Attendance entries: ${empData.attendance.length}');

      // Create employee record
      employeeMap[empData.employeeId] = EmployeeAttendanceRecord(
        id: empData.employeeId,
        name: empData.employeeName,
        dailyWage: empData.dailyWage,
        hasWage: true,
      );

      // Store attendance records - Handle null status values
      attendanceRecords[empData.employeeId] = {};
      empData.attendance.forEach((dateString, status) {
        final date = DateTime.tryParse(dateString);
        if (date != null && status != null) {
          attendanceRecords[empData.employeeId]![date] = status;
        }
      });

      // Store payment information
      employeePaymentStatus[empData.employeeId] = empData.paymentStatus;
      employeePartialPayments[empData.employeeId] = empData.partialPayment;
      employeeRemainingAmounts[empData.employeeId] = empData.remainingAmount;
    }

    // FIXED: If no employees in weekly data, fetch active employees as fallback
    if (employeeMap.isEmpty) {
      print('No employees in weekly data, fetching active employees...');
      try {
        final response = await AttendanceService.getActiveEmployees();
        if (response['success'] == true && response['data'] != null) {
          final apiData = response['data'];

          if (apiData.containsKey('employees') &&
              apiData['employees'] is List) {
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

              // Initialize empty attendance and payment data
              if (!attendanceRecords.containsKey(employeeId)) {
                attendanceRecords[employeeId] = {};
              }
              if (!employeePaymentStatus.containsKey(employeeId)) {
                employeePaymentStatus[employeeId] = 'pending';
                employeePartialPayments[employeeId] = 0.0;
                employeeRemainingAmounts[employeeId] = 0.0;
              }
            }

            print('Loaded ${employeeMap.length} active employees as fallback');
          }
        }
      } catch (e) {
        print('Error loading active employees: $e');
      }
    }

    // Convert map back to list
    employees.value = employeeMap.values.toList();

    // Ensure all employees have initialized payment data
    for (var employee in employees) {
      if (!employeePaymentStatus.containsKey(employee.id)) {
        employeePaymentStatus[employee.id] = 'pending';
        employeePartialPayments[employee.id] = 0.0;
        employeeRemainingAmounts[employee.id] = 0.0;
      }
      if (!attendanceRecords.containsKey(employee.id)) {
        attendanceRecords[employee.id] = {};
      }
    }

    print('=== AFTER PROCESSING ===');
    print('Final employees count: ${employees.length}');
    for (int i = 0; i < employees.length; i++) {
      final emp = employees[i];
      print('Final employee $i: ID=${emp.id}, Name="${emp.name}"');
    }

    // Apply employee ordering
    print('Applying employee ordering...');
    _applyEmployeeOrdering();

    print('=== AFTER ORDERING ===');
    print('Ordered employees count: ${employees.length}');
    for (int i = 0; i < employees.length; i++) {
      final emp = employees[i];
      print('Ordered employee $i: ID=${emp.id}, Name="${emp.name}"');
    }

    // Set wage information
    grandTotalWages.value = data.totalWages;
    wagesPaid.value = data.wagesPaid;

    // Calculate counts
    _calculateEmployeeCounts(data);

    print('=== PROCESSING COMPLETE ===');
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

  // MARK: - Attendance Management

  /// Update single employee attendance
  Future<void> updateAttendance(
    String employeeId,
    String employeeName,
    DateTime date,
    int status,
  ) async {
    if (_checkWagesPaidRestriction()) return;
    if (isUpdatingAttendance.value) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    isUpdatingAttendance.value = true;

    try {
      final response = await AttendanceService.updateSingleAttendance(
        employeeId: employeeId,
        employeeName: employeeName,
        date: normalizedDate,
        status: status,
      );

      if (response['success'] == true) {
        // Update local state immediately for better UX
        _updateLocalAttendance(employeeId, normalizedDate, status);

        // Refresh data in background
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

  /// Mark attendance for multiple employees on a specific date
  Future<void> markAttendanceForDate(
    DateTime date,
    List<EmployeeAttendance> employeeAttendances,
  ) async {
    if (_checkWagesPaidRestriction()) return;
    if (isUpdatingAttendance.value) return;

    isUpdatingAttendance.value = true;

    try {
      final response = await AttendanceService.markAttendance(
        date: date,
        employeeAttendances: employeeAttendances,
      );

      if (response['success'] == true) {
        await fetchWeeklyData();
        _showSuccessMessage(
            response['data']['message'] ?? 'Attendance marked successfully');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
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

    print('PAYMENT DEBUG - Starting payment process');
    print('Employee ID: $employeeId');
    print('Amount: $amount');
    print('Current payment status: ${employeePaymentStatus[employeeId]}');
    print('Current partial payment: ${employeePartialPayments[employeeId]}');
    print('Current remaining: ${employeeRemainingAmounts[employeeId]}');

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

      print('Sending API request...');
      final response = await AttendanceService.payWages(request: request);

      print('API Response received:');
      print('Success: ${response['success']}');
      print('Response data: ${response['data']}');

      if (response['success'] == true) {
        print('API call successful, refreshing data...');

        // Store old values for comparison
        final oldStatus = employeePaymentStatus[employeeId] ?? 'pending';
        final oldPartial = employeePartialPayments[employeeId] ?? 0.0;
        final oldRemaining = employeeRemainingAmounts[employeeId] ?? 0.0;

        print('Before fetchWeeklyData:');
        print('  Status: $oldStatus');
        print('  Partial: $oldPartial');
        print('  Remaining: $oldRemaining');

        // Refresh data from backend
        await fetchWeeklyData();

        print('After fetchWeeklyData:');
        print('  Status: ${employeePaymentStatus[employeeId]}');
        print('  Partial: ${employeePartialPayments[employeeId]}');
        print('  Remaining: ${employeeRemainingAmounts[employeeId]}');

        // Check if values actually changed
        final newStatus = employeePaymentStatus[employeeId] ?? 'pending';
        final newPartial = employeePartialPayments[employeeId] ?? 0.0;
        final newRemaining = employeeRemainingAmounts[employeeId] ?? 0.0;

        if (newStatus == oldStatus &&
            newPartial == oldPartial &&
            newRemaining == oldRemaining) {
          print(
              'WARNING: Payment values did not change after fetchWeeklyData!');
          print(
              'This indicates the backend is not returning updated payment data.');

          // Manual update as fallback
          print('Manually updating local state...');
          final totalWages = getTotalWages(employeeId);
          final newTotalPaid = oldPartial + amount;

          employeePartialPayments[employeeId] = newTotalPaid;

          if (newTotalPaid >= totalWages) {
            employeePaymentStatus[employeeId] = 'paid';
            employeeRemainingAmounts[employeeId] = 0.0;
          } else {
            employeePaymentStatus[employeeId] = 'partial';
            employeeRemainingAmounts[employeeId] = totalWages - newTotalPaid;
          }

          // Force UI refresh
          employeePaymentStatus.refresh();
          employeePartialPayments.refresh();
          employeeRemainingAmounts.refresh();

          print('Manual update complete:');
          print('  Status: ${employeePaymentStatus[employeeId]}');
          print('  Partial: ${employeePartialPayments[employeeId]}');
          print('  Remaining: ${employeeRemainingAmounts[employeeId]}');
        } else {
          print('Payment values updated correctly from backend');
        }

        final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
        final employeeName = employee?.name ?? 'Employee';

        _showPaymentSuccessDialog(employeeName, amount);
      } else {
        print('API call failed: ${response}');
        _handleApiError(response);
      }
    } catch (e) {
      print('Payment error: $e');
      _handleException('Failed to process payment', e);
    } finally {
      isProcessingPayment.value = false;
    }
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

  /// Pay all wages for the week
  Future<void> payAllWages({
    String paymentMode = 'Cash',
    String? paymentReference,
    String? remarks,
  }) async {
    if (isProcessingPayment.value) return;

    isProcessingPayment.value = true;

    try {
      final request = WagePaymentRequest(
        amount: 0, // Not used for pay all
        weekStart: selectedWeekStart.value.toDateString(),
        payAll: true,
        paymentMode: paymentMode,
        paymentReference: paymentReference,
        remarks: remarks,
      );

      final response = await AttendanceService.payWages(request: request);

      if (response['success'] == true) {
        await fetchWeeklyData();
        _showPayAllSuccessDialog();
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to pay all wages', e);
    } finally {
      isProcessingPayment.value = false;
    }
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
    if (attendanceRecords[employeeId] == null) {
      attendanceRecords[employeeId] = {};
    }
    attendanceRecords[employeeId]![date] = status;
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
    final message = response['data']?['message'] ?? 'An error occurred';
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
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
