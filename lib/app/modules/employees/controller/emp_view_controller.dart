import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/services/employee/emp_service.dart';

class EmployeeViewController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isExporting = false.obs;
  var isDownloading = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var employees = <Employee>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;
  var fromDate = Rxn<DateTime>();
  var toDate = Rxn<DateTime>();

  // Employee statistics
  var totalEmployees = 0.obs;
  var activeEmployees = 0.obs;
  var inactiveEmployees = 0.obs;
  var recentHires = 0.obs;
  var empTypeStats = <Map<String, dynamic>>[].obs;
  var genderStats = <Map<String, dynamic>>[].obs;

  // Filter options
  var selectedEmpType = ''.obs;
  var selectedGender = ''.obs;
  var selectedStatus = Rxn<bool>();

  // Error handling
  var errorMessage = ''.obs;
  var hasError = false.obs;

  // Fixed: Return the actual employees list instead of null
  List<Employee> get filteredEmployees => employees;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
    loadStatistics();
  }

  /// Load employees from API with current filters and pagination
  Future<void> loadEmployees({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final result = await EmployeeService.getEmployeeList(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isEmpty ? null : searchKeyword.value,
        empType: selectedEmpType.value.isEmpty ? null : selectedEmpType.value,
        gender: selectedGender.value.isEmpty ? null : selectedGender.value,
        isActive: selectedStatus.value,
      );

      if (result['success']) {
        final data = result['data']['data'];

        // Convert API response to Employee models
        final employeeList = (data['employees'] as List)
            .map((json) => EmployeeService.employeeFromJson(json))
            .toList();

        employees.value = employeeList;

        // Update pagination info
        final pagination = data['pagination'];
        currentPage.value = pagination['current_page'];
        totalPages.value = pagination['total_pages'];
        totalCount.value = pagination['total_count'];
        hasNext.value = pagination['has_next'];
        hasPrevious.value = pagination['has_previous'];
      } else {
        hasError.value = true;
        errorMessage.value =
            result['data']['message'] ?? 'Failed to load employees';
        _showErrorSnackbar('Error', errorMessage.value);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error: ${e.toString()}';
      _showErrorSnackbar('Network Error', errorMessage.value);
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  /// Load employee statistics from API
  Future<void> loadStatistics() async {
    try {
      final result = await EmployeeService.getEmployeeStatistics();

      if (result['success']) {
        final data = result['data']['data'];
        final summary = data['summary'];

        totalEmployees.value = summary['total_employees'];
        activeEmployees.value = summary['active_employees'];
        inactiveEmployees.value = summary['inactive_employees'];
        recentHires.value = summary['recent_hires'];

        empTypeStats.value =
            List<Map<String, dynamic>>.from(data['emp_type_stats']);
        genderStats.value =
            List<Map<String, dynamic>>.from(data['gender_stats']);
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  /// Search employees
  void runFilter(String keyword) {
    searchKeyword.value = keyword;
    currentPage.value = 1; // Reset to first page
    loadEmployees();
  }

  /// Apply employee type filter
  void setEmpTypeFilter(String empType) {
    selectedEmpType.value = empType;
    currentPage.value = 1;
    loadEmployees();
  }

  /// Apply gender filter
  void setGenderFilter(String gender) {
    selectedGender.value = gender;
    currentPage.value = 1;
    loadEmployees();
  }

  /// Apply status filter
  void setStatusFilter(bool? isActive) {
    selectedStatus.value = isActive;
    currentPage.value = 1;
    loadEmployees();
  }

  /// Clear all filters
  void clearFilters() {
    searchKeyword.value = '';
    selectedEmpType.value = '';
    selectedGender.value = '';
    selectedStatus.value = null;
    fromDate.value = null;
    toDate.value = null;
    currentPage.value = 1;
    loadEmployees();
  }

  /// Date filter methods (for future implementation if API supports date filtering)
  void selectFromDate(DateTime? date) {
    fromDate.value = date;
    // Implement API call with date filter when backend supports it
  }

  void selectToDate(DateTime? date) {
    toDate.value = date;
    // Implement API call with date filter when backend supports it
  }

  /// Pagination methods
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadEmployees();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadEmployees();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadEmployees();
    }
  }

  /// Refresh employees data
  Future<void> refreshEmployees() async {
    await loadEmployees();
    await loadStatistics();
  }

  /// Get employee details by ID
  Future<Employee?> getEmployeeDetail(String employeeId) async {
    try {
      final result = await EmployeeService.getEmployeeDetail(employeeId);

      if (result['success']) {
        return EmployeeService.employeeFromJson(result['data']['data']);
      } else {
        _showErrorSnackbar('Error',
            result['data']['message'] ?? 'Failed to load employee details');
        return null;
      }
    } catch (e) {
      _showErrorSnackbar('Network Error', 'Failed to load employee details');
      return null;
    }
  }

  // Fixed: Return the employees list instead of calling undefined filteredEmployees
  List<Employee> getPaginatedEmployees() {
    return employees;
  }

  /// Delete employee
  Future<void> deleteEmployee(String employeeId,
      {bool hardDelete = false}) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text(
              hardDelete ? 'Permanently Delete Employee' : 'Delete Employee'),
          content: Text(hardDelete
              ? 'This action cannot be undone. The employee record will be permanently removed.'
              : 'This will deactivate the employee. You can restore them later if needed.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(hardDelete ? 'Permanently Delete' : 'Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      final result = await EmployeeService.deleteEmployee(
        employeeId: employeeId,
        hardDelete: hardDelete,
      );

      if (result['success']) {
        _showSuccessSnackbar('Success', result['data']['message']);
        await refreshEmployees();
      } else {
        _showErrorSnackbar(
            'Error', result['data']['message'] ?? 'Failed to delete employee');
      }
    } catch (e) {
      _showErrorSnackbar('Network Error', 'Failed to delete employee');
    } finally {
      isLoading.value = false;
    }
  }

  /// Restore soft-deleted employee
  Future<void> restoreEmployee(String employeeId) async {
    try {
      isLoading.value = true;

      final result = await EmployeeService.restoreEmployee(employeeId);

      if (result['success']) {
        _showSuccessSnackbar('Success', result['data']['message']);
        await refreshEmployees();
      } else {
        _showErrorSnackbar(
            'Error', result['data']['message'] ?? 'Failed to restore employee');
      }
    } catch (e) {
      _showErrorSnackbar('Network Error', 'Failed to restore employee');
    } finally {
      isLoading.value = false;
    }
  }

  /// Download employee list as PDF
  void downloadEmployeeList() async {
    try {
      isDownloading.value = true;

      // TODO: Implement PDF generation with current employee data
      await Future.delayed(Duration(seconds: 2)); // Simulate download

      _showSuccessSnackbar('Success', 'Employee list downloaded as PDF');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to download employee list');
    } finally {
      isDownloading.value = false;
    }
  }

  /// Export employee list to Excel
  void exportToExcel() async {
    try {
      isExporting.value = true;

      // TODO: Implement Excel export with current employee data
      await Future.delayed(Duration(seconds: 2)); // Simulate export

      _showSuccessSnackbar('Success', 'Employee list exported to Excel');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to export employee list');
    } finally {
      isExporting.value = false;
    }
  }

  /// Get summary text for display
  String getSummaryText() {
    return 'Total: ${totalCount.value} employees (${activeEmployees.value} active, ${inactiveEmployees.value} inactive)';
  }

  /// Get page info text
  String getPageInfoText() {
    if (totalCount.value == 0) return 'No employees found';

    final startItem = ((currentPage.value - 1) * itemsPerPage) + 1;
    final endItem =
        (currentPage.value * itemsPerPage).clamp(0, totalCount.value);

    return 'Showing $startItem-$endItem of ${totalCount.value} employees';
  }

  /// Helper methods for snackbars
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Retry loading data after error
  void retryLoading() {
    loadEmployees();
    loadStatistics();
  }

  @override
  void onClose() {
    // Clean up resources if needed
    super.onClose();
  }
}
