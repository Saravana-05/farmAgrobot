import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/attendance/emp_advance_model.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/services/attendance/emp_advance_service.dart';
import '../../../data/services/employee/emp_service.dart';

class EmployeeAdvanceController extends GetxController {
  // Core data observables
  var advances = <EmployeeAdvance>[].obs;
  var advanceSummary = Rxn<EmployeeAdvanceSummaryData>();
  var selectedAdvance = Rxn<EmployeeAdvance>();

  var employees = <Employee>[].obs;
  var isLoadingEmployees = false.obs;
  var selectedEmployee = Rxn<Employee>();

  // Loading states
  var isLoading = false.obs;
  var isCreating = false.obs;
  var isDeleting = false.obs;
  var isFetchingSummary = false.obs;
  var isAdjusting = false.obs;

  // Filter parameters
  var selectedEmployeeId = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var selectedPaymentMode = Rxn<String>();
  var fromDate = Rxn<DateTime>();
  var toDate = Rxn<DateTime>();

  // Pagination
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalRecords = 0.obs;
  var itemsPerPage = 20.obs;

  // Statistics
  var totalAdvanceAmount = 0.0.obs;
  var totalAdjustedAmount = 0.0.obs;
  var pendingAdvances = 0.obs;
  var adjustedAdvances = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// Initialize controller with default values
  void _initializeController() {
    _setDefaultDateRange();
    loadEmployees();
    fetchAdvances();
  }

  /// Set default date range (current month)
  void _setDefaultDateRange() {
    final now = DateTime.now();
    fromDate.value = DateTime(now.year, now.month, 1);
    toDate.value = DateTime(now.year, now.month + 1, 0);
  }

