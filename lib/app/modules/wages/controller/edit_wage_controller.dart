import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/models/wages/wages_model.dart';
import '../../../data/services/employee/emp_service.dart';
import '../../../data/services/messages/message_service.dart';
import '../../../data/services/wages/wages_service.dart';
import '../../../routes/app_pages.dart';

class EditWageController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var isLoading = false.obs;
  var isLoadingEmployees = false.obs;
  var selectedIndex = 0.obs;
  var selectedEmployee = Rxn<Employee>();
  var currentWage = Rxn<Wage>();

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

  // Wage ID parameter
  String? wageId;

  @override
  void onInit() {
    super.onInit();

    // Get wage ID from arguments
    final arguments = Get.arguments;
    if (arguments is Map && arguments.containsKey('wageId')) {
      wageId = arguments['wageId']?.toString();
    } else if (arguments is String) {
      wageId = arguments;
    }

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

    // Load initial data
    _initializeData();
  }

  @override
  void onClose() {
    amountController.dispose();
    effectiveFromController.dispose();
    effectiveToController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  /// Initialize controller data - FIXED VERSION
  Future<void> _initializeData() async {
    if (wageId == null || wageId!.isEmpty) {
      MessageService.to
          .showError('invalid_wage_id', 'Invalid wage ID provided');
      Get.back();
      return;
    }

    try {
      isLoading.value = true;
      print("🔄 Starting initialization for wage ID: $wageId");

      // Load employees FIRST, then wage details
      print("🔄 Loading employees first...");
      await _loadEmployees();

      print("🔄 Employees loaded: ${employees.length}");

      print("🔄 Loading wage details after employees are loaded...");
      await _loadWageDetail();

      // Debug the final state
      debugDataLoading();
    } catch (e) {
      print('❌ Error in _initializeData: $e');
      MessageService.to.showError(
          'initialization_error', 'Failed to initialize data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load wage detail and populate form - FIXED VERSION
  Future<void> _loadWageDetail() async {
    try {
      print("🔍 Loading wage detail for ID: $wageId");

      Map<String, dynamic> result = await WageService.getWageDetail(wageId!);
      print("📥 Wage detail API result: $result");

      if (result['success'] == true) {
        // Handle the API response structure more carefully
        Map<String, dynamic> wageData;

        // Check different possible response structures
        if (result['data'] != null) {
          var data = result['data'];

          // Check if data has nested 'data' property
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            wageData = data['data'] as Map<String, dynamic>;
          } else {
            wageData = data as Map<String, dynamic>;
          }
        } else {
          throw Exception('No data found in API response');
        }

        print("📋 Raw wage data: $wageData");

        // Create Wage object from response
        Wage wage = Wage.fromJson(wageData);
        currentWage.value = wage;

        print(
            "✅ Created wage object: Employee ID = ${wage.employeeId}, Amount = ${wage.amount}");

        // Populate form fields
        await _populateFormFromWage(wage);

        print("✅ Wage detail loaded and form populated successfully");
      } else {
        String errorMessage = 'Failed to load wage details';

        if (result['data'] != null && result['data'] is Map) {
          errorMessage = result['data']['message'] ?? errorMessage;
        }

        print("❌ Failed to load wage detail: $errorMessage");
        MessageService.to.showError('error_loading_wage', errorMessage);
        Get.back();
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _loadWageDetail: $e');
      print('Stack trace: $stackTrace');
      MessageService.to.showError(
          'error_loading_wage', 'Failed to load wage details: ${e.toString()}');
      Get.back();
    }
  }

  /// Populate form fields from wage data - FIXED VERSION
  Future<void> _populateFormFromWage(Wage wage) async {
    print("=== POPULATING FORM FROM WAGE ===");
    print(
        "Wage data: Employee ID = ${wage.employeeId}, Amount = ${wage.amount}");

    try {
      // Set amount with explicit update
      print("Setting amount: ${wage.amount}");
      amountController.text = wage.amount.toString();
      amountText.value = wage.amount.toString();

      // Set effective from date
      String effectiveFromStr =
          DateFormat('yyyy-MM-dd').format(wage.effectiveFrom);
      print("Setting effective from: $effectiveFromStr");
      effectiveFromController.text = effectiveFromStr;
      effectiveFromDate.value = effectiveFromStr;

      // Set effective to date (optional)
      if (wage.effectiveTo != null) {
        String effectiveToStr =
            DateFormat('yyyy-MM-dd').format(wage.effectiveTo!);
        print("Setting effective to: $effectiveToStr");
        effectiveToController.text = effectiveToStr;
        effectiveToDate.value = effectiveToStr;
      } else {
        print("Clearing effective to date");
        effectiveToController.clear();
        effectiveToDate.value = '';
      }

      // Set remarks
      print("Setting remarks: ${wage.remarks ?? 'None'}");
      remarksController.text = wage.remarks ?? '';

      // Force UI update
      update();

      // Wait for employees to be loaded and then select employee
      await _waitForEmployeesAndSelect(wage.employeeId);

      print("=== FORM POPULATED SUCCESSFULLY ===");
    } catch (e) {
      print("❌ Error populating form: $e");
      throw e;
    }
  }

  /// Wait for employees to load and then select the correct employee
  Future<void> _waitForEmployeesAndSelect(String employeeId) async {
    int attempts = 0;
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 500);

    while (attempts < maxAttempts) {
      if (employees.isNotEmpty) {
        print(
            "👥 Employees loaded (${employees.length}), selecting employee...");
        selectEmployeeById(employeeId);
        return;
      }

      attempts++;
      print(
          "⏳ Waiting for employees to load... (attempt $attempts/$maxAttempts)");
      await Future.delayed(delay);
    }

    print("❌ Timeout waiting for employees to load");
    _handleMissingEmployee(employeeId);
  }

  /// Select employee by ID - IMPROVED VERSION
  void selectEmployeeById(String employeeId) {
    print(
        "🔍 Looking for employee with ID: $employeeId in ${employees.length} employees");

    if (employees.isEmpty) {
      print("❌ No employees loaded yet");
      return;
    }

    try {
      Employee? employee;

      // Try different ID matching approaches
      // 1. Exact string match
      employee =
          employees.firstWhereOrNull((emp) => emp.id.toString() == employeeId);

      // 2. If not found, try parsing as int and comparing
      if (employee == null) {
        int? targetId = int.tryParse(employeeId);
        if (targetId != null) {
          employee = employees.firstWhereOrNull((emp) {
            if (emp.id is int) return emp.id == targetId;
            if (emp.id is String) return int.tryParse(emp.id) == targetId;
            return false;
          });
        }
      }

      if (employee != null) {
        selectedEmployee.value = employee;
        print(
            "✅ Found and selected employee: ${employee.name} (ID: ${employee.id})");
        update(); // Force UI update
      } else {
        print("❌ Employee not found with ID: $employeeId");
        print(
            "Available employee IDs: ${employees.map((e) => '${e.id}(${e.id.runtimeType})').join(', ')}");
        _handleMissingEmployee(employeeId);
      }
    } catch (e) {
      print("❌ Error selecting employee: $e");
      _handleMissingEmployee(employeeId);
    }
  }

  /// Enhanced debugging method to check data loading
  void debugDataLoading() {
    print("=== DEBUG DATA LOADING ===");
    print("Wage ID: $wageId");
    print("Current wage loaded: ${currentWage.value != null}");
    print("Employees loaded: ${employees.length}");
    print("Selected employee: ${selectedEmployee.value?.name}");
    print("Amount controller text: '${amountController.text}'");
    print("Effective from controller text: '${effectiveFromController.text}'");
    print("Effective to controller text: '${effectiveToController.text}'");
    print("Remarks controller text: '${remarksController.text}'");
    print("Is loading: ${isLoading.value}");
    print("Is loading employees: ${isLoadingEmployees.value}");
    print("========================");
  }

  /// Handle case where employee is not in the current active list
  void _handleMissingEmployee(String employeeId) {
    // This could happen if the employee was deactivated after the wage was created
    // We might want to show a warning or load the specific employee
    print("⚠️ Employee with ID $employeeId not found in active employees list");
    MessageService.to.showWarning('employee_not_found',
        'The employee associated with this wage record may no longer be active');
  }

  /// Load employees for dropdown selection
  Future<void> _loadEmployees() async {
    try {
      isLoadingEmployees.value = true;
      print("Starting to load employees for edit...");

      Map<String, dynamic> result = await EmployeeService.getEmployeeList();
      print("API Result: $result");

      if (result.isEmpty) {
        print("Error: Empty result from API");
        MessageService.to.showError(
            'error_loading_employees', 'No data received from server');
        return;
      }

      bool isSuccess = result['success'] == true || result['success'] == 'true';

      if (isSuccess) {
        List<dynamic> employeeData = [];

        // Handle the specific API structure: result['data']['data']['employees']
        if (result['data'] != null && result['data'] is Map) {
          var outerData = result['data'] as Map<String, dynamic>;

          if (outerData['data'] != null && outerData['data'] is Map) {
            var innerData = outerData['data'] as Map<String, dynamic>;

            if (innerData['employees'] != null &&
                innerData['employees'] is List) {
              employeeData = List<dynamic>.from(innerData['employees']);
              print("Found employees list with ${employeeData.length} items");
            }
          }
        }

        if (employeeData.isEmpty) {
          print("Warning: No employees found in response");
          MessageService.to
              .showError('no_employees_found', 'No employees found');
          employees.clear();
          return;
        }

        // Convert and include ALL employees (both active and inactive)
        // This is important for edit mode in case the wage is associated with an inactive employee
        List<Employee> allEmployees = [];

        for (var json in employeeData) {
          try {
            Employee emp = Employee.fromJson(json);
            allEmployees.add(emp);
          } catch (e) {
            print("Error parsing employee: $json, Error: $e");
          }
        }

        employees.value = allEmployees;
        print(
            "Successfully loaded ${allEmployees.length} employees (including inactive)");
      } else {
        String errorMessage = result['message'] ?? 'Failed to load employees';
        print("API Error: $errorMessage");
        MessageService.to.showError('error_loading_employees', errorMessage);
      }
    } catch (e) {
      print('Exception in _loadEmployees: $e');
      String errorMessage = 'Error loading employees';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Please try again';
      } else {
        errorMessage = 'Error loading employees: ${e.toString()}';
      }

      MessageService.to.showError('error_loading_employees', errorMessage);
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  /// Select effective from date
  Future<void> selectEffectiveFromDate() async {
    DateTime initialDate = DateTime.now();

    // Use current effective from date if available
    if (effectiveFromController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(effectiveFromController.text);
      } catch (e) {
        // Keep default if parsing fails
      }
    }

    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
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

    // Use current effective to date if available
    if (effectiveToController.text.isNotEmpty) {
      try {
        DateTime currentEffectiveTo =
            DateTime.parse(effectiveToController.text);
        if (currentEffectiveTo.isAfter(firstDate)) {
          initialDate = currentEffectiveTo;
        }
      } catch (e) {
        // Keep calculated initial date if parsing fails
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

  /// Convert form data to update request format
  Map<String, dynamic> _wageToUpdateRequestData() {
    print("=== BUILDING WAGE UPDATE REQUEST DATA ===");

    Map<String, dynamic> data = {};

    // Handle employee ID - backend expects 'employee' field but will convert to employee_id
    var employeeId = selectedEmployee.value!.id;
    if (employeeId is String) {
      var parsedId = int.tryParse(employeeId);
      data['employee'] = parsedId ?? employeeId;
    } else {
      data['employee'] = employeeId;
    }
    print("Employee ID: ${data['employee']} (${data['employee'].runtimeType})");

    // Handle amount
    var amountText = amountController.text.trim();
    data['amount'] = double.parse(amountText);
    print("Amount: ${data['amount']} (${data['amount'].runtimeType})");

    // Handle effective from date
    data['effective_from'] = effectiveFromController.text.trim();
    print("Effective from: '${data['effective_from']}'");

    // Handle optional effective to date
    if (effectiveToController.text.trim().isNotEmpty) {
      data['effective_to'] = effectiveToController.text.trim();
      print("Effective to: '${data['effective_to']}'");
    } else {
      // Explicitly set to null to clear the field
      data['effective_to'] = null;
      print("Effective to: null (clearing end date)");
    }

    // Handle optional remarks
    if (remarksController.text.trim().isNotEmpty) {
      data['remarks'] = remarksController.text.trim();
      print("Remarks: '${data['remarks']}'");
    } else {
      // Explicitly set to null to clear the field
      data['remarks'] = null;
      print("Remarks: null (clearing remarks)");
    }

    print("Final update request data: $data");
    print("=== END WAGE UPDATE REQUEST DATA ===");

    return data;
  }

  /// Update wage record
  void updateWage() async {
    if (isSaving.value) {
      print("Update already in progress, ignoring");
      return;
    }

    if (wageId == null) {
      MessageService.to.showError('invalid_wage_id', 'Invalid wage ID');
      return;
    }

    print("=== STARTING WAGE UPDATE PROCESS ===");

    if (!_validateForm()) {
      print("❌ Form validation failed, not updating");
      return;
    }

    try {
      isSaving.value = true;
      print("Setting isSaving to true");

      Map<String, dynamic> wageData = _wageToUpdateRequestData();
      print("Update data prepared, calling API...");

      Map<String, dynamic> result = await WageService.editWage(
        wageId: wageId!,
        wageData: wageData,
      );

      print("📥 API Response: $result");

      if (result['success'] == true) {
        String message = 'Wage record updated successfully';

        if (result['data'] != null && result['data'] is Map) {
          message = result['data']['message'] ?? message;
        }

        print("✅ Wage updated successfully: $message");
        MessageService.to.showSuccess('success_wage_updated', message);

        // Give user time to see the success message
        await Future.delayed(Duration(milliseconds: 1500));

        // Navigate back to wages list
        Get.offAllNamed(Routes.WAGES, arguments: {'refresh': true});
      } else {
        String errorMessage = 'Failed to update wage record';

        if (result['data'] != null && result['data'] is Map) {
          errorMessage = result['data']['message'] ?? errorMessage;

          // Handle validation errors from API
          if (result['data']['errors'] != null) {
            Map<String, dynamic> errors = result['data']['errors'];
            String errorDetails = errors.entries
                .map((entry) =>
                    '${entry.key}: ${entry.value is List ? (entry.value as List).join(', ') : entry.value}')
                .join('\n');
            errorMessage = '$errorMessage\n$errorDetails';
          }
        }

        print("❌ API Error: $errorMessage");
        MessageService.to.showError('error_wage_update', errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ Exception in updateWage: $e');
      print('Stack trace: $stackTrace');

      String errorMessage =
          'Network error: Please check your connection and try again';
      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Network connection error. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      }

      MessageService.to.showError('error_wage_update', errorMessage);
    } finally {
      isSaving.value = false;
      print("Setting isSaving to false");
      print("=== END WAGE UPDATE PROCESS ===");
    }
  }

  /// Check if form has changes compared to original wage
  bool get hasChanges {
    if (currentWage.value == null) return false;

    Wage original = currentWage.value!;

    // Check employee change
    if (selectedEmployee.value?.id.toString() != original.employeeId)
      return true;

    // Check amount change
    double? currentAmount = double.tryParse(amountController.text.trim());
    if (currentAmount != null && currentAmount != original.amount) return true;

    // Check effective from date change
    if (effectiveFromController.text.trim().isNotEmpty) {
      try {
        DateTime currentEffectiveFrom =
            DateTime.parse(effectiveFromController.text.trim());
        DateTime originalDate = DateTime(original.effectiveFrom.year,
            original.effectiveFrom.month, original.effectiveFrom.day);
        DateTime currentDate = DateTime(currentEffectiveFrom.year,
            currentEffectiveFrom.month, currentEffectiveFrom.day);
        if (!currentDate.isAtSameMomentAs(originalDate)) return true;
      } catch (e) {
        // Consider invalid date as a change
        return true;
      }
    }

    // Check effective to date change
    String currentEffectiveTo = effectiveToController.text.trim();
    if (original.effectiveTo == null && currentEffectiveTo.isNotEmpty)
      return true;
    if (original.effectiveTo != null && currentEffectiveTo.isEmpty) return true;
    if (original.effectiveTo != null && currentEffectiveTo.isNotEmpty) {
      try {
        DateTime currentToDate = DateTime.parse(currentEffectiveTo);
        DateTime originalToDate = DateTime(original.effectiveTo!.year,
            original.effectiveTo!.month, original.effectiveTo!.day);
        DateTime currentToDateOnly = DateTime(
            currentToDate.year, currentToDate.month, currentToDate.day);
        if (!currentToDateOnly.isAtSameMomentAs(originalToDate)) return true;
      } catch (e) {
        return true;
      }
    }

    // Check remarks change
    String currentRemarks = remarksController.text.trim();
    String originalRemarks = original.remarks ?? '';
    if (currentRemarks != originalRemarks) return true;

    return false;
  }

  /// Reset form to original values
  void resetForm() {
    if (currentWage.value != null) {
      _populateFormFromWage(currentWage.value!);
    }
  }

  /// Navigate back with confirmation if there are unsaved changes
  void navigateBack() {
    if (hasChanges) {
      Get.defaultDialog(
        title: 'Unsaved Changes',
        middleText:
            'You have unsaved changes. Are you sure you want to go back?',
        textConfirm: 'Yes, Go Back',
        textCancel: 'Stay',
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back(); // Close dialog
          Get.back(); // Go back to previous page
        },
        onCancel: () => Get.back(), // Just close dialog
      );
    } else {
      Get.back();
    }
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
    String displayName = '${employee.name} (${employee.empType})';
    if (employee.status != true) {
      displayName += ' - Inactive';
    }
    return displayName;
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
      amountText.value = text;
    }
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
    if (effectiveToController.text.trim().isEmpty) return true;

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

  /// Get current wage details for display
  String get originalWageInfo {
    if (currentWage.value == null) return '';

    Wage wage = currentWage.value!;
    return 'Original: ${wage.employeeName} - ${wage.formattedAmountClean} (${wage.formattedDateRange})';
  }
}
