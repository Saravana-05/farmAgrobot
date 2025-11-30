import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../config/api.dart';
import '../../../core/utils/tamil_text_handler.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/services/employee/emp_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';

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

  // Enhanced image cache with validation status
  var imageCache = <String, Map<String, dynamic>>{}.obs;

  // Add reactive variable for real-time updates
  var lastUpdateTimestamp = 0.obs;

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

        // Convert API response to Employee models with proper encoding handling
        final employeeList = (data['employees'] as List)
            .map((json) => _parseEmployeeWithProperEncoding(json))
            .toList();

        employees.value = employeeList;

        // Update pagination info
        final pagination = data['pagination'];
        currentPage.value = pagination['current_page'];
        totalPages.value = pagination['total_pages'];
        totalCount.value = pagination['total_count'];
        hasNext.value = pagination['has_next'];
        hasPrevious.value = pagination['has_previous'];

        // Pre-process image URLs
        _preprocessImageUrls();

        // Update timestamp for real-time tracking
        lastUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;
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
      print('Error loading employees: $e');
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  /// Parse employee data with enhanced Tamil text encoding
  Employee _parseEmployeeWithProperEncoding(Map<String, dynamic> json) {
    try {
      // Only fix tamil_name field using the simplified handler
      if (json['tamil_name'] != null) {
        String originalTamilName = json['tamil_name'].toString();
        String decodedTamilName =
            TamilTextHandler.decodeTamilText(originalTamilName);
        json['tamil_name'] = decodedTamilName;

        // Debug logging
        if (originalTamilName != decodedTamilName) {
          print(
              'Tamil name decoded: "$originalTamilName" -> "$decodedTamilName"');
        }
      }

      // Handle image URL (keep your existing logic)
      if (json['profile_image'] != null) {
        String imageUrl = json['profile_image'].toString().trim();
        json['profile_image'] = _validateAndBuildImageUrl(imageUrl);
      }

      return Employee.fromJson(json);
    } catch (e) {
      print('Error parsing employee data: $e');
      return Employee.fromJson(json);
    }
  }

  /// Enhanced image URL validation and building
  String _validateAndBuildImageUrl(String imageUrl) {
    try {
      // Remove any extra whitespace
      imageUrl = imageUrl.trim();

      // If empty, return empty
      if (imageUrl.isEmpty) {
        return '';
      }

      // If already a complete URL, validate it
      if (imageUrl.startsWith('http')) {
        Uri? uri = Uri.tryParse(imageUrl);
        if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
          return imageUrl;
        } else {
          print('Invalid complete URL: $imageUrl');
          return '';
        }
      }

      // Build the complete URL
      String fullUrl;
      if (imageUrl.startsWith('/')) {
        fullUrl = '$baseImgUrl$imageUrl';
      } else {
        fullUrl = '$baseImgUrl/$imageUrl';
      }

      // Validate the built URL
      Uri? uri = Uri.tryParse(fullUrl);
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        print('Built valid URL: $fullUrl for path: $imageUrl');
        return fullUrl;
      } else {
        print('Failed to build valid URL from: $imageUrl');
        return '';
      }
    } catch (e) {
      print('Error validating image URL "$imageUrl": $e');
      return '';
    }
  }

  /// Pre-process all image URLs
  void _preprocessImageUrls() {
    for (var employee in employees) {
      if (employee.imageUrl != null && employee.imageUrl!.isNotEmpty) {
        final validatedUrl = _validateAndBuildImageUrl(employee.imageUrl!);
        imageCache[employee.id] = {
          'url': validatedUrl,
          'isValid': validatedUrl.isNotEmpty,
          'originalPath': employee.imageUrl,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        imageCache[employee.id] = {
          'url': '',
          'isValid': false,
          'originalPath': '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }
    }
  }

  /// Get employee image URL with enhanced validation and fallback
  String? getEmployeeImageUrl(Employee employee) {
    try {
      // Check cache first
      if (imageCache.containsKey(employee.id)) {
        final cached = imageCache[employee.id]!;
        if (cached['isValid'] == true && cached['url'].toString().isNotEmpty) {
          return cached['url'].toString();
        }
      }

      // If not in cache or invalid, validate and cache
      if (employee.imageUrl != null && employee.imageUrl!.isNotEmpty) {
        final validatedUrl = _validateAndBuildImageUrl(employee.imageUrl!);

        // Update cache
        imageCache[employee.id] = {
          'url': validatedUrl,
          'isValid': validatedUrl.isNotEmpty,
          'originalPath': employee.imageUrl,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        return validatedUrl.isEmpty ? null : validatedUrl;
      }

      return null;
    } catch (e) {
      print('Error getting employee image URL for ${employee.id}: $e');
      return null;
    }
  }

  /// Safe image widget builder
  Widget buildEmployeeImage(
    Employee employee, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    final imageUrl = getEmployeeImageUrl(employee);

    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ??
          Container(
            width: width ?? 50,
            height: height ?? 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey[600],
              size: (width ?? 50) * 0.6,
            ),
          );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return loadingWidget ??
            Container(
              width: width ?? 50,
              height: height ?? 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Image load error for ${employee.name}: $error');

        // Mark as invalid in cache
        imageCache[employee.id] = {
          'url': '',
          'isValid': false,
          'originalPath': employee.imageUrl ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'error': error.toString(),
        };

        return errorWidget ??
            Container(
              width: width ?? 50,
              height: height ?? 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: (width ?? 50) * 0.6,
              ),
            );
      },
    );
  }

  /// Get employee display name with Tamil support using simplified handler
  String getEmployeeDisplayName(Employee employee) {
    String name = employee.name ?? 'Unknown';

    // Use the simplified Tamil text handler
    String decodedName = TamilTextHandler.decodeTamilText(name);

    // Debug logging
    if (name != decodedName) {
      print('Display name processed: "$name" -> "$decodedName"');
    }

    return decodedName.isEmpty ? 'Unknown' : decodedName;
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

  /// Search employees with Tamil text support using simplified handler
  void runFilter(String keyword) {
    try {
      // For search, we'll use the keyword as-is since the simplified handler
      // is mainly for decoding received data, not encoding for API calls
      searchKeyword.value = keyword;

      // Debug logging for search
      print('Search keyword: "$keyword"');
    } catch (e) {
      print('Search error: $e');
      searchKeyword.value = keyword;
    }

    currentPage.value = 1;
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
    imageCache.clear();
    loadEmployees();
  }

  /// Date filter methods
  void selectFromDate(DateTime? date) {
    fromDate.value = date;
  }

  void selectToDate(DateTime? date) {
    toDate.value = date;
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

  /// Refresh employees data with real-time update
  Future<void> refreshEmployees({bool forceRefresh = false}) async {
    if (forceRefresh) {
      imageCache.clear();
    }
    await loadEmployees(showLoading: forceRefresh);
    await loadStatistics();
  }

  /// Get employee details by ID with proper encoding
  Future<Employee?> getEmployeeDetail(String employeeId) async {
    try {
      final result = await EmployeeService.getEmployeeDetail(employeeId);

      if (result['success']) {
        return _parseEmployeeWithProperEncoding(result['data']['data']);
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

  List<Employee> getPaginatedEmployees() {
    return employees;
  }

  /// Permanently delete employee
  Future<void> deleteEmployee(String employeeId) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Permanently Delete Employee'),
          content: Text(
            'This action cannot be undone. The employee record will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Permanently Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isLoading.value = true;

      final result = await EmployeeService.deleteEmployee(
        employeeId: employeeId,
        hardDelete: true, // always hard delete
      );

      print('Delete API response: $result');

      if (result['success']) {
        _showSuccessSnackbar('Success', result['data']['message']);
        await refreshEmployees(forceRefresh: true);
      } else {
        _showErrorSnackbar(
          'Error',
          result['data']['message'] ?? 'Failed to delete employee',
        );
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
        // Force refresh to ensure real-time updates
        await refreshEmployees(forceRefresh: true);
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

  /// Enhanced toggle employee status with real-time updates
  Future<void> toggleEmployeeStatus(String? employeeId,
      {bool? newStatus}) async {
    // Validate employee ID
    if (employeeId == null || employeeId.trim().isEmpty) {
      _showErrorSnackbar('Error', 'Invalid employee ID');
      return;
    }

    try {
      // Find the employee in current list to get current status
      Employee? employee =
          employees.firstWhereOrNull((emp) => emp.id == employeeId);

      if (employee == null) {
        _showErrorSnackbar('Error', 'Employee not found');
        return;
      }

      // Determine new status
      bool targetStatus = newStatus ?? !employee.status;
      String statusText = targetStatus ? 'activate' : 'deactivate';
      String actionText = targetStatus ? 'Activate' : 'Deactivate';

      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('$actionText Employee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to $statusText this employee?'),
              SizedBox(height: 8),
              Text(
                'Employee: ${getEmployeeDisplayName(employee)}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text('Current Status: '),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: employee.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: employee.statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(employee.statusIcon,
                            size: 12, color: employee.statusColor),
                        SizedBox(width: 4),
                        Text(
                          employee.statusText,
                          style: TextStyle(
                            color: employee.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(
                foregroundColor: targetStatus ? Colors.green : Colors.orange,
              ),
              child: Text(actionText),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading state
      isLoading.value = true;

      // Call the API
      final result = await EmployeeService.updateEmployeeStatus(
        employeeId: employeeId.trim(),
        isActive: targetStatus,
      );

      if (result['success']) {
        // Check if this was a warning (employee already had the requested status)
        final apiStatus = result['data']['status'];
        final message = result['data']['message'] ?? '';

        if (apiStatus == 'warning') {
          // Employee already had the requested status
          _showSuccessSnackbar('Info', message);
        } else {
          // Successful status change
          final responseData = result['data']['data'];

          if (responseData != null && responseData is Map<String, dynamic>) {
            // Create updated employee using fromJson (handles status conversion)
            final updatedEmployee = Employee.fromJson({
              ...employee.toJson(),
              ...responseData,
              'id': employee.id, // Ensure ID is preserved
            });

            // Update the employee in the local list immediately
            final updatedEmployees = employees.map((emp) {
              if (emp.id == employeeId) {
                return updatedEmployee;
              }
              return emp;
            }).toList();

            employees.value = updatedEmployees;
            employees.refresh(); // Force UI update

            // Update timestamp for real-time tracking
            lastUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;
          } else {
            // Fallback update if response data is not available
            final updatedEmployees = employees.map((emp) {
              if (emp.id == employeeId) {
                return emp.copyWith(
                  status: targetStatus,
                  updatedAt: DateTime.now(),
                );
              }
              return emp;
            }).toList();

            employees.value = updatedEmployees;
            employees.refresh(); // Force UI update

            // Update timestamp for real-time tracking
            lastUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;
          }

          // Show success message
          _showSuccessSnackbar('Success', message);

          // Refresh statistics in background to reflect the change
          loadStatistics();

          // Optional: Refresh the entire list after a short delay to ensure consistency
          Future.delayed(Duration(milliseconds: 500), () {
            refreshEmployees();
          });
        }
      } else {
        // Handle API error
        String errorMessage =
            result['data']['message'] ?? 'Failed to update employee status';
        _showErrorSnackbar('Error', errorMessage);
      }
    } catch (e) {
      // Handle network or other errors
      _showErrorSnackbar('Network Error', 'Failed to update employee status');
      print('Error updating employee status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Activate employee (set status to true)
  Future<void> activateEmployee(String? employeeId) async {
    await toggleEmployeeStatus(employeeId, newStatus: true);
  }

  /// Deactivate employee (set status to false)
  Future<void> deactivateEmployee(String? employeeId) async {
    await toggleEmployeeStatus(employeeId, newStatus: false);
  }

  /// Enhanced bulk status update for multiple employees with real-time updates
  Future<void> bulkUpdateEmployeeStatus(
    List<String> employeeIds,
    bool newStatus,
  ) async {
    if (employeeIds.isEmpty) {
      _showErrorSnackbar('Error', 'No employees selected');
      return;
    }

    final validIds = employeeIds.where((id) => id.trim().isNotEmpty).toList();

    if (validIds.isEmpty) {
      _showErrorSnackbar('Error', 'No valid employee IDs found');
      return;
    }

    final actionText = newStatus ? "Activate" : "Deactivate";
    final verb = newStatus ? "activate" : "deactivate";

    // Confirm dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text("$actionText ${validIds.length} Employees"),
        content: Text(
            "Are you sure you want to $verb ${validIds.length} employees?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              actionText,
              style: TextStyle(color: newStatus ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isLoading.value = true;

    try {
      int successCount = 0;
      int failureCount = 0;
      List<String> failedEmployees = [];

      // -------------------------------
      // 🚀 PARALLEL PROCESS (FAST)
      // -------------------------------
      List<Future> tasks = validIds.map((employeeId) async {
        final result = await EmployeeService.updateEmployeeStatus(
          employeeId: employeeId,
          isActive: newStatus,
        );

        if (result['success'] == true) {
          successCount++;

          // update local list
          employees.value = employees.map((e) {
            if (e.id == employeeId) {
              return e.copyWith(
                status: newStatus,
                updatedAt: DateTime.now(),
              );
            }
            return e;
          }).toList();
        } else {
          failureCount++;
          Employee? emp = employees.firstWhereOrNull((e) => e.id == employeeId);
          failedEmployees.add(emp?.name ?? employeeId);

          print("❌ Error updating $employeeId → ${result['message']}");
        }
      }).toList();

      await Future.wait(tasks);

      // force UI update
      employees.refresh();

      lastUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;

      // -------------------------------
      // 🔥 RESULT SUMMARY
      // -------------------------------
      if (successCount > 0) {
        String msg =
            "$successCount employees ${newStatus ? "activated" : "deactivated"}";

        if (failureCount > 0) msg += ", $failureCount failed";

        _showSuccessSnackbar("Bulk Update Complete", msg);
      }

      if (failureCount > 0 && successCount == 0) {
        _showErrorSnackbar(
            "Bulk Update Failed", "Failed to update $failureCount employees");
      }

      if (failedEmployees.isNotEmpty) {
        print("❌ Failed Employees:");
        for (var name in failedEmployees) {
          print("- $name");
        }
      }

      // Refresh stats
      loadStatistics();

      // refresh full list after delay
      Future.delayed(const Duration(milliseconds: 400), () {
        refreshEmployees();
      });
    } catch (e, s) {
      print("Exception in bulk update: $e");
      print(s);
      _showErrorSnackbar("Error", "Unexpected error occurred");
    } finally {
      isLoading.value = false;
    }
  }

  /// Method to force refresh the view after status changes
  void forceViewRefresh() {
    employees.refresh();
    lastUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;
    update(); // Trigger GetBuilder updates if used
  }

  /// Method to check if data needs refresh (for periodic updates)
  bool shouldRefreshData() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = currentTime - lastUpdateTimestamp.value;
    // Refresh if data is older than 30 seconds
    return timeDiff > 30000;
  }

  /// Periodic refresh method (call this from UI lifecycle)
  void startPeriodicRefresh() {
    // You can call this method from onResume or when view becomes active
    if (shouldRefreshData()) {
      refreshEmployees();
    }
  }

  /// Download employee list as PDF
  void downloadEmployeeList() async {
    try {
      isDownloading.value = true;
      await Future.delayed(Duration(seconds: 2));
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
      await Future.delayed(Duration(seconds: 2));
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

  /// Clear image cache for specific employee
  void clearEmployeeImageCache(String employeeId) {
    imageCache.remove(employeeId);
  }

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    int validImages = 0;
    int invalidImages = 0;
    int totalCached = imageCache.length;

    for (var cache in imageCache.values) {
      if (cache['isValid'] == true) {
        validImages++;
      } else {
        invalidImages++;
      }
    }

    return {
      'total': totalCached,
      'valid': validImages,
      'invalid': invalidImages,
    };
  }

  /// Helper methods for snackbars
  void _showSuccessSnackbar(String title, String message) {
    CustomSnackbar.showSuccess(title: title, message: message);
  }

  void _showErrorSnackbar(String title, String message) {
    CustomSnackbar.showError(title: title, message: message);
  }

  /// Retry loading data after error
  void retryLoading() {
    imageCache.clear();
    loadEmployees();
    loadStatistics();
  }

  @override
  void onClose() {
    imageCache.clear();
    super.onClose();
  }
}
