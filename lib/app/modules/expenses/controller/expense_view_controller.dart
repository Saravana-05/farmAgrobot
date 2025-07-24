import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/services/expenses/expense_service.dart';
import '../../../routes/app_pages.dart';

class ExpensesViewController extends GetxController {
  var fromDate = Rxn<DateTime>();
  var toDate = Rxn<DateTime>();
  var searchKeyword = ''.obs;
  var isExporting = false.obs;
  var isDownloading = false.obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var totalAmount = 0.0.obs;
  var filteredExpenses = <ExpenseModel>[].obs;
  var allExpenses = <ExpenseModel>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
    refreshExpenses();
  }

  void onRouteBack() {
    // Called when coming back to this route
    if (Get.currentRoute == Routes.EXPENSES) {
      refreshExpenses();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // This will be called when the widget is ready
    loadExpenses();
  }

  // Add this method to be called when returning from other pages
  void onResume() {
    refreshExpenses();
  }

  // Load expenses from API
  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;

      String? fromDateStr = fromDate.value != null
          ? DateFormat('yyyy-MM-dd').format(fromDate.value!)
          : null;
      String? toDateStr = toDate.value != null
          ? DateFormat('yyyy-MM-dd').format(toDate.value!)
          : null;

      final response = await ExpenseService.getAllExpenses(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
        dateFrom: fromDateStr,
        dateTo: toDateStr,
      );

      if (response['status'] == 'success') {
        final data = response['data'];
        final expensesData = data['expenses'] as List;

        filteredExpenses.value = expensesData
            .map((expense) => ExpenseModel.fromJson(expense))
            .toList();

        // Update pagination info
        final pagination = data['pagination'];
        currentPage.value = pagination['current_page'];
        totalPages.value = pagination['total_pages'];
        totalCount.value = pagination['total_count'];
        hasNext.value = pagination['has_next'];
        hasPrevious.value = pagination['has_previous'];

        // Update summary info
        final summary = data['summary'];
        totalAmount.value = summary['total_amount'];

        // Update all expenses for local operations
        allExpenses.value = filteredExpenses;
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to load expenses',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Network error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Search expenses
  void runFilter(String keyword) {
    searchKeyword.value = keyword;
    currentPage.value = 1; // Reset to first page
    loadExpenses();
  }

  // Date filtering
  void selectFromDate(DateTime? date) {
    if (date != null) {
      fromDate.value = date;
      if (toDate.value != null && toDate.value!.isBefore(date)) {
        toDate.value = null;
      }
      currentPage.value = 1;
      loadExpenses();
    }
  }

  void selectToDate(DateTime? date) {
    if (date != null) {
      toDate.value = date;
      currentPage.value = 1;
      loadExpenses();
    }
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadExpenses();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadExpenses();
    }
  }

  // Get current page expenses (since we're using API pagination)
  List<ExpenseModel> getPaginatedExpenses() {
    return filteredExpenses;
  }

  // Export functions
  void exportToExcel() {
    isExporting.value = true;
    // Simulate export process
    Future.delayed(Duration(seconds: 2), () {
      isExporting.value = false;
      Get.snackbar(
        'Export Complete',
        'Excel file has been saved to Downloads',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });
  }

  void downloadExpenseBills() {
    isDownloading.value = true;
    // Simulate download process
    Future.delayed(Duration(seconds: 3), () {
      isDownloading.value = false;
      Get.snackbar(
        'Download Complete',
        'PDF file has been saved to Downloads',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      isLoading.value = true;

      final success = await ExpenseService.deleteExpense(id);

      if (success) {
        Get.snackbar(
          'Success',
          'Expense deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Reload expenses to reflect changes
        loadExpenses();
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete expense',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete expense: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void editExpense(ExpenseModel expense) {
    // Navigate to edit screen or show edit dialog
    Get.snackbar(
      'Edit',
      'Edit functionality would be implemented here',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void viewExpense(ExpenseModel expense) {
    // Show expense details
    Get.dialog(
      AlertDialog(
        title: Text(expense.expenseName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${formatTimestamp(expense.expenseDate as DateTime)}'),
              SizedBox(height: 8),
              Text('Amount: ₹${expense.amount}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Category: ${expense.expenseCategory}'),
              SizedBox(height: 8),
              Text('Spent By: ${expense.spentBy}'),
              SizedBox(height: 8),
              Text('Mode: ${expense.modeOfPayment}'),
              SizedBox(height: 8),
              Text('Description: ${expense.description}'),
              SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Refresh expenses
  Future<void> refreshExpenses() async {
    currentPage.value = 1;
    await loadExpenses();
  }

  // Clear filters
  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    searchKeyword.value = '';
    currentPage.value = 1;
    loadExpenses();
  }

  String formatTimestamp(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Get summary information
  String getSummaryText() {
    return 'Total: ₹${formatIndianAmount(totalAmount.value)} (${totalCount.value} expenses)';
  }

  String formatIndianAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(0)}C'; // Crore
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(0)}L'; // Lakh
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K'; // Thousand
    } else {
      return amount.toStringAsFixed(0); // Less than 1000
    }
  }
}
