import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/wages/wages_model.dart';
import '../../../data/services/messages/message_service.dart';
import '../../../data/services/wages/wages_service.dart';
import '../../../routes/app_pages.dart';

class WagesViewController extends GetxController {
  var fromDate = Rxn<DateTime>();
  var toDate = Rxn<DateTime>();
  var searchKeyword = ''.obs;
  var selectedEmployeeId = Rxn<String>();
  var currentOnly = false.obs;
  var minAmount = Rxn<double>();
  var maxAmount = Rxn<double>();
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var totalAmount = 0.0.obs;
  var filteredWages = <Wage>[].obs;
  var allWages = <Wage>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  final MessageService _messageService = MessageService.to;

  // Add a flag to prevent multiple error messages
  var _isShowingError = false;

  @override
  void onInit() {
    super.onInit();
    loadWages();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.WAGES) {
      refreshWages();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Remove duplicate loadWages() call - already called in onInit()
  }

  void onResume() {
    refreshWages();
  }

  // Helper method to show error only once
  void _showErrorOnce(String messageKey, [String? customMessage]) {
    if (!_isShowingError) {
      _isShowingError = true;
      _messageService.showError(messageKey, customMessage);

      // Reset flag after a short delay to allow future error messages
      Future.delayed(Duration(milliseconds: 500), () {
        _isShowingError = false;
      });
    }
  }

  // Load wages from API with proper null safety
  Future<void> loadWages() async {
    try {
      isLoading.value = true;

      String? fromDateStr = fromDate.value != null
          ? DateFormat('yyyy-MM-dd').format(fromDate.value!)
          : null;
      String? toDateStr = toDate.value != null
          ? DateFormat('yyyy-MM-dd').format(toDate.value!)
          : null;

      print('Loading wages with params:');
      print('Page: ${currentPage.value}');
      print('Search: ${searchKeyword.value}');
      print('From Date: $fromDateStr');
      print('To Date: $toDateStr');

      final response = await WageService.getWageList(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
        employeeId: selectedEmployeeId.value,
        currentOnly: currentOnly.value ? true : null,
        minAmount: minAmount.value,
        maxAmount: maxAmount.value,
        fromDate: fromDateStr,
        toDate: toDateStr,
      );

      print('Response received: $response');

      if (response['success'] == true) {
        final data = response['data'];

        if (data == null) {
          _showErrorOnce('error_general', 'No data received from server');
          return;
        }

        print('Response data: $data');

        if (data['status'] == 'success') {
          final wageData = data['data'];

          if (wageData == null) {
            _showErrorOnce('error_general', 'Invalid data structure received');
            return;
          }

          // Handle wages data
          final wagesData = wageData['wages'];
          if (wagesData is List) {
            filteredWages.value = wagesData
                .map((wage) {
                  try {
                    if (wage is Map<String, dynamic>) {
                      return Wage.fromJson(wage);
                    } else {
                      print('Invalid wage data format: $wage');
                      return null;
                    }
                  } catch (e) {
                    print('Error parsing wage: $e');
                    print('Wage data: $wage');
                    return null;
                  }
                })
                .where((wage) => wage != null)
                .cast<Wage>()
                .toList();
          } else {
            print('Wages data is not a list: $wagesData');
            filteredWages.value = [];
          }

          // Handle pagination data
          final pagination = wageData['pagination'];
          if (pagination is Map<String, dynamic>) {
            currentPage.value = pagination['current_page'] ?? 1;
            totalPages.value = pagination['total_pages'] ?? 1;
            totalCount.value = pagination['total_count'] ?? 0;
            hasNext.value = pagination['has_next'] ?? false;
            hasPrevious.value = pagination['has_previous'] ?? false;
          } else {
            // Set default pagination values
            currentPage.value = 1;
            totalPages.value = 1;
            totalCount.value = filteredWages.length;
            hasNext.value = false;
            hasPrevious.value = false;
          }

          // Handle summary data
          final summary = wageData['summary'];
          if (summary is Map<String, dynamic>) {
            totalAmount.value = _parseDouble(summary['total_amount']);
          } else {
            totalAmount.value = 0.0;
          }

          allWages.value = filteredWages;

          // Only show success message for initial load or explicit refresh
          // Remove automatic success message on every filter change
          if (currentPage.value == 1 && !hasActiveFilters) {
            _messageService.showSuccess('success_data_loaded');
          }
        } else {
          String errorMessage = data['message'] ?? 'Unknown error occurred';
          print(
              'API returned error status: ${data['status']}, message: $errorMessage');
          _showErrorOnce('error_general', errorMessage);
        }
      } else {
        final errorData = response['data'];
        String errorMessage = 'Failed to load wages';

        if (errorData != null && errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? errorMessage;
        }

        print('Request failed with status code: ${response['statusCode']}');
        print('Error message: $errorMessage');

        if (response['statusCode'] == 500) {
          _showErrorOnce('error_network', errorMessage);
        } else {
          _showErrorOnce('error_general', errorMessage);
        }
      }
    } catch (e, stackTrace) {
      print('Load wages error: $e');
      print('Stack trace: $stackTrace');
      _showErrorOnce('error_general', 'Failed to load wages: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  // Search wages - debounced to prevent multiple rapid calls
  void runFilter(String keyword) {
    searchKeyword.value = keyword;
    currentPage.value = 1;
    _debounceLoadWages();
  }

  // Debounce mechanism to prevent rapid API calls
  Timer? _debounceTimer;
  void _debounceLoadWages() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      loadWages();
    });
  }