  // MARK: - Data Fetching Methods
  /// Load active employees for the dropdown
  Future<void> loadEmployees() async {
    if (isLoadingEmployees.value) return;

    isLoadingEmployees.value = true;

    try {
      print('👥 Loading employees...');

      final response = await EmployeeService.getEmployeeList(
        page: 1,
        limit: 1000,
        isActive: true,
      );

      final data = response['data'];

      if (response['success'] == true) {
        if (data != null &&
            data['data'] != null &&
            data['data']['employees'] != null) {
          final employeesList = data['data']['employees'] as List;

          employees.value = employeesList
              .map((json) => EmployeeService.employeeFromJson(json))
              .toList();

          employees.sort((a, b) => a.name.compareTo(b.name));

          print('✅ Loaded ${employees.length} active employees');
        } else {
          print('⚠️ No employees found in response');
          employees.value = [];
        }
      } else {
        final errorMsg = data?['message'] ?? 'Failed to load employees';
        _showErrorMessage(errorMsg);
        print('❌ Failed to load employees: $errorMsg');
      }
    } catch (e, stackTrace) {
      print('❌ Exception in loadEmployees: $e');
      print('Stack trace: $stackTrace');
      _handleException('Failed to load employees', e);
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  /// Refresh employee list
  Future<void> refreshEmployees() async {
    await loadEmployees();
  }

  /// Fetch advances with current filters
  Future<void> fetchAdvances({bool resetPage = false}) async {
    if (isLoading.value) return;

    if (resetPage) {
      currentPage.value = 1;
    }

    isLoading.value = true;

    try {
      print('🔍 Fetching advances - Page: ${currentPage.value}');

      final response = await EmployeeAdvanceService.getAdvances(
        employeeId: selectedEmployeeId.value,
        fromDate: fromDate.value,
        toDate: toDate.value,
        status: selectedStatus.value,
        paymentMode: selectedPaymentMode.value,
        page: currentPage.value,
        limit: itemsPerPage.value,
      );

      if (response['success'] == true && response['data'] != null) {
        final advancesResponse =
            EmployeeAdvancesResponse.fromJson(response['data']);

        advances.value = advancesResponse.advances;
        currentPage.value = advancesResponse.pagination.currentPage;
        totalPages.value = advancesResponse.pagination.totalPages;
        totalRecords.value = advancesResponse.pagination.totalCount;

        _calculateStatistics();

        String successMsg = _extractSuccessMessage(
            response, 'Loaded ${advances.length} advance records');
        _showSuccessMessage(successMsg);

        print('✅ Loaded ${advances.length} advances');
      } else {
        _handleApiError(response);
      }
    } catch (e, stackTrace) {
      print('❌ Exception in fetchAdvances: $e');
      print('Stack trace: $stackTrace');
      _handleException('Failed to fetch advances', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch advances for a specific employee
  Future<void> fetchEmployeeAdvances(String employeeId) async {
    selectedEmployeeId.value = employeeId;
    await fetchAdvances(resetPage: true);
  }

  /// Fetch advance detail by ID
  Future<void> fetchAdvanceDetail(String advanceId) async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      print('🔍 Fetching advance detail: $advanceId');

      final response = await EmployeeAdvanceService.getAdvanceDetail(
        advanceId: advanceId,
      );

      if (response['success'] == true && response['data'] != null) {
        final detailResponse = AdvanceDetailResponse.fromJson(response['data']);
        selectedAdvance.value = detailResponse.advance;

        String successMsg =
            _extractSuccessMessage(response, 'Advance details loaded');
        _showSuccessMessage(successMsg);
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to fetch advance detail', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch employee advance summary
  Future<void> fetchEmployeeSummary(String employeeId) async {
    if (isFetchingSummary.value) return;

    isFetchingSummary.value = true;

    try {
      print('📊 Fetching summary for employee: $employeeId');

      final response = await EmployeeAdvanceService.getEmployeeAdvanceSummary(
        employeeId: employeeId,
        fromDate: fromDate.value,
        toDate: toDate.value,
      );

      if (response['success'] == true && response['data'] != null) {
        advanceSummary.value =
            EmployeeAdvanceSummaryData.fromJson(response['data']);

        String successMsg =
            _extractSuccessMessage(response, 'Summary loaded successfully');
        _showSuccessMessage(successMsg);

        _showSummaryDialog();
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _handleException('Failed to fetch employee summary', e);
    } finally {
      isFetchingSummary.value = false;
    }
  }

  // MARK: - Create Advance

  /// Create a new employee advance
  Future<bool> createAdvance({
    required String employeeId,
    required String employeeName,
    required double amount,
    required String paymentMode,
    required DateTime date,
    String? paymentReference,
    String? remarks,
  }) async {
    if (isCreating.value) return false;

    final request = CreateAdvanceRequest(
      employeeId: employeeId,
      amount: amount,
      paymentMode: paymentMode,
      advanceDate: date,
      paymentReference: paymentReference,
      remarks: remarks,
      reason: remarks,
      status: 'pending',
    );

    if (amount <= 0) {
      _showErrorMessage('Amount must be greater than zero');
      return false;
    }

    isCreating.value = true;

    try {
      print('💰 Creating advance: $employeeName - ₹$amount');

      final response = await EmployeeAdvanceService.createAdvance(
        request: request,
      );

      if (response['success'] == true) {
        String successMsg =
            _extractSuccessMessage(response, 'Advance created successfully');

        _showAdvanceCreatedDialog(
          employeeName: employeeName,
          amount: amount,
          message: successMsg,
        );

        await fetchAdvances(resetPage: true);

        return true;
      } else {
        _handleApiError(response);
        return false;
      }
    } catch (e) {
      _handleException('Failed to create advance', e);
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // MARK: - Delete Advance

  /// Delete an advance record
  Future<bool> deleteAdvance(
    String advanceId,
    String employeeName, {
    bool hardDelete = false,
  }) async {
    if (isDeleting.value) return false;

    final confirmed = await _showDeleteConfirmationDialog(
      employeeName: employeeName,
      hardDelete: hardDelete,
    );

    if (!confirmed) return false;

    isDeleting.value = true;

    try {
      print('🗑️ Deleting advance: $advanceId');

      final response = await EmployeeAdvanceService.deleteAdvance(
        advanceId: advanceId,
        hardDelete: hardDelete,
      );

      if (response['success'] == true) {
        String successMsg = _extractSuccessMessage(
            response,
            hardDelete
                ? 'Advance permanently deleted'
                : 'Advance soft deleted');
        _showSuccessMessage(successMsg);

        await fetchAdvances();

        return true;
      } else {
        _handleApiError(response);
        return false;
      }
    } catch (e) {
      _handleException('Failed to delete advance', e);
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  // MARK: - Adjust Advance (NEW FEATURE)

  /// Adjust advance when paying wages
  /// This automatically deducts the advance amount from the wage payment
  Future<Map<String, dynamic>> calculateWageWithAdvanceDeduction({
    required String employeeId,
    required double grossWage,
  }) async {
    try {
      print(
          '💵 Calculating wage with advance deduction for employee: $employeeId');

      // Fetch pending advances for this employee
      final response = await EmployeeAdvanceService.getAdvances(
        employeeId: employeeId,
        status: 'pending', // Only pending advances
        page: 1,
        limit: 100,
      );

      if (response['success'] == true && response['data'] != null) {
        final advancesResponse =
            EmployeeAdvancesResponse.fromJson(response['data']);
        final pendingAdvances = advancesResponse.advances;

        double totalPendingAdvance = 0.0;
        for (var advance in pendingAdvances) {
          totalPendingAdvance += advance.remainingAmount;
        }

        double netWage = grossWage - totalPendingAdvance;

        return {
          'success': true,
          'grossWage': grossWage,
          'totalAdvanceDeduction': totalPendingAdvance,
          'netWage': netWage > 0 ? netWage : 0.0,
          'pendingAdvances': pendingAdvances,
          'advanceCount': pendingAdvances.length,
        };
      }

      return {
        'success': false,
        'error': 'Failed to fetch pending advances',
      };
    } catch (e) {
      print('❌ Error calculating wage with advance: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // MARK: - Filter Methods

  /// Apply filters and fetch data
  void applyFilters({
    String? employeeId,
    String? status,
    String? paymentMode,
    DateTime? from,
    DateTime? to,
  }) {
    selectedEmployeeId.value = employeeId;
    selectedStatus.value = status;
    selectedPaymentMode.value = paymentMode;
    fromDate.value = from;
    toDate.value = to;

    fetchAdvances(resetPage: true);
  }

  /// Clear all filters
  void clearFilters() {
    selectedEmployeeId.value = null;
    selectedStatus.value = null;
    selectedPaymentMode.value = null;
    _setDefaultDateRange();

    fetchAdvances(resetPage: true);
  }

  /// Filter by status
  void filterByStatus(String? status) {
    selectedStatus.value = status;
    fetchAdvances(resetPage: true);
  }

  /// Filter by payment mode
  void filterByPaymentMode(String? paymentMode) {
    selectedPaymentMode.value = paymentMode;
    fetchAdvances(resetPage: true);
  }

  /// Set date range filter
  void setDateRange(DateTime? from, DateTime? to) {
    fromDate.value = from;
    toDate.value = to;
    fetchAdvances(resetPage: true);
  }

  // MARK: - Pagination Methods

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchAdvances();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchAdvances();
    }
  }

  void goToPage(int page) {
    if (page > 0 && page <= totalPages.value) {
      currentPage.value = page;
      fetchAdvances();
    }
  }

  // MARK: - Statistics

  void _calculateStatistics() {
    double totalAdvance = 0.0;
    double totalAdjusted = 0.0;
    int pending = 0;
    int adjusted = 0;

    for (var advance in advances) {
      totalAdvance += advance.amount;
      totalAdjusted += advance.adjustedAmount;

      if (advance.isFullyAdjusted) {
        adjusted++;
      } else {
        pending++;
      }
    }

    totalAdvanceAmount.value = totalAdvance;
    totalAdjustedAmount.value = totalAdjusted;
    pendingAdvances.value = pending;
    adjustedAdvances.value = adjusted;
  }

  // MARK: - UI Dialogs

  void _showAdvanceCreatedDialog({
    required String employeeName,
    required double amount,
    String? message,
  }) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 8),
            const Text('Advance Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
            ],
            Text(
              'Employee: $employeeName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Amount: ₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Future<bool> _showDeleteConfirmationDialog({
    required String employeeName,
    required bool hardDelete,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hardDelete
                  ? 'Are you sure you want to permanently delete this advance?'
                  : 'Are you sure you want to delete this advance?',
            ),
            const SizedBox(height: 8),
            Text(
              'Employee: $employeeName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (hardDelete) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ This action cannot be undone!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSummaryDialog() {
    if (advanceSummary.value == null) return;

    final summary = advanceSummary.value!;
    final stats = summary.summary;

    final paidBreakdown = stats.statusBreakdown['paid'];
    final adjustedBreakdown = stats.statusBreakdown['adjusted'];
    final pendingBreakdown = stats.statusBreakdown['pending'];

    Get.dialog(
      AlertDialog(
        title: Text('Advance Summary - ${summary.employeeName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                'Total Advances',
                stats.totalAdvances.toString(),
              ),
              _buildSummaryRow(
                'Total Amount',
                '₹${stats.totalAmount.toStringAsFixed(2)}',
              ),
              const Divider(),
              if (paidBreakdown != null) ...[
                _buildSummaryRow(
                  'Paid Count',
                  paidBreakdown.count.toString(),
                ),
                _buildSummaryRow(
                  'Paid Amount',
                  '₹${paidBreakdown.amount.toStringAsFixed(2)}',
                ),
              ],
              if (adjustedBreakdown != null) ...[
                _buildSummaryRow(
                  'Adjusted Count',
                  adjustedBreakdown.count.toString(),
                ),
                _buildSummaryRow(
                  'Adjusted Amount',
                  '₹${adjustedBreakdown.amount.toStringAsFixed(2)}',
                ),
              ],
              if (pendingBreakdown != null) ...[
                _buildSummaryRow(
                  'Pending Count',
                  pendingBreakdown.count.toString(),
                ),
                _buildSummaryRow(
                  'Pending Amount',
                  '₹${pendingBreakdown.amount.toStringAsFixed(2)}',
                ),
              ],
              if (summary.dateRange != null &&
                  summary.dateRange!.fromDate != null &&
                  summary.dateRange!.toDate != null) ...[
                const Divider(),
                _buildSummaryRow(
                  'Period',
                  '${summary.dateRange!.fromDate} - ${summary.dateRange!.toDate}',
                ),
              ],
              if (summary.recentAdvances.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Recent Advances:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...summary.recentAdvances.take(5).map((advance) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(advance.advanceDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₹${advance.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // MARK: - Helper Methods

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'adjusted':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getPaymentModeIcon(String paymentMode) {
    switch (paymentMode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.qr_code;
      case 'bank transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.receipt;
      default:
        return Icons.payment;
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // MARK: - Error Handling

  void _handleApiError(Map<String, dynamic> response) {
    String message = 'An error occurred';

    if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['message'] != null) {
        message = data['message'].toString();
      } else if (data['error'] != null) {
        message = data['error'].toString();
      }
    } else if (response['error'] != null) {
      message = response['error'].toString();
    } else if (response['message'] != null) {
      message = response['message'].toString();
    }

    _showErrorMessage(message);
    print('❌ API Error: $message');
  }

  void _handleException(String context, dynamic error) {
    String message = '$context: ${error.toString()}';

    if (error.toString().contains('SocketException')) {
      message = 'No internet connection. Please check your network.';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Request timeout. Please try again.';
    }

    _showErrorMessage(message);
    print('❌ Exception: $message');
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

  String _extractSuccessMessage(
    Map<String, dynamic> response,
    String defaultMessage,
  ) {
    if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }

    if (response['message'] != null) {
      return response['message'].toString();
    }

    return defaultMessage;
  }

  // MARK: - Getters

  bool get hasFilters =>
      selectedEmployeeId.value != null ||
      selectedStatus.value != null ||
      selectedPaymentMode.value != null ||
      fromDate.value != null ||
      toDate.value != null;

  bool get canGoNext => currentPage.value < totalPages.value;

  bool get canGoPrevious => currentPage.value > 1;

  String get paginationText =>
      'Page ${currentPage.value} of ${totalPages.value} (${totalRecords.value} records)';

  double get totalPendingAmount =>
      totalAdvanceAmount.value - totalAdjustedAmount.value;

  @override
  void onClose() {
    super.onClose();
  }
}
