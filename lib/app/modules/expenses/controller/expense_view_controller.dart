import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/services/expenses/expense_service.dart';
import '../../../global_widgets/custom_snackbar/flash_message.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
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

  // Company details for PDF
  final String companyName = "Your Company Name";
  final String companyAddress =
      "123 Business Street\nCity, State 12345\nPhone: +91 98765 43210\nEmail: info@company.com";
  final String companyLogo = "assets/images/xeLogo.png";

  @override
  void onInit() {
    super.onInit();

    // Load expenses
    loadExpenses(showMessages: false);

    // Check for success message from navigation with proper type checking
    if (Get.arguments != null) {
      // ✅ Check if arguments is actually a Map before casting
      if (Get.arguments is Map<String, dynamic>) {
        final args = Get.arguments as Map<String, dynamic>;

        if (args['showSuccess'] == true) {
          // Show success message with a slight delay for smooth transition
          Future.delayed(const Duration(milliseconds: 500), () {
            CustomFlashMessage.showSuccess(
              title: 'Success',
              message: args['message'] ?? 'Expense added successfully',
            );
          });
        }
      }
    }
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.EXPENSES) {
      refreshExpenses(showMessages: false); // Don't show messages on route back
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadExpenses(showMessages: false); // Don't show messages on ready
  }

  void onResume() {
    refreshExpenses(showMessages: false); // Don't show messages on resume
  }

  // FIXED: Load expenses with optional message display
  Future<void> loadExpenses({bool showMessages = true}) async {
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
        if (data != null) {
          final expensesData = data['expenses'] as List? ?? [];

          filteredExpenses.value = expensesData
              .map((expense) {
                try {
                  return ExpenseModel.fromJson(expense as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing expense: $e');
                  return null;
                }
              })
              .where((expense) => expense != null)
              .cast<ExpenseModel>()
              .toList();

          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
          currentPage.value = pagination['current_page'] ?? 1;
          totalPages.value = pagination['total_pages'] ?? 1;
          totalCount.value = pagination['total_count'] ?? 0;
          hasNext.value = pagination['has_next'] ?? false;
          hasPrevious.value = pagination['has_previous'] ?? false;

          final summary = data['summary'] as Map<String, dynamic>? ?? {};
          totalAmount.value = (summary['total_amount'] ?? 0.0).toDouble();

          allExpenses.value = filteredExpenses;
        }
      } else {
        // Only show error messages when explicitly requested
        if (showMessages) {
          CustomSnackbar.showError(
              title: 'Error', message: response['message']);
        }
      }
    } catch (e) {
      // Only show error messages when explicitly requested
      if (showMessages) {
        CustomSnackbar.showError(
            title: 'Error', message: 'Failed to load expenses');
      }
      print('Load expenses error: $e'); // Keep console logging for debugging
    } finally {
      isLoading.value = false;
    }
  }

  // Search expenses - show messages only for user-initiated searches
  void runFilter(String keyword) {
    searchKeyword.value = keyword;
    currentPage.value = 1;
    loadExpenses(showMessages: false); // Don't show messages for filtering
  }

  // Date filtering - don't show messages for date changes
  void selectFromDate(DateTime? date) {
    if (date != null) {
      fromDate.value = date;
      if (toDate.value != null && toDate.value!.isBefore(date)) {
        toDate.value = null;
      }
      currentPage.value = 1;
      loadExpenses(showMessages: false);
    }
  }

  void selectToDate(DateTime? date) {
    if (date != null) {
      toDate.value = date;
      currentPage.value = 1;
      loadExpenses(showMessages: false);
    }
  }

  // Pagination - don't show messages for page changes
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadExpenses(showMessages: false);
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadExpenses(showMessages: false);
    }
  }

  List<ExpenseModel> getPaginatedExpenses() {
    return filteredExpenses;
  }

  // Check and request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.storage.request();
      }
      return status == PermissionStatus.granted;
    }
    return true;
  }

  // Get all expenses for export - no messages needed
  Future<List<ExpenseModel>> _getAllExpensesForExport() async {
    try {
      String? fromDateStr = fromDate.value != null
          ? DateFormat('yyyy-MM-dd').format(fromDate.value!)
          : null;
      String? toDateStr = toDate.value != null
          ? DateFormat('yyyy-MM-dd').format(toDate.value!)
          : null;

      final response = await ExpenseService.getAllExpenses(
        page: 1,
        limit: 10000,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
        dateFrom: fromDateStr,
        dateTo: toDateStr,
      );

      if (response['status'] == 'success') {
        final data = response['data'];
        if (data != null) {
          final expensesData = data['expenses'] as List? ?? [];
          return expensesData
              .map((expense) {
                try {
                  return ExpenseModel.fromJson(expense as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing expense for export: $e');
                  return null;
                }
              })
              .where((expense) => expense != null)
              .cast<ExpenseModel>()
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching all expenses for export: $e');
    }
    return [];
  }

  // FIXED: Export to Excel - only show meaningful messages
  Future<void> exportToExcel() async {
    if (isExporting.value) return;

    try {
      isExporting.value = true;

      // Check permission
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        CustomSnackbar.showError(
            title: 'Permission Required',
            message: 'Storage permission is needed to save the file');
        return;
      }

      // Get all expenses for export
      List<ExpenseModel> allExpensesForExport =
          await _getAllExpensesForExport();

      if (allExpensesForExport.isEmpty) {
        CustomSnackbar.showError(
          title: 'No Data',
          message: 'No expenses found to export',
        );
        return;
      }

      // Create Excel file
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Expenses'];

      // Remove default sheet if exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Add headers
      List<String> headers = [
        'S.No',
        'Date',
        'Expense Name',
        'Category',
        'Amount (₹)',
        'Spent By',
        'Mode of Payment',
        'Description'
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.green,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add data rows
      for (int i = 0; i < allExpensesForExport.length; i++) {
        ExpenseModel expense = allExpensesForExport[i];
        List<dynamic> rowData = [
          i + 1,
          formatTimestamp(expense.expenseDate),
          expense.expenseName ?? 'No Name',
          expense.expenseCategory ?? 'No Category',
          expense.amount ?? 0.0,
          expense.spentBy ?? 'Unknown',
          expense.modeOfPayment ?? 'Unknown',
          expense.description ?? 'No Description',
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));

          var value = rowData[j];
          if (value is String) {
            cell.value = TextCellValue(value);
          } else if (value is num) {
            cell.value = DoubleCellValue(value.toDouble());
          } else {
            cell.value = TextCellValue(value?.toString() ?? '');
          }
        }
      }

      // Add summary row
      int summaryRow = allExpensesForExport.length + 2;
      var totalCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow));
      totalCell.value = TextCellValue('TOTAL:');
      totalCell.cellStyle = CellStyle(bold: true);

      var amountCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow));
      amountCell.value = DoubleCellValue(totalAmount.value);
      amountCell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.green,
      );

      // Get directory and save file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download/Expenses');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      String fileName =
          'Expenses_${DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now())}.xlsx';
      String filePath = '${directory.path}/$fileName';

      File file = File(filePath);
      List<int>? excelBytes = excel.encode();

      if (excelBytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      await file.writeAsBytes(excelBytes);

      // Show single success message
      CustomSnackbar.showSuccess(
        title: 'Export Complete',
        message: 'Excel file saved successfully',
      );
    } catch (e) {
      print('Excel export error: $e');
      CustomSnackbar.showError(
        title: 'Export Failed',
        message: 'Could not create Excel file',
      );
    } finally {
      isExporting.value = false;
    }
  }

  // FIXED: PDF Export - only show meaningful messages
  Future<void> downloadExpenseBills() async {
    if (isDownloading.value) return;

    try {
      isDownloading.value = true;

      // Check permission
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        CustomSnackbar.showError(
            title: 'Permission Required',
            message: 'Storage permission is needed to save the file');
        return;
      }

      // Get all expenses for export
      List<ExpenseModel> allExpensesForExport =
          await _getAllExpensesForExport();

      if (allExpensesForExport.isEmpty) {
        CustomSnackbar.showError(
            title: 'No Data', message: 'No expenses found to export');
        return;
      }

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header with company info
              pw.Container(
                padding: pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(width: 2, color: PdfColors.green)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _getSafeString(companyName, 'Company Name'),
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          _getSafeString(companyAddress, 'Company Address'),
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Report title and date range
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'EXPENSE REPORT',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    if (_getSafeDateRange().isNotEmpty)
                      pw.Text(
                        _getSafeDateRange(),
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Summary box
              pw.Container(
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Expenses',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${allExpensesForExport.length}',
                            style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Amount',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('₹${_getSafeTotalAmount()}',
                            style: pw.TextStyle(
                                fontSize: 16, color: PdfColors.green800)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Expenses table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(30), // S.No
                  1: pw.FixedColumnWidth(60), // Date
                  2: pw.FlexColumnWidth(2), // Expense Name
                  3: pw.FlexColumnWidth(1.5), // Category
                  4: pw.FixedColumnWidth(50), // Amount
                  5: pw.FlexColumnWidth(1), // Spent By
                  6: pw.FlexColumnWidth(1), // Mode
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.green),
                    children: [
                      _buildTableCell('S.No', isHeader: true),
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Expense Name', isHeader: true),
                      _buildTableCell('Category', isHeader: true),
                      _buildTableCell('Amount (₹)', isHeader: true),
                      _buildTableCell('Spent By', isHeader: true),
                      _buildTableCell('Payment Mode', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...allExpensesForExport.asMap().entries.map((entry) {
                    int index = entry.key;
                    ExpenseModel expense = entry.value;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0
                            ? PdfColors.grey100
                            : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(
                            _formatExpenseDate(expense.expenseDate)),
                        _buildTableCell(
                            _getSafeString(expense.expenseName, 'No Name')),
                        _buildTableCell(_getSafeString(
                            expense.expenseCategory, 'No Category')),
                        _buildTableCell(_getSafeAmount(expense.amount)),
                        _buildTableCell(
                            _getSafeString(expense.spentBy, 'Unknown')),
                        _buildTableCell(
                            _getSafeString(expense.modeOfPayment, 'Unknown')),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Report generated by Expense Management System',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ];
          },
        ),
      );

      // Save PDF file
      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download/Expenses');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      String fileName =
          'Expense_Report_${DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now())}.pdf';
      String filePath = '${directory.path}/$fileName';

      File file = File(filePath);
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      // Show single success message
      CustomSnackbar.showSuccess(
        title: 'PDF Downloaded',
        message: 'Report saved successfully',
      );
    } catch (e) {
      print('PDF export error: $e');
      CustomSnackbar.showError(
        title: 'Download Failed',
        message: 'Could not create PDF report',
      );
    } finally {
      isDownloading.value = false;
    }
  }

  // Helper methods (unchanged but with better error handling)
  String _getSafeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    return value;
  }

  String _getSafeAmount(dynamic amount) {
    if (amount == null) return '0';

    try {
      if (amount is num) {
        return amount.toStringAsFixed(0);
      } else if (amount is String) {
        double? parsed = double.tryParse(amount);
        return parsed?.toStringAsFixed(0) ?? '0';
      }
    } catch (e) {
      print('Error formatting amount: $e');
    }
    return '0';
  }

  String _getSafeTotalAmount() {
    try {
      return totalAmount.value.toStringAsFixed(0);
    } catch (e) {
      print('Error getting total amount: $e');
      return '0.00';
    }
  }

  String _getSafeDateRange() {
    try {
      String fromDateStr = 'Start';
      String toDateStr = 'End';

      if (fromDate.value != null) {
        fromDateStr = formatTimestamp(fromDate.value);
      }

      if (toDate.value != null) {
        toDateStr = formatTimestamp(toDate.value);
      }

      if (fromDateStr != 'Start' || toDateStr != 'End') {
        return 'Period: $fromDateStr - $toDateStr';
      }
    } catch (e) {
      print('Error getting date range: $e');
    }
    return '';
  }

  String _formatExpenseDate(dynamic date) {
    if (date == null) return 'No Date';

    try {
      if (date is DateTime) {
        return formatTimestamp(date);
      }

      if (date is String) {
        if (date.isEmpty) return 'No Date';

        DateTime? parsedDate;
        try {
          parsedDate = DateTime.parse(date);
        } catch (e) {
          try {
            parsedDate = DateFormat('yyyy-MM-dd').parse(date);
          } catch (e) {
            try {
              parsedDate = DateFormat('dd/MM/yyyy').parse(date);
            } catch (e) {
              try {
                parsedDate = DateFormat('MM/dd/yyyy').parse(date);
              } catch (e) {
                return date;
              }
            }
          }
        }

        return parsedDate != null ? formatTimestamp(parsedDate) : date;
      }

      if (date is int) {
        return formatTimestamp(DateTime.fromMillisecondsSinceEpoch(date));
      }

      return date.toString();
    } catch (e) {
      print('Error formatting expense date: $e');
      return 'Invalid Date';
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // FIXED: Delete expense - only show messages for user actions
  Future<void> deleteExpense(String id) async {
    try {
      isLoading.value = true;

      final success = await ExpenseService.deleteExpense(id);

      if (success) {
        CustomSnackbar.showSuccess(
            title: 'Deleted', message: 'Expense deleted successfully');
        loadExpenses(showMessages: false); // Reload without messages
      } else {
        CustomSnackbar.showError(
            title: 'Delete Failed', message: 'Could not delete expense');
      }
    } catch (e) {
      print('Delete expense error: $e');
      CustomSnackbar.showError(
          title: 'Error', message: 'Failed to delete expense');
    } finally {
      isLoading.value = false;
    }
  }

  void editExpense(ExpenseModel expense) {
    // Remove the info message - just implement the functionality
    print('Edit expense: ${expense.id}');
    // Add your edit navigation logic here
  }

  void viewExpense(ExpenseModel expense) {
    Get.dialog(
      AlertDialog(
        title: Text(expense.expenseName ?? 'No Name'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${formatTimestamp(expense.expenseDate)}'),
              SizedBox(height: 8),
              Text('Amount: ₹${_getSafeAmount(expense.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Category: ${expense.expenseCategory ?? 'No Category'}'),
              SizedBox(height: 8),
              Text('Spent By: ${expense.spentBy ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('Mode: ${expense.modeOfPayment ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('Description: ${expense.description ?? 'No Description'}'),
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

  Future<void> refreshExpenses({bool showMessages = true}) async {
    currentPage.value = 1;
    await loadExpenses(showMessages: showMessages);
  }

  void clearFilters() {
    fromDate.value = null;
    toDate.value = null;
    searchKeyword.value = '';
    currentPage.value = 1;
    loadExpenses(
        showMessages: false); // Don't show messages for filter clearing
  }

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
    return 'Total: ₹${formatIndianAmount(totalAmount.value)} (${totalCount.value} expenses)';
  }

  String formatIndianAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(0)}C';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(0)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