  // Employee filter
  void selectEmployee(String? employeeId) {
    selectedEmployeeId.value = employeeId;
    currentPage.value = 1;
    loadWages();
  }

  // Current only filter
  void toggleCurrentOnly(bool value) {
    currentOnly.value = value;
    currentPage.value = 1;
    loadWages();
  }

  // Amount range filters
  void setMinAmount(double? amount) {
    if (!validateAmountRange(minAmount: amount)) return;
    minAmount.value = amount;
    currentPage.value = 1;
    loadWages();
  }

  void setMaxAmount(double? amount) {
    if (!validateAmountRange(maxAmount: amount)) return;
    maxAmount.value = amount;
    currentPage.value = 1;
    loadWages();
  }

  // Date filtering with validation
  void selectFromDate(DateTime? date) {
    if (date != null) {
      if (toDate.value != null && toDate.value!.isBefore(date)) {
        _messageService.showWarning(
            'validation_date_range', 'To date cannot be before from date');
        return;
      }
      fromDate.value = date;
      currentPage.value = 1;
      loadWages();
    }
  }

  void selectToDate(DateTime? date) {
    if (date != null) {
      if (fromDate.value != null && date.isBefore(fromDate.value!)) {
        _messageService.showWarning(
            'validation_date_range', 'To date cannot be before from date');
        return;
      }
      toDate.value = date;
      currentPage.value = 1;
      loadWages();
    }
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadWages();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadWages();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadWages();
    }
  }

  List<Wage> getPaginatedWages() {
    return filteredWages;
  }

  // Delete wage with better error handling
  Future<void> deleteWage(String id) async {
    if (id.isEmpty) {
      _messageService.showError('validation_id_empty', 'Invalid wage ID');
      return;
    }

    try {
      isLoading.value = true;

      // Call the service method with just the ID (no need for wageId parameter)
      final response = await WageService.deleteWage(id);

      print('Delete response: $response'); // Debug log

      if (response['success'] == true) {
        _messageService.showSuccess(
            'success_wage_deleted', 'Wage deleted successfully');

        // Reload the wages list to reflect the deletion
        await loadWages();
      } else {
        // Extract error message from response
        final errorData = response['data'];
        String errorMessage = 'Failed to delete wage';

        if (errorData != null && errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? errorMessage;
        }

        print('Delete failed: $errorMessage');
        _showErrorOnce('error_wage_delete', errorMessage);
      }
    } catch (e) {
      print('Delete wage error: $e');
      _showErrorOnce(
          'error_wage_delete', 'Failed to delete wage: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void editWage(Wage wage) {
    if (wage.id == null || wage.id!.isEmpty) {
      _messageService.showError('validation_id_empty', 'Invalid wage data');
      return;
    }

    // Navigate to edit wage screen
    Get.toNamed(Routes.EDIT_WAGES, arguments: wage);
  }

  // View wage details
  void viewWage(Wage wage) {
    Get.dialog(
      AlertDialog(
        title: Text(_getSafeString(wage.employeeName, 'Employee Wage')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Employee:', _getSafeString(wage.employeeName, 'Unknown')),
              _buildDetailRow(
                  'Effective From:', formatTimestamp(wage.effectiveFrom)),
              _buildDetailRow(
                  'Effective To:', formatTimestamp(wage.effectiveTo)),
              _buildDetailRow('Amount:', '₹${_getSafeAmount(wage.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (wage.remarks != null && wage.remarks!.isNotEmpty)
                _buildDetailRow('Notes:', wage.remarks!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
          if (wage.id != null)
            TextButton(
              onPressed: () {
                Get.back();
                editWage(wage);
              },
              child: Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> refreshWages() async {
    currentPage.value = 1;
    await loadWages();
  }

  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    searchKeyword.value = '';
    selectedEmployeeId.value = null;
    currentOnly.value = false;
    minAmount.value = null;
    maxAmount.value = null;
    currentPage.value = 1;
    loadWages();
    _messageService.showSuccess(
        'success_form_cleared', 'Filters cleared successfully');
  }

  // Helper method to safely get string values
  String _getSafeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    return value;
  }

  // Helper method to safely get amount
  String _getSafeAmount(dynamic amount) {
    if (amount == null) return '0';

    try {
      if (amount is num) {
        return amount.toStringAsFixed(2);
      } else if (amount is String) {
        double? parsed = double.tryParse(amount);
        return parsed?.toStringAsFixed(2) ?? '0.00';
      }
    } catch (e) {
      print('Error formatting amount: $e');
    }
    return '0.00';
  }

  // Format timestamp with comprehensive null safety
  String formatTimestamp(dynamic date) {
    if (date == null) {
      return 'No Date';
    }

    DateTime? dateTime;

    try {
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        if (date.isEmpty) {
          return 'No Date';
        }
        dateTime = DateTime.parse(date);
      } else if (date is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return 'Invalid Date';
      }

      if (dateTime == null) {
        return 'No Date';
      }

      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error parsing date: $date, Error: $e');
      return 'Invalid Date';
    }
  }

  String getSummaryText() {
    return 'Total: ₹${formatIndianAmount(totalAmount.value)} (${totalCount.value} wages)';
  }

  String formatIndianAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  // Improved validation methods with early return
  bool validateDateRange() {
    if (fromDate.value != null && toDate.value != null) {
      if (toDate.value!.isBefore(fromDate.value!)) {
        return false; // Don't show message here, let caller handle it
      }
    }
    return true;
  }

  bool validateAmountRange({double? minAmount, double? maxAmount}) {
    double? min = minAmount ?? this.minAmount.value;
    double? max = maxAmount ?? this.maxAmount.value;

    if (min != null && max != null) {
      if (max < min) {
        return false; // Don't show message here, let caller handle it
      }
    }
    return true;
  }

  // Get filter summary for display
  String getActiveFiltersText() {
    List<String> filters = [];

    if (searchKeyword.value.isNotEmpty) {
      filters.add('Search: ${searchKeyword.value}');
    }

    if (selectedEmployeeId.value != null) {
      filters.add('Employee ID: ${selectedEmployeeId.value}');
    }

    if (currentOnly.value) {
      filters.add('Current employees only');
    }

    if (fromDate.value != null || toDate.value != null) {
      String dateRange = '';
      if (fromDate.value != null) {
        dateRange += formatTimestamp(fromDate.value);
      }
      if (toDate.value != null) {
        if (dateRange.isNotEmpty) dateRange += ' - ';
        dateRange += formatTimestamp(toDate.value);
      }
      filters.add('Date: $dateRange');
    }

    if (minAmount.value != null || maxAmount.value != null) {
      String amountRange = '';
      if (minAmount.value != null) {
        amountRange += '₹${minAmount.value!.toStringAsFixed(2)}';
      }
      if (maxAmount.value != null) {
        if (amountRange.isNotEmpty) amountRange += ' - ';
        amountRange += '₹${maxAmount.value!.toStringAsFixed(2)}';
      }
      filters.add('Amount: $amountRange');
    }

    return filters.isEmpty ? 'No filters applied' : filters.join(', ');
  }

  // Check if any filters are active
  bool get hasActiveFilters {
    return searchKeyword.value.isNotEmpty ||
        selectedEmployeeId.value != null ||
        currentOnly.value ||
        fromDate.value != null ||
        toDate.value != null ||
        minAmount.value != null ||
        maxAmount.value != null;
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}
