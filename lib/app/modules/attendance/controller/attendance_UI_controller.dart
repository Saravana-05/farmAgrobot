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

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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

  // NEW: Queue for batch API updates
  final Map<String, Map<DateTime, int>> _pendingUpdates = {};
  bool _isSyncingBatch = false;

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

      if (response['success'] == true && response['data'] != null) {
        final rawData = response['data'];
        final weeklyDataModel = WeeklyData.fromJson(rawData);

        weeklyData.value = weeklyDataModel;
        await _processWeeklyData(weeklyDataModel);
        _refreshPaymentUI();

        // Extract and show success message
        String successMsg =
            _extractSuccessMessage(response, 'Weekly data loaded successfully');
        _showSuccessMessage(successMsg);
      } else {
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

  /// Export attendance data to Excel file
  Future<void> exportAttendanceToExcel(
      DateTime fromDate, DateTime toDate) async {
    if (isExporting.value) return;

    // Validate date range
    if (fromDate.isAfter(toDate)) {
      _showErrorMessage('From date must be before or equal to To date');
      return;
    }

    isExporting.value = true;

    try {
      // Check storage permissions
      if (!await _checkStoragePermissions()) {
        _showErrorMessage('Storage permission is required to save Excel files');
        return;
      }

      print(
          '📥 Exporting attendance from ${fromDate.toDateString()} to ${toDate.toDateString()}');

      final response = await AttendanceService.exportAttendanceToExcel(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response['success'] == true) {
        final excelData = response['data'];
        final filename = response['filename'] ?? 'attendance_export.xlsx';

        if (excelData != null && excelData.isNotEmpty) {
          await _saveExcelFile(excelData, filename, fromDate, toDate);
        } else {
          _showErrorMessage('No Excel data received from server');
        }
      } else {
        // Extract and show error message
        String errorMessage =
            response['message'] ?? 'Failed to export attendance';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      print('💥 Export exception: $e');
      _handleException('Failed to export attendance', e);
    } finally {
      isExporting.value = false;
    }
  }

  /// Save Excel file to device storage
  Future<void> _saveExcelFile(
    List<int> excelBytes,
    String filename,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(excelBytes);

      print('✅ Excel file saved: ${file.path}');

      _showExportSuccessDialog(file.path, filename, fromDate, toDate);
    } catch (e) {
      print('❌ Failed to save Excel file: $e');
      _handleException('Failed to save Excel file', e);
    }
  }

  /// Show export success dialog with options
  void _showExportSuccessDialog(
    String filePath,
    String fileName,
    DateTime fromDate,
    DateTime toDate,
  ) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_download_done,
                color: Colors.green.shade600, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Export Successful', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance data has been exported successfully!',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Period: ${DateFormat('dd/MM/yyyy').format(fromDate)} - ${DateFormat('dd/MM/yyyy').format(toDate)}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved to: ${Platform.isAndroid ? "Downloads" : "Documents"}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await _openExcelFile(filePath);
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open File'),
          ),
        ],
      ),
    );
  }

  /// Open Excel file with default app
  Future<void> _openExcelFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        Get.dialog(
          AlertDialog(
            title: const Text('Cannot Open Excel File'),
            content: const Text(
              'No Excel viewer app found. Please install Microsoft Excel, Google Sheets, or WPS Office from the Play Store or App Store to view the exported file.',
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
      _showErrorMessage(
        'Could not open Excel file. Please check if you have an Excel viewer app installed.',
      );
    }
  }

  /// Check and request storage permissions
  Future<bool> _checkStoragePermissions() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), we need to handle differently
      if (Platform.version.contains('11') ||
          Platform.version.contains('12') ||
          Platform.version.contains('13')) {
        // For Android 11+, we can directly write to Download folder
        // No special permission needed for app-specific directories
        return true;
      } else {
        // For older Android versions, request storage permission
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return status.isGranted;
      }
    }
    // iOS doesn't need storage permission for Documents directory
    return true;
  }

  /// Process weekly data and update local state
  Future<void> _processWeeklyData(WeeklyData data) async {
    print('=== STARTING DATA PROCESSING ===');
    print('Total employees from API: ${data.employees.length}');

    _clearLocalData();

    Map<String, EmployeeAttendanceRecord> employeeMap = {};
    int processedCount = 0;
    int skippedCount = 0;

    // NEW: Map to track daily attendance counts
    Map<DateTime, Set<String>> dailyAttendanceTracker = {};

    // STEP 1: Process each employee
    for (int i = 0; i < data.employees.length; i++) {
      try {
        var empData = data.employees[i];

        final employeeId = empData.employeeId?.toString() ?? '';
        final employeeName = empData.employeeName?.toString() ?? 'Unknown';
        final dailyWage = _parseDouble(empData.dailyWage) ?? 0.0;

        if (employeeId.isEmpty) {
          print('⚠️ Warning: Empty employee ID at index $i, skipping');
          skippedCount++;
          continue;
        }

        // Create employee record
        employeeMap[employeeId] = EmployeeAttendanceRecord(
          id: employeeId,
          name: employeeName,
          dailyWage: dailyWage,
          hasWage: true,
        );

        // Initialize attendance records
        attendanceRecords[employeeId] = {};

        // Process attendance
        if (empData.attendance != null && empData.attendance is Map) {
          final attendanceMap = empData.attendance as Map;
          attendanceMap.forEach((key, value) {
            final dateString = key.toString();
            final date = DateTime.tryParse(dateString);

            if (date != null && value != null) {
              int? status;

              // Handle different value types
              if (value is int) {
                status = value;
              } else if (value is String) {
                status = int.tryParse(value);
              } else if (value is double) {
                status = value.toInt();
              } else if (value is Map) {
                final statusValue = value['status'];
                if (statusValue is int) {
                  status = statusValue;
                } else if (statusValue is String) {
                  status = int.tryParse(statusValue);
                } else if (statusValue is double) {
                  status = statusValue.toInt();
                }
              }

              if (status != null && [0, 1, 2, 3].contains(status)) {
                attendanceRecords[employeeId]![date] = status;

                // NEW: Track daily attendance (count only Present, Half Day, Late)
                if (status == 1 || status == 2 || status == 3) {
                  if (!dailyAttendanceTracker.containsKey(date)) {
                    dailyAttendanceTracker[date] = {};
                  }
                  dailyAttendanceTracker[date]!.add(employeeId);
                }
              }
            }
          });
        }

        // Extract payment data from API response
        final paymentStatus = empData.paymentStatus?.toString() ?? 'pending';
        final partialPayment = _parseDouble(empData.partialPayment) ?? 0.0;
        final remainingAmount = _parseDouble(empData.remainingAmount) ?? 0.0;

        // Store payment data
        employeePaymentStatus[employeeId] = paymentStatus;
        employeePartialPayments[employeeId] = partialPayment;
        employeeRemainingAmounts[employeeId] = remainingAmount;

        print(
            '✅ [$i] ${employeeName}: Status=$paymentStatus, Paid=₹$partialPayment, Remaining=₹$remainingAmount');
        processedCount++;
      } catch (e, stackTrace) {
        print('❌ Error processing employee $i: $e');
        print('Stack trace: $stackTrace');
        skippedCount++;
        continue;
      }
    }

    print(
        'Processing Summary: Processed=$processedCount, Skipped=$skippedCount');

    // STEP 2: Fallback if no employees
    if (employeeMap.isEmpty) {
      print('⚠️ No employees processed, loading fallback...');
      await _loadActiveEmployeesAsFallback(employeeMap);
    }

    // STEP 3: Set employees list
    employees.value = employeeMap.values.toList();
    print('Total employees in list: ${employees.length}');

    // STEP 4: Apply ordering
    _applyEmployeeOrdering();

    // STEP 5: Set totals and counts
    grandTotalWages.value = data.totalWages;

    // NEW: Calculate daily employee counts from tracked attendance
    _calculateDailyEmployeeCounts(dailyAttendanceTracker, data);

    // STEP 6: Validate consistency
    _validateAllPaymentData();
    _recalculateWageSummary();

    // STEP 7: Print final summary
    print('=== PROCESSING COMPLETE ===');
    print('Final employees count: ${employees.length}');
    print('Total wages: ₹${grandTotalWages.value}');
    print('Total paid: ₹${getTotalPaidAmount()}');
    print('Total remaining: ₹${getTotalRemainingAmount()}');
    print('Wages fully paid: ${wagesPaid.value}');
    print('Daily counts: ${dailyEmployeeCount.length} days tracked');

    // Print payment status breakdown
    final statusCounts = getPaymentStatusCounts();
    print(
        'Payment breakdown: Paid=${statusCounts['paid']}, Partial=${statusCounts['partial']}, Pending=${statusCounts['pending']}');
  }

  void _calculateDailyEmployeeCounts(
      Map<DateTime, Set<String>> dailyAttendanceTracker, WeeklyData data) {
    dailyEmployeeCount.clear();

    // Option 1: Use API data if available
    if (data.dailyCounts.isNotEmpty) {
      print('Using daily counts from API');
      data.dailyCounts.forEach((dateString, count) {
        final date = DateTime.tryParse(dateString);
        if (date != null) {
          // ✅ CRITICAL: Normalize the date before storing
          final normalizedDate = _normalizeDate(date);
          dailyEmployeeCount[normalizedDate] = count;
          print(
              '  ${DateFormat('dd/MM').format(normalizedDate)}: $count employees (stored with key: $normalizedDate)');
        }
      });
    }
    // Option 2: Calculate from local attendance data
    else {
      print('Calculating daily counts from attendance data');
      dailyAttendanceTracker.forEach((date, employeeIds) {
        // ✅ CRITICAL: Normalize the date before storing
        final normalizedDate = _normalizeDate(date);
        dailyEmployeeCount[normalizedDate] = employeeIds.length;
        print(
            '  ${DateFormat('dd/MM').format(normalizedDate)}: ${employeeIds.length} employees');
      });
    }

    // Set weekly employee count
    if (data.weeklyEmployeeCount > 0) {
      weeklyEmployeeCount.value = data.weeklyEmployeeCount;
    } else {
      Set<String> uniqueEmployees = {};
      dailyAttendanceTracker.values.forEach((employeeIds) {
        uniqueEmployees.addAll(employeeIds);
      });
      weeklyEmployeeCount.value = uniqueEmployees.length;
    }

    print('Weekly employee count: ${weeklyEmployeeCount.value}');
    print('Daily count map keys: ${dailyEmployeeCount.keys.toList()}');

    // ✅ Force UI update
    dailyEmployeeCount.refresh();
  }

  void _recalculateDailyCountsFromRecords() {
    dailyEmployeeCount.clear();

    // For each employee's attendance records
    attendanceRecords.forEach((employeeId, attendanceMap) {
      attendanceMap.forEach((date, status) {
        // Count only Present (1), Half Day (2), and Late (3)
        if (status == 1 || status == 2 || status == 3) {
          // ✅ Date is already normalized in attendanceRecords
          dailyEmployeeCount[date] = (dailyEmployeeCount[date] ?? 0) + 1;
        }
      });
    });

    // Calculate unique employees for the week
    Set<String> uniqueEmployees = {};
    attendanceRecords.forEach((employeeId, attendanceMap) {
      if (attendanceMap.values
          .any((status) => status == 1 || status == 2 || status == 3)) {
        uniqueEmployees.add(employeeId);
      }
    });
    weeklyEmployeeCount.value = uniqueEmployees.length;

    print('Recalculated ${dailyEmployeeCount.length} daily counts');
    print(
        'Daily count map keys after recalc: ${dailyEmployeeCount.keys.toList()}');

    // ✅ Force UI update
    dailyEmployeeCount.refresh();
  }

