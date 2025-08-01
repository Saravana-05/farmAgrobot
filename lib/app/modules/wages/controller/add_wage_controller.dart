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
  var selectedEmployee = Rxn<Employee>();

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

  /// Load employees for dropdown selection
  Future<void> _loadEmployees() async {
    try {
      isLoadingEmployees.value = true;

      // Add proper error handling and debugging
      print("Starting to load employees...");

      Map<String, dynamic> result = await EmployeeService.getEmployeeList();
      print("API Result: $result");

      // Add detailed debugging
      debugApiResponse(result);

      // Check if result is null or empty
      if (result.isEmpty) {
        print("Error: Empty result from API");
        MessageService.to.showError(
            'error_loading_employees', 'No data received from server');
        return;
      }

      // More robust success checking
      bool isSuccess = result['success'] == true || result['success'] == 'true';

      if (isSuccess) {
        // Handle the specific API structure: result['data']['data']['employees']
        List<dynamic> employeeData = [];

        print("Attempting to extract employees from nested structure...");

        // Your API structure: result -> data -> data -> employees
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

        // Convert and filter employees with better error handling
        List<Employee> validEmployees = [];

        for (var json in employeeData) {
          try {
            Employee emp = Employee.fromJson(json);
            // Only add active employees
            if (emp.status == true) {
              validEmployees.add(emp);
            }
          } catch (e) {
            print("Error parsing employee: $json, Error: $e");
            // Continue with other employees instead of failing completely
          }
        }

        employees.value = validEmployees;
        print("Successfully loaded ${validEmployees.length} active employees");

        if (validEmployees.isEmpty) {
          MessageService.to
              .showError('no_active_employees', 'No active employees found');
        }
      } else {
        // Handle API error response
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

      // Provide more specific error messages
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

// Also add this method to manually refresh employees
  Future<void> refreshEmployeesManually() async {
    employees.clear(); // Clear existing data
    selectedEmployee.value = null; // Reset selection
    await _loadEmployees();
  }

// Add this method to debug the exact API response structure
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

// Add this method to check employee service availability
  Future<bool> checkEmployeeServiceHealth() async {
    try {
      // You might want to add a health check endpoint
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

      // Clear effective to date if it's before the new effective from date
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

    // Set minimum date based on effective from date
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

  /// Validate form data
  bool _validateForm() {
    // Employee validation
    if (selectedEmployee.value == null) {
      MessageService.to.showEmployeeValidationError();
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

  /// Convert form data to request format
  Map<String, dynamic> _wageToRequestData() {
    print("=== BUILDING WAGE REQUEST DATA ===");

    Map<String, dynamic> data = {};

    // Debug the selected employee
    print("selectedEmployee.value: ${selectedEmployee.value}");
    print("selectedEmployee.value?.id: ${selectedEmployee.value?.id}");
    print(
        "selectedEmployee.value?.id type: ${selectedEmployee.value?.id.runtimeType}");

    // Handle employee ID properly - use 'employee' instead of 'employee_id'
    var employeeId = selectedEmployee.value!.id;
    if (employeeId is String) {
      // If it's a string, try to convert to int
      var parsedId = int.tryParse(employeeId);
      data['employee'] =
          parsedId ?? employeeId; // Keep as string if parsing fails
      print(
          "Converted string ID '$employeeId' to: ${data['employee']} (${data['employee'].runtimeType})");
    } else if (employeeId is int) {
      data['employee'] = employeeId;
      print(
          "Using integer ID: ${data['employee']} (${data['employee'].runtimeType})");
    } else {
      data['employee'] = employeeId;
      print(
          "Using ID as-is: ${data['employee']} (${data['employee'].runtimeType})");
    }

    // Handle amount
    var amountText = amountController.text.trim();
    print("Amount text: '$amountText'");
    data['amount'] = double.parse(amountText);
    print("Parsed amount: ${data['amount']} (${data['amount'].runtimeType})");

    // Handle effective from date
    data['effective_from'] = effectiveFromController.text.trim();
    print("Effective from: '${data['effective_from']}'");

    // Handle optional effective to date
    if (effectiveToController.text.trim().isNotEmpty) {
      data['effective_to'] = effectiveToController.text.trim();
      print("Effective to: '${data['effective_to']}'");
    } else {
      print("No effective to date");
    }

    // Handle optional remarks
    if (remarksController.text.trim().isNotEmpty) {
      data['remarks'] = remarksController.text.trim();
      print("Remarks: '${data['remarks']}'");
    } else {
      print("No remarks");
    }

    // Remove null or empty values
    int initialCount = data.length;
    data.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty));
    int finalCount = data.length;

    if (initialCount != finalCount) {
      print("Removed ${initialCount - finalCount} null/empty values");
    }

    print("Final request data: $data");
    print("=== END WAGE REQUEST DATA ===");

    return data;
  }

// Also add this helper method to verify employee selection
  bool isEmployeeProperlySelected() {
    print("=== EMPLOYEE SELECTION CHECK ===");
    print("selectedEmployee.value: ${selectedEmployee.value}");

    if (selectedEmployee.value == null) {
      print("❌ No employee selected");
      return false;
    }

    print("✅ Employee selected: ${selectedEmployee.value!.name}");
    print(
        "   ID: ${selectedEmployee.value!.id} (${selectedEmployee.value!.id.runtimeType})");
    print("   Type: ${selectedEmployee.value!.empType}");
    print("   Status: ${selectedEmployee.value!.status}");
    print("=== END EMPLOYEE CHECK ===");

    return true;
  }

  /// Save wage record
  /// Save wage record
  void saveWage() async {
    if (isSaving.value) {
      print("Save already in progress, ignoring");
      return;
    }

    print("=== STARTING WAGE SAVE PROCESS ===");

    // First check if employee is properly selected
    if (!isEmployeeProperlySelected()) {
      MessageService.to
          .showError('employee_required', 'Please select an employee');
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

      Map<String, dynamic> wageData = _wageToRequestData();
      print("Wage data prepared, calling API...");

      Map<String, dynamic> result = await WageService.saveWage(
        wageData: wageData,
      );

      print("API Response: $result");

      if (result['success']) {
        String message =
            result['data']?['message'] ?? 'Wage record saved successfully';

        print("✅ Wage saved successfully: $message");
        MessageService.to.showSuccess('success_wage_saved', message);

        _clearForm();
        await Future.delayed(Duration(milliseconds: 1000));
        Get.offAllNamed(Routes.WAGES, arguments: true);
      } else {
        String errorMessage =
            result['data']?['message'] ?? 'Failed to save wage record';

        // Handle validation errors from API
        if (result['data'] != null && result['data']['errors'] != null) {
          Map<String, dynamic> errors = result['data']['errors'];
          String errorDetails = errors.entries
              .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
              .join('\n');
          errorMessage = '$errorMessage\n$errorDetails';
        }

        print("❌ API Error: $errorMessage");
        MessageService.to.showError('error_wage_save', errorMessage);
      }
    } catch (e) {
      print('❌ Exception in saveWage: $e');
      print('Stack trace: ${StackTrace.current}');
      MessageService.to.showNetworkError(
          'Network error: Please check your connection and try again');
    } finally {
      isSaving.value = false;
      print("Setting isSaving to false");
      print("=== END WAGE SAVE PROCESS ===");
    }
  }

  /// Clear form data
  void _clearForm() {
    selectedEmployee.value = null;
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

  /// Check if employee is already selected
  bool isEmployeeSelected(Employee employee) {
    return selectedEmployee.value?.id == employee.id;
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
      amountText.value = text; // Update reactive variable
    }
  }

  /// Validate form with visual feedback - can be called from UI
  bool validateFormWithFeedback() {
    return _validateForm();
  }

  /// Quick validation methods for UI feedback
  bool get isEmployeeValid => selectedEmployee.value != null;

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
