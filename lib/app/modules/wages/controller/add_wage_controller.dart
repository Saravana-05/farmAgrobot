import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/services/employee/emp_service.dart';
import '../../../data/services/messages/message_service.dart';
import '../../../data/services/wages/wages_service.dart';
import '../../../routes/app_pages.dart';

class AddWageController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var isLoadingEmployees = false.obs;
  var selectedIndex = 0.obs;

  // Multiple employees selection
  var selectedEmployees = <Employee>[].obs;

  // Add reactive variables for form updates
  var effectiveFromDate = ''.obs;
  var effectiveToDate = ''.obs;
  var amountText = ''.obs;

  // Text controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController effectiveFromController = TextEditingController();
  final TextEditingController effectiveToController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  // Employee list for dropdown
  final RxList<Employee> employees = <Employee>[].obs;

  @override
  void onInit() {
    super.onInit();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    effectiveFromController.text = today;
    effectiveFromDate.value = today;

    // Listen to text controller changes for reactive updates
    amountController.addListener(() {
      amountText.value = amountController.text;
    });

    effectiveFromController.addListener(() {
      effectiveFromDate.value = effectiveFromController.text;
    });

    effectiveToController.addListener(() {
      effectiveToDate.value = effectiveToController.text;
    });

    _loadEmployees();
  }

  @override
  void onClose() {
    amountController.dispose();
    effectiveFromController.dispose();
    effectiveToController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  // Multiselect employee methods
  void addSelectedEmployee(Employee employee) {
    if (!isEmployeeSelected(employee)) {
      selectedEmployees.add(employee);
      print("✅ Added employee: ${employee.name} (ID: ${employee.id})");
      print("Total selected: ${selectedEmployees.length}");
    }
  }

  void removeSelectedEmployee(Employee employee) {
    selectedEmployees.removeWhere((emp) => emp.id == employee.id);
    print("❌ Removed employee: ${employee.name} (ID: ${employee.id})");
    print("Total selected: ${selectedEmployees.length}");
  }

  bool isEmployeeSelected(Employee employee) {
    return selectedEmployees.any((emp) => emp.id == employee.id);
  }

  void selectAllEmployees() {
    selectedEmployees.clear();
    selectedEmployees.addAll(employees);
    print("✅ Selected all ${employees.length} employees");
  }

  void clearAllSelectedEmployees() {
    selectedEmployees.clear();
    print("❌ Cleared all selected employees");
  }

  // Employee preview for multiselect
  String get employeePreview {
    if (selectedEmployees.isEmpty) {
      return 'No employees selected';
    } else if (selectedEmployees.length == 1) {
      return selectedEmployees.first.name;
    } else {
      return '${selectedEmployees.length} employees selected';
    }
  }

  /// Load employees for dropdown selection - Updated to fetch ALL employees
  Future<void> _loadEmployees() async {
    try {
      isLoadingEmployees.value = true;
      print("Starting to load all employees...");

      // Try to get all employees by setting a high limit or using pagination
      Map<String, dynamic> result = await _getAllEmployeesWithPagination();
      print("API Result: $result");

      debugApiResponse(result);

      if (result.isEmpty) {
        print("Error: Empty result from API");
        MessageService.to.showError(
            'error_loading_employees', 'No data received from server');
        return;
      }

      bool isSuccess = result['success'] == true || result['success'] == 'true';

      if (isSuccess) {
        List<dynamic> employeeData = [];
        print("Attempting to extract employees from nested structure...");

        if (result['data'] != null && result['data'] is Map) {
          var outerData = result['data'] as Map<String, dynamic>;
          print("Outer data keys: ${outerData.keys}");

          if (outerData['data'] != null && outerData['data'] is Map) {
            var innerData = outerData['data'] as Map<String, dynamic>;
            print("Inner data keys: ${innerData.keys}");

            if (innerData['employees'] != null &&
                innerData['employees'] is List) {
              employeeData = List<dynamic>.from(innerData['employees']);
              print("Found employees list with ${employeeData.length} items");
            } else {
              print("No employees list found in inner data");
              print("Inner data structure: $innerData");
            }
          } else {
            print("No inner 'data' field found or it's not a Map");
            print("Outer data structure: $outerData");
          }
        } else {
          print("No outer 'data' field found or it's not a Map");
        }

        print("Employee data found: ${employeeData.length} employees");

        if (employeeData.isEmpty) {
          print("Warning: No employees found in response");
          MessageService.to
              .showError('no_employees_found', 'No employees found');
          employees.clear();
          return;
        }

        List<Employee> validEmployees = [];

        for (var json in employeeData) {
          try {
            Employee emp = Employee.fromJson(json);
            if (emp.status == true) {
              validEmployees.add(emp);
            }
          } catch (e) {
            print("Error parsing employee: $json, Error: $e");
          }
        }

        employees.value = validEmployees;
        print("Successfully loaded ${validEmployees.length} active employees");

        if (validEmployees.isEmpty) {
          MessageService.to
              .showError('no_active_employees', 'No active employees found');
        }
      } else {
        String errorMessage = 'Failed to load employees';

        if (result['message'] != null) {
          errorMessage = result['message'];
        } else if (result['error'] != null) {
          errorMessage = result['error'];
        } else if (result['data'] != null &&
            result['data']['message'] != null) {
          errorMessage = result['data']['message'];
        }

        print("API Error: $errorMessage");
        MessageService.to.showError('error_loading_employees', errorMessage);
      }
    } catch (e) {
      print('Exception in _loadEmployees: $e');
      print('Stack trace: ${StackTrace.current}');

      String errorMessage = 'Error loading employees';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Please try again';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Data format error: Invalid response from server';
      } else {
        errorMessage = 'Error loading employees: ${e.toString()}';
      }

      MessageService.to.showError('error_loading_employees', errorMessage);
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  /// Helper method to get all employees using pagination
  Future<Map<String, dynamic>> _getAllEmployeesWithPagination() async {
    List<dynamic> allEmployees = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      // Call your employee service with pagination
      Map<String, dynamic> result = await EmployeeService.getEmployeeList(
        page: currentPage,
        limit: 100, // Fetch 100 at a time to reduce API calls
      );

      if (result['success'] == true) {
        // Extract employees from current page
        if (result['data'] != null && result['data']['data'] != null) {
          var pageData = result['data']['data'];

          if (pageData['employees'] != null) {
            allEmployees.addAll(pageData['employees']);
          }

          // Check if there are more pages
          if (pageData['pagination'] != null) {
            totalPages = pageData['pagination']['total_pages'] ?? 1;
            print(
                "Page $currentPage of $totalPages loaded, ${pageData['employees']?.length ?? 0} employees");
          } else {
            // If no pagination info, assume this is the last page
            break;
          }
        } else {
          break;
        }
      } else {
        // If any page fails, return the error
        return result;
      }

      currentPage++;
    } while (currentPage <= totalPages);

    print("Total employees loaded across all pages: ${allEmployees.length}");

    // Return in the same format as the original API response
    return {
      'success': true,
      'data': {
        'data': {'employees': allEmployees}
      }
    };
  }

  Future<void> refreshEmployeesManually() async {
    employees.clear();
    selectedEmployees.clear();
    await _loadEmployees();
  }

  void debugApiResponse(Map<String, dynamic> result) {
    print("=== DETAILED API RESPONSE DEBUG ===");
    print("Full result: $result");
    print("Result type: ${result.runtimeType}");
    print("Result keys: ${result.keys.toList()}");

    result.forEach((key, value) {
      print("Key: '$key' | Type: ${value.runtimeType} | Value: $value");

      if (value is Map) {
        print("  Nested Map keys: ${(value as Map).keys.toList()}");
        (value as Map).forEach((nestedKey, nestedValue) {
          print("    '$nestedKey': ${nestedValue.runtimeType} | $nestedValue");
        });
      } else if (value is List) {
        print("  List length: ${(value as List).length}");
        if ((value as List).isNotEmpty) {
          print("  First item type: ${(value as List).first.runtimeType}");
          print("  First item: ${(value as List).first}");
        }
      }
    });
    print("=== END DEBUG ===");
  }

  Future<bool> checkEmployeeServiceHealth() async {
    try {
      Map<String, dynamic> result = await EmployeeService.getEmployeeList();
      return result.isNotEmpty;
    } catch (e) {
      print('Employee service health check failed: $e');
      return false;
    }
  }

  /// Select effective from date
  Future<void> selectEffectiveFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      effectiveFromController.text = formattedDate;
      effectiveFromDate.value = formattedDate;

      if (effectiveToController.text.isNotEmpty) {
        DateTime effectiveTo = DateTime.parse(effectiveToController.text);
        if (effectiveTo.isBefore(picked)) {
          effectiveToController.clear();
          effectiveToDate.value = '';
        }
      }
    }
  }

  /// Select effective to date
  Future<void> selectEffectiveToDate() async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime.now();

    if (effectiveFromController.text.isNotEmpty) {
      firstDate = DateTime.parse(effectiveFromController.text);
      if (firstDate.isAfter(initialDate)) {
        initialDate = firstDate;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
      helpText: 'Select End Date (Optional)',
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      effectiveToController.text = formattedDate;
      effectiveToDate.value = formattedDate;
    }
  }

  /// Clear effective to date
  void clearEffectiveToDate() {
    effectiveToController.clear();
    effectiveToDate.value = '';
  }

  /// Validate form data for multiple employees
  bool _validateForm() {
    // Employee validation - checks for multiple employees
    if (selectedEmployees.isEmpty) {
      MessageService.to
          .showError('validation_error', 'Please select at least one employee');
      return false;
    }

    // Amount validation
    if (amountController.text.trim().isEmpty) {
      MessageService.to.showAmountValidationError();
      return false;
    }

    double? amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      MessageService.to.showAmountInvalidError();
      return false;
    }

    // Effective from date validation
    if (effectiveFromController.text.trim().isEmpty) {
      MessageService.to.showEffectiveFromValidationError();
      return false;
    }

    // Date range validation
    if (effectiveToController.text.trim().isNotEmpty) {
      try {
        DateTime effectiveFrom =
            DateTime.parse(effectiveFromController.text.trim());
        DateTime effectiveTo =
            DateTime.parse(effectiveToController.text.trim());

        if (effectiveTo.isBefore(effectiveFrom)) {
          MessageService.to.showDateRangeValidationError();
          return false;
        }
      } catch (e) {
        MessageService.to.showDateFormatError();
        return false;
      }
    }

    return true;
  }

  // Verify employee selection for multiple employees
  bool isEmployeeProperlySelected() {
    print("=== EMPLOYEE SELECTION CHECK ===");
    print("selectedEmployees.length: ${selectedEmployees.length}");

    if (selectedEmployees.isEmpty) {
      print("❌ No employees selected");
      return false;
    }

    selectedEmployees.forEach((employee) {
      print("✅ Employee selected: ${employee.name}");
      print("   ID: ${employee.id} (${employee.id.runtimeType})");
      print("   Type: ${employee.empType}");
      print("   Status: ${employee.status}");
    });

    print("=== END EMPLOYEE CHECK ===");
    return true;
  }

  /// Save wage record for multiple employees using the updated WageService
  void saveWage() async {
    if (isSaving.value) {
      print("Save already in progress, ignoring");
      return;
    }

    print("=== STARTING WAGE SAVE PROCESS ===");

    // First check if employees are properly selected
    if (!isEmployeeProperlySelected()) {
      MessageService.to.showError(
          'employees_required', 'Please select at least one employee');
      return;
    }

    // Then run full form validation
    if (!_validateForm()) {
      print("❌ Form validation failed, not saving");
      return;
    }

    try {
      isSaving.value = true;
      print("Setting isSaving to true");

      // Prepare employee IDs
      List<String> employeeIds = selectedEmployees.map((employee) {
        return employee.id.toString(); // Ensure ID is string
      }).toList();

      print("Employee IDs prepared: $employeeIds");

      // Parse amount
      double amount = double.parse(amountController.text.trim());

      // Prepare dates
      String effectiveFrom = effectiveFromController.text.trim();
      String? effectiveTo = effectiveToController.text.trim().isEmpty
          ? null
          : effectiveToController.text.trim();

      // Prepare remarks
      String? remarks = remarksController.text.trim().isEmpty
          ? null
          : remarksController.text.trim();

      print("Calling WageService.saveMultipleEmployeeWages...");
      print(
          "Amount: $amount, EffectiveFrom: $effectiveFrom, EffectiveTo: $effectiveTo");

      // Use the new saveMultipleEmployeeWages method from WageService
      Map<String, dynamic> result = await WageService.saveMultipleEmployeeWages(
        employeeIds: employeeIds,
        amount: amount,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        remarks: remarks,
      );

      print("API Response: $result");

      if (WageService.isSuccessResponse(result)) {
        // Handle successful response
        var summary = WageService.getWageSummary(result);
        var successfulWages = WageService.getSuccessfulWages(result);
        var failedEmployees = WageService.getFailedEmployees(result);

        String message = 'Wage records processed successfully';

        if (summary != null) {
          int successCount = summary['successful_count'] ?? 0;
          int failedCount = summary['failed_count'] ?? 0;
          message = 'Successfully saved wages for $successCount employee(s)';

          if (failedCount > 0) {
            message += ', $failedCount failed';
          }
        }

        print("✅ Wages saved successfully: $message");
        MessageService.to.showSuccess('success_wage_saved', message);

        // Show details of failed employees if any
        if (failedEmployees != null && failedEmployees.isNotEmpty) {
          String failedDetails = failedEmployees.map((failed) {
            String employeeName = failed['employee_name'] ?? 'Unknown';
            String reason = failed['reason'] ?? 'Unknown error';
            return '$employeeName: $reason';
          }).join('\n');

          print("⚠️ Failed employees: $failedDetails");
          MessageService.to.showError(
              'partial_failure', 'Some employees failed:\n$failedDetails');
        }

        _clearForm();
        await Future.delayed(Duration(milliseconds: 1000));
        Get.offAllNamed(Routes.WAGES, arguments: true);
      } else {
        // Handle error response
        String errorMessage = WageService.getErrorMessage(result);

        // Handle validation errors
        var validationErrors = WageService.getValidationErrors(result);
        if (validationErrors != null) {
          String errorDetails = validationErrors.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('\n');
          errorMessage = '$errorMessage\n$errorDetails';
        }

        print("❌ API Error: $errorMessage");
        MessageService.to.showError('error_wage_save', errorMessage);
      }
    } catch (e) {
      print('❌ Exception in saveWage: $e');
      print('Stack trace: ${StackTrace.current}');

      String errorMessage =
          'Network error: Please check your connection and try again';

      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Network connection error. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid data format. Please check your inputs.';
      }

      MessageService.to.showNetworkError(errorMessage);
    } finally {
      isSaving.value = false;
      print("Setting isSaving to false");
      print("=== END WAGE SAVE PROCESS ===");
    }
  }

  /// Clear form data
  void _clearForm() {
    selectedEmployees.clear();
    amountController.clear();
    amountText.value = '';

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    effectiveFromController.text = today;
    effectiveFromDate.value = today;

    effectiveToController.clear();
    effectiveToDate.value = '';

    remarksController.clear();
  }

  /// Refresh employees list
  Future<void> refreshEmployees() async {
    await _loadEmployees();
  }

  /// Navigate to view wages
  void navigateToViewWages() {
    Get.toNamed(Routes.WAGES);
  }

  /// Navigate to specific tab
  void navigateToTab(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.offAllNamed('/home');
        break;
      case 1:
        Get.offAllNamed('/dashboard');
        break;
      case 2:
        Get.offAllNamed('/settings');
        break;
    }
  }

  /// Get employee display name for dropdown
  String getEmployeeDisplayName(Employee employee) {
    return '${employee.name} (${employee.empType})';
  }

  /// Get formatted amount preview - now reactive
  String get formattedAmountPreview {
    if (amountText.value.trim().isEmpty) return '₹0.00';

    double? amount = double.tryParse(amountText.value.trim());
    if (amount == null) return '₹0.00';

    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get date range preview - now reactive
  String get dateRangePreview {
    if (effectiveFromDate.value.isEmpty) return 'No date selected';

    String fromDate = effectiveFromDate.value;
    String toDate =
        effectiveToDate.value.isEmpty ? 'Ongoing' : effectiveToDate.value;

    return '$fromDate - $toDate';
  }

  /// Validate amount in real-time
  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    double? amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 999999.99) {
      return 'Amount is too large';
    }

    return null;
  }

  /// Format amount input
  void formatAmountInput() {
    String text = amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Handle multiple decimal points
    int decimalCount = text.split('.').length - 1;
    if (decimalCount > 1) {
      List<String> parts = text.split('.');
      text = '${parts[0]}.${parts.sublist(1).join('')}';
    }

    // Limit decimal places to 2
    if (text.contains('.')) {
      List<String> parts = text.split('.');
      if (parts[1].length > 2) {
        text = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }

    if (text != amountController.text) {
      amountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      amountText.value = text;
    }
  }

  /// Validate form with visual feedback
  bool validateFormWithFeedback() {
    return _validateForm();
  }

  /// Quick validation methods for UI feedback
  bool get isEmployeeValid => selectedEmployees.isNotEmpty;

  bool get isAmountValid {
    if (amountController.text.trim().isEmpty) return false;
    double? amount = double.tryParse(amountController.text.trim());
    return amount != null && amount > 0;
  }

  bool get isEffectiveFromValid =>
      effectiveFromController.text.trim().isNotEmpty;

  bool get isDateRangeValid {
    if (effectiveToController.text.trim().isEmpty)
      return true; // Optional field

    try {
      DateTime effectiveFrom =
          DateTime.parse(effectiveFromController.text.trim());
      DateTime effectiveTo = DateTime.parse(effectiveToController.text.trim());
      return !effectiveTo.isBefore(effectiveFrom);
    } catch (e) {
      return false;
    }
  }

  /// Get form validation status
  bool get isFormValid =>
      isEmployeeValid &&
      isAmountValid &&
      isEffectiveFromValid &&
      isDateRangeValid;
}