// Fix getDailyEmployeeCount helper
  int getDailyEmployeeCount(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final count = dailyEmployeeCount[normalizedDate] ?? 0;
    print(
        'getDailyEmployeeCount for ${DateFormat('dd/MM').format(date)}: $count (key: $normalizedDate)');
    return count;
  }

  int getDailyEmployeeCountSafe(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final count = dailyEmployeeCount[normalizedDate] ?? 0;
    print(
        'getDailyEmployeeCountSafe for ${DateFormat('dd/MM/yyyy').format(date)}: $count (key: $normalizedDate)');
    return count;
  }

  void debugDailyCountKeys() {
    print('=== DEBUG DAILY COUNT KEYS ===');
    print('Total entries in dailyEmployeeCount: ${dailyEmployeeCount.length}');
    dailyEmployeeCount.forEach((date, count) {
      print(
          '  Key: $date (${date.hour}:${date.minute}:${date.second}) -> Count: $count');
    });

    print('\n=== CHECKING UI DATE KEYS ===');
    final daysOfWeek = List.generate(
        7, (index) => selectedWeekStart.value.add(Duration(days: index)));
    for (var date in daysOfWeek) {
      final normalized = _normalizeDate(date);
      final count = dailyEmployeeCount[normalized];
      print('  UI date: $normalized -> Count: $count');
    }
    print('================================');
  }

  Map<String, int> getDailyAttendanceBreakdown(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    int present = 0;
    int halfDay = 0;
    int late = 0;
    int absent = 0;

    attendanceRecords.forEach((employeeId, attendanceMap) {
      final status = attendanceMap[normalizedDate];
      if (status != null) {
        switch (status) {
          case 1:
            present++;
            break;
          case 2:
            halfDay++;
            break;
          case 3:
            late++;
            break;
          case 0:
            absent++;
            break;
        }
      }
    });

    return {
      'present': present,
      'halfDay': halfDay,
      'late': late,
      'absent': absent,
      'total': present + halfDay + late,
    };
  }

  /// Force recalculate all daily counts (call after bulk updates)
  void recalculateDailyCounts() {
    print('🔄 Force recalculating daily counts...');
    _recalculateDailyCountsFromRecords();
    dailyEmployeeCount.refresh();
    print('✅ Daily counts refreshed');
  }

  /// NEW: Validate payment data without overwriting API values
  void _validateAllPaymentData() {
    print('=== VALIDATING PAYMENT DATA ===');

    for (var employee in employees) {
      final employeeId = employee.id;

      // Ensure records exist (but DON'T overwrite if they already have values)
      if (!employeePaymentStatus.containsKey(employeeId)) {
        employeePaymentStatus[employeeId] = 'pending';
        print('⚠️ ${employee.name}: No payment status, set to pending');
      }

      if (!employeePartialPayments.containsKey(employeeId)) {
        employeePartialPayments[employeeId] = 0.0;
        print('⚠️ ${employee.name}: No partial payment, set to 0');
      }

      if (!employeeRemainingAmounts.containsKey(employeeId)) {
        final totalWages = getTotalWages(employeeId);
        final partialPayment = employeePartialPayments[employeeId] ?? 0.0;
        employeeRemainingAmounts[employeeId] = totalWages - partialPayment;
        print(
            '⚠️ ${employee.name}: Calculated remaining amount = ₹${employeeRemainingAmounts[employeeId]}');
      }

      if (!attendanceRecords.containsKey(employeeId)) {
        attendanceRecords[employeeId] = {};
      }

      // Validate consistency (fix only if clearly wrong)
      final status = employeePaymentStatus[employeeId]!;
      final paid = employeePartialPayments[employeeId]!;
      final remaining = employeeRemainingAmounts[employeeId]!;
      final total = getTotalWages(employeeId);

      // Check for inconsistencies
      if (status == 'paid' && remaining > 0.01) {
        print(
            '⚠️ ${employee.name}: Status is paid but has remaining ₹$remaining - fixing');
        employeeRemainingAmounts[employeeId] = 0.0;
        employeePartialPayments[employeeId] = total;
      } else if (status == 'pending' && paid > 0.01) {
        print(
            '⚠️ ${employee.name}: Status is pending but has payment ₹$paid - fixing to partial');
        employeePaymentStatus[employeeId] = 'partial';
      }
    }

    print('✅ Payment data validation complete');
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
      final totalWages = getTotalWages(employee.id);

      if (!employeePaymentStatus.containsKey(employee.id)) {
        employeePaymentStatus[employee.id] =
            totalWages > 0 ? 'pending' : 'pending';
      }

      if (!employeePartialPayments.containsKey(employee.id)) {
        employeePartialPayments[employee.id] = 0.0;
      }

      if (!employeeRemainingAmounts.containsKey(employee.id)) {
        final partialPayment = employeePartialPayments[employee.id] ?? 0.0;
        final remaining = totalWages - partialPayment;
        employeeRemainingAmounts[employee.id] = remaining > 0 ? remaining : 0.0;
      }

      if (!attendanceRecords.containsKey(employee.id)) {
        attendanceRecords[employee.id] = {};
      }

      _validatePaymentDataConsistency(employee.id);
    }
  }

  /// Validate payment data consistency for an employee
  void _validatePaymentDataConsistency(String employeeId) {
    final totalWages = getTotalWages(employeeId);
    final partialPayment = employeePartialPayments[employeeId] ?? 0.0;
    final remainingAmount = employeeRemainingAmounts[employeeId] ?? 0.0;
    final paymentStatus = employeePaymentStatus[employeeId] ?? 'pending';

    final expectedRemaining = totalWages - partialPayment;

    if ((expectedRemaining - remainingAmount).abs() > 0.01) {
      employeeRemainingAmounts[employeeId] =
          expectedRemaining > 0 ? expectedRemaining : 0.0;
    }

    if (totalWages > 0 &&
        partialPayment >= totalWages &&
        paymentStatus != 'paid') {
      employeePaymentStatus[employeeId] = 'paid';
      employeeRemainingAmounts[employeeId] = 0.0;
    } else if (totalWages == 0) {
      employeePaymentStatus[employeeId] = 'pending';
      employeePartialPayments[employeeId] = 0.0;
      employeeRemainingAmounts[employeeId] = 0.0;
    } else if (partialPayment > 0 &&
        partialPayment < totalWages &&
        paymentStatus != 'partial') {
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

  // NEW: ULTRA-FAST ATTENDANCE UPDATE METHOD
  /// Update attendance instantly in UI, sync to backend asynchronously
  void updateAttendanceInstant(
      String employeeId, String employeeName, DateTime date, int status) {
    // Validation checks
    if (employeeId.isEmpty ||
        employeeName.isEmpty ||
        ![0, 1, 2, 3].contains(status)) {
      return;
    }

    if (_checkWagesPaidRestriction()) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);

    // STEP 1: Update UI immediately (no waiting)
    _updateLocalAttendanceInstant(employeeId, normalizedDate, status);

    // ✅ Recalculate daily counts immediately
    _recalculateDailyCountsFromRecords();

    // STEP 2: Queue the update for backend sync
    _queueBackendUpdate(employeeId, employeeName, normalizedDate, status);

    // STEP 3: Recalculate wages immediately for instant UI feedback
    _recalculateEmployeeWages(employeeId);
  }

  /// Update local attendance instantly without any delay
  void _updateLocalAttendanceInstant(
      String employeeId, DateTime date, int status) {
    // Ensure attendance record exists
    if (!attendanceRecords.containsKey(employeeId)) {
      attendanceRecords[employeeId] = {};
    }

    // Update the record
    attendanceRecords[employeeId]![date] = status;

    // Force UI refresh
    attendanceRecords.refresh();
  }

  /// Queue backend update for batch processing
  void _queueBackendUpdate(
      String employeeId, String employeeName, DateTime date, int status) {
    // Add to pending updates
    if (!_pendingUpdates.containsKey(employeeId)) {
      _pendingUpdates[employeeId] = {};
    }
    _pendingUpdates[employeeId]![date] = status;

    // Trigger batch sync after a short delay (debounce)
    _debouncedBatchSync(employeeId, employeeName);
  }

  /// Debounced batch sync to avoid too many API calls
  void _debouncedBatchSync(String employeeId, String employeeName) async {
    // Wait for 500ms to batch multiple rapid changes
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isSyncingBatch) return;
    _isSyncingBatch = true;

    try {
      // Get all pending updates for this employee
      final updates = _pendingUpdates[employeeId];
      if (updates == null || updates.isEmpty) {
        _isSyncingBatch = false;
        return;
      }

      // Sync each update to backend
      for (var entry in updates.entries) {
        await _syncToBackend(employeeId, employeeName, entry.key, entry.value);
      }

      // Clear pending updates for this employee
      _pendingUpdates.remove(employeeId);
    } catch (e) {
      print('Error in batch sync: $e');
    } finally {
      _isSyncingBatch = false;
    }
  }

  /// Sync single attendance update to backend
  Future<void> _syncToBackend(
      String employeeId, String employeeName, DateTime date, int status) async {
    try {
      final response = await AttendanceService.updateSingleAttendance(
        employeeId: employeeId,
        employeeName: employeeName,
        date: date,
        status: status,
      );

      if (response['success'] == true) {
        print(
            '✓ Synced: $employeeName - ${DateFormat('dd/MM').format(date)} - Status: $status');

        // Show success message if available
        String successMsg = _extractSuccessMessage(response, '');
        if (successMsg.isNotEmpty) {
          print('Backend message: $successMsg');
        }
      } else {
        print(
            '✗ Sync failed: $employeeName - ${DateFormat('dd/MM').format(date)}');

        // Extract error message using helper method
        String errorMessage =
            _extractErrorMessage(response, 'Failed to update attendance');

        // Revert local change with backend error message
        _revertLocalAttendance(employeeId, date, errorMessage);
      }
    } catch (e) {
      print('✗ Sync error: $e');

      // Revert with exception message
      String errorMessage = 'Network error: ${e.toString()}';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      }

      _revertLocalAttendance(employeeId, date, errorMessage);
    }
  }

  /// Revert local attendance if backend sync fails
  void _revertLocalAttendance(String employeeId, DateTime date,
      [String? errorMessage]) {
    // Remove the failed update
    if (attendanceRecords.containsKey(employeeId)) {
      attendanceRecords[employeeId]!.remove(date);
      attendanceRecords.refresh();
    }

    // Recalculate daily counts after reverting
    _recalculateDailyCountsFromRecords();

    // Show backend error message or fallback
    final displayMessage =
        errorMessage ?? 'Failed to update attendance. Please try again.';
    _showErrorMessage(displayMessage);
  }

  /// Recalculate wages for a specific employee instantly
  void _recalculateEmployeeWages(String employeeId) {
    final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
    if (employee == null) return;

    // This will trigger UI update for wages column
    employees.refresh();

    // Recalculate grand total
    _recalculateGrandTotal();
  }

  /// Recalculate grand total wages
  void _recalculateGrandTotal() {
    double total = 0.0;
    for (var employee in employees) {
      total += getTotalWages(employee.id);
    }
    grandTotalWages.value = total;
  }

  // Keep original method for backwards compatibility
  Future<void> updateAttendance(
      String employeeId, String employeeName, DateTime date, int status) async {
    // Just call the instant version
    updateAttendanceInstant(employeeId, employeeName, date, status);
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
        _showSuccessMessage('Statistics loaded successfully');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to fetch attendance statistics', e);
    }
  }

  /// Mark attendance for multiple employees on a specific date
  Future<void> markAttendanceForDate(
      DateTime date, List<EmployeeAttendance> employeeAttendances) async {
    if (employeeAttendances.isEmpty) {
      _showErrorMessage('No attendance data to mark');
      return;
    }

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
      final response = await AttendanceService.markAttendance(
        date: date,
        employeeAttendances: employeeAttendances,
      );

      if (response != null && response['success'] == true) {
        // Update local attendance
        for (var attendance in employeeAttendances) {
          _updateLocalAttendance(
              attendance.employeeId, date, attendance.status);
        }

        await fetchWeeklyData();

        // Extract and show backend success message
        String successMessage =
            _extractSuccessMessage(response, 'Attendance marked successfully');
        _showSuccessMessage(successMessage);
      } else {
        if (response == null) {
          throw Exception('No response received from server');
        } else {
          // Use helper method to extract error
          String errorMessage =
              _extractErrorMessage(response, 'Failed to mark attendance');
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      _handleException('Failed to mark attendance', e);
    } finally {
      isUpdatingAttendance.value = false;
    }
  }

  /// Update attendance for multiple employees
  Future<void> updateAttendanceForDate(
      DateTime date, List<EmployeeAttendance> employeeAttendances) async {
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

        // Extract and show backend success message
        String successMessage =
            _extractSuccessMessage(response, 'Attendance updated successfully');
        _showSuccessMessage(successMessage);
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to update attendance', e);
    } finally {
      isUpdatingAttendance.value = false;
    }
  }

  Future<bool> checkServiceHealth() async {
    try {
      return true;
    } catch (e) {
      print('Service health check failed: $e');
      return false;
    }
  }

  bool validateAttendanceData(String employeeId, DateTime date, int status) {
    final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
    if (employee == null) {
      _showErrorMessage('Employee not found: $employeeId');
      return false;
    }

    if (date.isAfter(DateTime.now())) {
      _showErrorMessage('Cannot mark attendance for future dates');
      return false;
    }

    if (![0, 1, 2, 3].contains(status)) {
      _showErrorMessage('Invalid attendance status: $status');
      return false;
    }

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
  Future<void> payEmployeeWages(String employeeId, double amount,
      {String paymentMode = 'Cash',
      String? paymentReference,
      String? remarks}) async {
    if (isProcessingPayment.value) return;
    isProcessingPayment.value = true;

    try {
      print('💰 ========== PAYMENT START ==========');

      final request = WagePaymentRequest(
        employeeId: employeeId,
        amount: amount,
        paymentMode: paymentMode,
        paymentReference: paymentReference,
        remarks: remarks,
        weekStart: selectedWeekStart.value.toDateString(),
        payAll: false,
      );

      final response = await AttendanceService.payWages(request: request);

      if (response['success'] == true) {
        final employee = employees.firstWhereOrNull((e) => e.id == employeeId);
        final employeeName = employee?.name ?? 'Employee';

        // Extract success message from backend
        String successMessage =
            _extractSuccessMessage(response, 'Payment processed successfully');

        // Show custom dialog with backend message
        _showPaymentSuccessDialog(employeeName, amount, successMessage);

        await Future.delayed(const Duration(milliseconds: 500));
        await fetchWeeklyData();

        print('💰 ========== PAYMENT COMPLETE ==========');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      print('💥 Payment exception: $e');
      _handleException('Failed to process payment', e);
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _updatePaymentStatusFromResponse(
      String employeeId, Map<String, dynamic> responseData) {
    try {
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

      if (responseData.containsKey('employee')) {
        final empData = responseData['employee'];
        employeePaymentStatus[employeeId] =
            empData['payment_status'] ?? 'pending';
        employeePartialPayments[employeeId] =
            double.tryParse(empData['partial_payment'].toString()) ?? 0.0;
        employeeRemainingAmounts[employeeId] =
            double.tryParse(empData['remaining_amount'].toString()) ?? 0.0;
      }
    } catch (e) {
      print('Error updating payment status from response: $e');
    }
  }

  bool _validateBulkPaymentConditions() {
    if (employees.isEmpty) {
      _showErrorMessage('No employees found for the selected week');
      return false;
    }

    if (wagesPaid.value) {
      _showErrorMessage('All wages have already been paid for this week');
      return false;
    }

    double totalUnpaid = getTotalRemainingAmount();
    if (totalUnpaid <= 0) {
      _showErrorMessage('No pending payments found for this week');
      return false;
    }

    if (grandTotalWages.value <= 0) {
      _showErrorMessage(
          'Total wages amount is invalid: ₹${grandTotalWages.value}');
      return false;
    }

    return true;
  }

  void _refreshPaymentUI() {
    employeePaymentStatus.refresh();
    employeePartialPayments.refresh();
    employeeRemainingAmounts.refresh();
    _recalculateWageSummary();
    employees.refresh();
  }

  void _recalculateWageSummary() {
    double totalPaid = 0.0;
    int employeesWithWages = 0;
    int employeesFullyPaid = 0;

    for (var employee in employees) {
      final totalWages = getTotalWages(employee.id);
      final paidAmount = getPartialPayment(employee.id);
      final remainingAmount = getRemainingAmount(employee.id);

      totalPaid += paidAmount;

      // Only count employees who have wages to be paid
      if (totalWages > 0) {
        employeesWithWages++;

        // Check if this employee is fully paid (remaining is 0 or negligible)
        if (remainingAmount <= 0.01) {
          employeesFullyPaid++;
        }
      }
    }

    wagesPaid.value =
        (employeesWithWages > 0) && (employeesFullyPaid == employeesWithWages);

    print(
        ' Wage Summary: Employees with wages: $employeesWithWages, Fully paid: $employeesFullyPaid, All paid: ${wagesPaid.value}');

    // Force UI refresh
    wagesPaid.refresh();
  }

  Future<void> payAllWages(
      {String paymentMode = 'Cash',
      String? paymentReference,
      String? remarks}) async {
    if (isProcessingPayment.value) return;

    if (!_validateBulkPaymentConditions()) return;

    isProcessingPayment.value = true;

    try {
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

      final response = await AttendanceService.payWages(request: request);

      if (response['success'] == true) {
        await _handleSuccessfulBulkPayment(response['data']);
      } else {
        await _handleBulkPaymentError(response);
      }
    } catch (e) {
      _handleException('Failed to process bulk payment', e);
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<void> _handleBulkPaymentError(Map<String, dynamic> response) async {
    final statusCode = response['statusCode'];
    final errorData = response['data'] ?? {};
    String errorMessage =
        errorData['error'] ?? errorData['message'] ?? 'Unknown error';

    switch (statusCode) {
      case 400:
        if (errorMessage.contains('No pending payments')) {
          await _handleNoPendingPaymentsError();
        } else {
          _showErrorMessage('Invalid request: $errorMessage');
        }
        break;
      case 404:
        _showErrorMessage('Week data not found. Please refresh and try again.');
        await fetchWeeklyData();
        break;
      case 500:
        _showErrorMessage('Server error occurred. Please try again later.');
        break;
      default:
        _handleApiError(response);
    }
  }

  Future<void> _handleNoPendingPaymentsError() async {
    await fetchWeeklyData();

    if (getTotalRemainingAmount() > 0) {
      Get.dialog(
        AlertDialog(
          title: const Text('Data Synchronization Issue'),
          content: const Text(
              'There seems to be a mismatch between local and server data. The data has been refreshed. Please try the payment again.'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
    } else {
      Get.dialog(
        AlertDialog(
          title: const Text('All Payments Complete'),
          content: const Text(
              'All wages for this week have already been paid. The payment status has been updated.'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _handleSuccessfulBulkPayment(
      Map<String, dynamic>? responseData) async {
    print(' Payment successful, refreshing data...');

    // CRITICAL: Fetch fresh data
    await fetchWeeklyData();

    print('✅ Data refreshed after bulk payment');

    if (responseData != null) {
      _showBulkPaymentSuccessDialog(responseData);
    } else {
      _showSuccessMessage('All wages paid successfully!');
    }
  }

  void _showBulkPaymentSuccessDialog(Map<String, dynamic> responseData) {
    // Extract message from response
    String message = responseData['message']?.toString() ??
        'All pending wages have been paid successfully!';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 8),
            const Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (responseData['total_amount_paid'] != null)
              Text('Total Amount Paid: ₹${responseData['total_amount_paid']}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            if (responseData['total_employees'] != null)
              Text('Total Employees: ${responseData['total_employees']}'),
            if (responseData['week_start_date'] != null)
              Text('Week: ${responseData['week_start_date']}'),
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

// Enhanced payment success dialog
  void _showPaymentSuccessDialog(String employeeName, double amount,
      [String? customMessage]) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 8),
            const Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customMessage != null) ...[
              Text(customMessage, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
            ],
            Text('Employee: $employeeName',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Amount Paid: ₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold)),
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

  Future<void> forceRefreshWeeklyData() async {
    weeklyData.value = null;
    _clearLocalData();
    await fetchWeeklyData();
  }

  Future<void> syncEmployeesForCurrentWeek() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      await fetchWeeklyData();
      _showSuccessMessage('Employees synchronized successfully');
    } catch (e) {
      _handleException('Failed to sync employees', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateWeeklyWagePdf() async {
    if (isPdfGenerating.value) return;
    isPdfGenerating.value = true;

    try {
      if (!await _checkStoragePermissions()) {
        _showErrorMessage('Storage permission is required to save PDF files');
        return;
      }

      final response = await AttendanceService.generateWeeklyWagePdf(
          weekStart: selectedWeekStart.value);

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

  Future<void> _savePdfFile(List<int> pdfBytes, DateTime weekStart) async {
    try {
      final fileName =
          'weekly_wages_${DateFormat('yyyy_MM_dd').format(weekStart)}.pdf';
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null)
        throw Exception('Could not access storage directory');

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      _showPdfSuccessDialog(file.path, fileName);
    } catch (e) {
      _handleException('Failed to save PDF file', e);
    }
  }

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
                    child: Text(fileName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Saved to: ${Platform.isAndroid ? "Downloads" : "Documents"}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
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

  Future<void> _openPdfFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        Get.dialog(
          AlertDialog(
            title: const Text('Cannot Open PDF'),
            content: const Text(
                'No PDF viewer app found. Please install a PDF reader app from the Play Store or App Store to view the generated PDF.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorMessage(
          'Could not open PDF file. Please check if you have a PDF viewer installed.');
    }
  }

  Future<void> generateAndSharePdf() async {
    if (isPdfGenerating.value) return;
    isPdfGenerating.value = true;

    try {
      final response = await AttendanceService.generateWeeklyWagePdf(
          weekStart: selectedWeekStart.value);

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

  Future<void> _sharePdfFile(List<int> pdfBytes, DateTime weekStart) async {
    try {
      final fileName =
          'weekly_wages_${DateFormat('yyyy_MM_dd').format(weekStart)}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      _showSuccessMessage(
          'PDF generated successfully. File saved to temporary storage.');
    } catch (e) {
      _handleException('Failed to share PDF file', e);
    }
  }

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

  Future<void> fetchWageSummary() async {
    try {
      final response = await AttendanceService.getWageSummary(
          weekStart: selectedWeekStart.value);

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

  void previousWeek() {
    selectedWeekStart.value =
        selectedWeekStart.value.subtract(const Duration(days: 7));
    fetchWeeklyData();
  }

  void nextWeek() {
    final now = DateTime.now();
    final nextWeekStart = selectedWeekStart.value.add(const Duration(days: 7));
    if (!nextWeekStart.isAfter(now.mondayOfWeek)) {
      selectedWeekStart.value = nextWeekStart;
      fetchWeeklyData();
    }
  }

  void goToCurrentWeek() {
    selectedWeekStart.value = DateTime.now().mondayOfWeek;
    fetchWeeklyData();
  }

  void goToWeek(DateTime weekStart) {
    selectedWeekStart.value = weekStart.mondayOfWeek;
    fetchWeeklyData();
  }

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
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = customEmployeeOrder.removeAt(oldIndex);
                  customEmployeeOrder.insert(newIndex, item);
                },
              )),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
              onPressed: _resetEmployeeOrder, child: const Text('Reset')),
          ElevatedButton(
              onPressed: _saveEmployeeOrder, child: const Text('Save Order')),
        ],
      ),
    );
  }

  bool _checkWagesPaidRestriction() {
    if (wagesPaid.value) {
      Get.dialog(
        AlertDialog(
          title: const Text("Cannot Modify"),
          content: const Text(
              "Wages have already been paid for this week. You cannot update attendance."),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("OK")),
          ],
        ),
      );
      return true;
    }
    return false;
  }

  void _clearLocalData() {
    employees.clear();
    attendanceRecords.clear();
    employeePaymentStatus.clear();
    employeePartialPayments.clear();
    employeeRemainingAmounts.clear();
    dailyEmployeeCount.clear();
  }

  void _updateLocalAttendance(String employeeId, DateTime date, int status) {
    try {
      if (employeeId.isEmpty || ![0, 1, 2, 3].contains(status)) return;

      if (attendanceRecords[employeeId] == null) {
        attendanceRecords[employeeId] = {};
      }

      attendanceRecords[employeeId]![date] = status;
      attendanceRecords.refresh();
    } catch (e) {
      print('Error in _updateLocalAttendance: $e');
    }
  }

  void _applyEmployeeOrdering() {
    if (!useCustomOrder.value || customEmployeeOrder.isEmpty) {
      employees.sort((a, b) => a.name.compareTo(b.name));
    } else {
      _applyCustomOrder();
    }
  }

  void _applyCustomOrder() {
    final reorderedEmployees = <EmployeeAttendanceRecord>[];

    for (String employeeId in customEmployeeOrder) {
      try {
        final employee = employees.firstWhere((e) => e.id == employeeId);
        reorderedEmployees.add(employee);
      } catch (e) {}
    }

    for (EmployeeAttendanceRecord employee in employees) {
      if (!customEmployeeOrder.contains(employee.id)) {
        reorderedEmployees.add(employee);
      }
    }

    employees.value = reorderedEmployees;
  }

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

  void _resetEmployeeOrder() {
    customEmployeeOrder.value = employees.map((e) => e.id).toList();
    employees.sort((a, b) => a.name.compareTo(b.name));
    saveEmployeeOrder();
    Get.back();
    useCustomOrder.value = false;
  }

  void _saveEmployeeOrder() {
    saveEmployeeOrder();
    Get.back();
    useCustomOrder.value = true;
    _applyCustomOrder();
  }

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
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

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

  void _handleApiError(Map<String, dynamic> response) {
    String message = 'An error occurred';

    // Try to extract error message from various possible locations
    if (response['data'] != null) {
      if (response['data'] is Map) {
        final data = response['data'] as Map;

        // Check for 'message' in data
        if (data['message'] != null) {
          message = data['message'].toString();
        }
        // Check for 'error' in data
        else if (data['error'] != null) {
          message = data['error'].toString();
        }
      }
      // If data is a string
      else if (response['data'] is String) {
        message = response['data'].toString();
      }
    }
    // Check top-level 'error' field
    else if (response['error'] != null) {
      message = response['error'].toString();
    }
    // Check top-level 'message' field
    else if (response['message'] != null) {
      message = response['message'].toString();
    }
    // Check for 'errors' array/map
    else if (response['errors'] != null) {
      if (response['errors'] is Map) {
        final errors = response['errors'] as Map;
        message = errors.values.join(', ');
      } else if (response['errors'] is List) {
        message = (response['errors'] as List).join(', ');
      }
    }

    _showErrorMessage(message);

    // Log for debugging
    print('❌ API Error: $message');
    print('Full response: $response');
  }

  void _handleException(String context, dynamic error) {
    Get.snackbar(
      'Error',
      '$context: ${error.toString()}',
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _extractSuccessMessage(
      Map<String, dynamic> response, String defaultMessage) {
    // Try data.message first
    if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }

    // Try top-level message
    if (response['message'] != null) {
      return response['message'].toString();
    }

    return defaultMessage;
  }

  String _extractErrorMessage(
      Map<String, dynamic> response, String defaultMessage) {
    // Try data.message first
    if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['message'] != null) {
        return data['message'].toString();
      }
      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    // Try top-level error
    if (response['error'] != null) {
      return response['error'].toString();
    }

    // Try top-level message
    if (response['message'] != null) {
      return response['message'].toString();
    }

    // Try errors array/map
    if (response['errors'] != null) {
      if (response['errors'] is Map) {
        final errors = response['errors'] as Map;
        return errors.values.join(', ');
      } else if (response['errors'] is List) {
        return (response['errors'] as List).join(', ');
      }
    }

    return defaultMessage;
  }

  Future<void> saveEmployeeOrder() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _showSuccessMessage('Employee order saved successfully');
    } catch (e) {
      _handleException('Failed to save employee order', e);
    }
  }

  Future<void> loadEmployeeOrder() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      customEmployeeOrder.value = [];
      useCustomOrder.value = false;
    } catch (e) {
      _handleException('Failed to load employee order', e);
    }
  }

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

  bool get allEmployeesPaid => employees
      .every((employee) => employeePaymentStatus[employee.id] == 'paid');

  double getRemainingAmount(String employeeId) =>
      employeeRemainingAmounts[employeeId] ?? 0.0;

  String getPaymentStatus(String employeeId) =>
      employeePaymentStatus[employeeId] ?? 'pending';

  double getPartialPayment(String employeeId) =>
      employeePartialPayments[employeeId] ?? 0.0;

  bool get canNavigateNext {
    final nextWeekStart = selectedWeekStart.value.add(const Duration(days: 7));
    return !nextWeekStart.isAfter(DateTime.now().mondayOfWeek);
  }

  String get formattedWeekRange {
    final start = selectedWeekStart.value;
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
  }

  int getTotalPresentDays(String employeeId) {
    if (attendanceRecords[employeeId] == null) return 0;
    return attendanceRecords[employeeId]!
        .values
        .where((status) => status == 1 || status == 2)
        .length;
  }

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
    super.onClose();
  }

  double getTotalPaidAmount() {
    double totalPaid = 0.0;
    for (var employee in employees) {
      totalPaid += getPartialPayment(employee.id);
    }
    return totalPaid;
  }

  double getTotalRemainingAmount() =>
      grandTotalWages.value - getTotalPaidAmount();

  bool get hasUnpaidEmployees =>
      employees.any((employee) => getRemainingAmount(employee.id) > 0);

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

    return {'paid': paid, 'partial': partial, 'pending': pending};
  }

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

    employeePaymentStatus.refresh();
    employeeRemainingAmounts.refresh();
    employeePartialPayments.refresh();
  }
}
