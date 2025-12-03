import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../config/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:excel/excel.dart';

class YieldAnalyticsController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var isExporting = false.obs;
  var selectedPeriod = 'current_month'.obs;
  var selectedCropId = Rx<String?>(null);
  var dashboardData = Rx<Map<String, dynamic>?>(null);
  var availableCrops = <Map<String, dynamic>>[].obs;
  var customStartDate = Rx<DateTime?>(null);
  var customEndDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Load dashboard data from API
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      final uri = Uri.parse(yieldDashboardUrl).replace(
        queryParameters: selectedCropId.value != null
            ? {'crop_id': selectedCropId.value}
            : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          dashboardData.value = data['data'];

          // Extract available crops from metadata
          if (data['data']['crop_metadata'] != null) {
            availableCrops.value = List<Map<String, dynamic>>.from(
              data['data']['crop_metadata'],
            );
          }
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Failed to load dashboard data',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      Get.snackbar(
        'Error',
        'Failed to load analytics data: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh data
  Future<void> refreshData() async {
    await loadDashboardData();
  }

  /// Select time period
  void selectPeriod(String period) {
    selectedPeriod.value = period;
  }

  /// Select crop filter
  void selectCrop(String? cropId) {
    selectedCropId.value = cropId;
    loadDashboardData();
  }

  /// Apply custom date range
  void applyCustomDateRange() {
    if (customStartDate.value != null && customEndDate.value != null) {
      selectedPeriod.value = 'custom';
      // You would implement custom date range API call here
      loadDashboardData();
    }
  }

  /// Get current period data
  Map<String, dynamic>? getCurrentPeriodData() {
    if (dashboardData.value == null) return null;

    final periods = dashboardData.value!['periods'];
    if (periods == null) return null;

    return periods[selectedPeriod.value];
  }

  /// Get total quantity display
  String getTotalQuantityDisplay() {
    final periodData = getCurrentPeriodData();
    if (periodData == null) return '0';

    final List crops = periodData['crops'] ?? [];
    double total = crops.fold(
      0.0,
      (sum, crop) => sum + (crop['total_quantity'] ?? 0).toDouble(),
    );

    return formatQuantity(total);
  }

  /// Get average quantity display
  String getAverageQuantityDisplay() {
    final periodData = getCurrentPeriodData();
    if (periodData == null) return '0';

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) return '0';

    double total = crops.fold(
      0.0,
      (sum, crop) => sum + (crop['total_quantity'] ?? 0).toDouble(),
    );

    int totalYields = crops.fold(
      0,
      (sum, crop) => sum + (crop['total_yield_records'] ?? 0) as int,
    );

    if (totalYields == 0) return '0';

    double average = total / totalYields;
    return formatQuantity(average);
  }

  /// Format quantity for display
  String formatQuantity(double quantity) {
    if (quantity >= 1000000) {
      return '${(quantity / 1000000).toStringAsFixed(2)}M';
    } else if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(2)}K';
    } else {
      return quantity.toStringAsFixed(1);
    }
  }

  /// Format quantity short for charts
  String formatQuantityShort(double quantity) {
    if (quantity >= 1000000) {
      return '${(quantity / 1000000).toStringAsFixed(0)}M';
    } else if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(0)}K';
    } else {
      return quantity.toInt().toString();
    }
  }

  /// Get max yield count for chart scaling
  double getMaxYieldCount() {
    final periodData = getCurrentPeriodData();
    if (periodData == null) return 10.0;

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) return 10.0;

    int max = crops.fold(
      0,
      (max, crop) {
        int count = crop['total_yield_records'] ?? 0;
        return count > max ? count : max;
      },
    );

    return max.toDouble();
  }

  /// Get max quantity for chart scaling
  double getMaxQuantity() {
    final periodData = getCurrentPeriodData();
    if (periodData == null) return 100.0;

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) return 100.0;

    double max = crops.fold(
      0.0,
      (max, crop) {
        double quantity = (crop['total_quantity'] ?? 0).toDouble();
        return quantity > max ? quantity : max;
      },
    );

    return max;
  }

  /// Get chart color by index
  Color getChartColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  /// Get crop short name
  String getCropShortName(String name) {
    if (name.length <= 8) return name;
    return '${name.substring(0, 8)}..';
  }

  /// Get units display
  String getUnitsDisplay(Map<String, dynamic> crop) {
    final List? units = crop['unique_units'];
    if (units == null || units.isEmpty) return '-';
    return units.join(', ');
  }

  /// Format date
  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Get monthly data for line chart
  List<Map<String, dynamic>> getMonthlyData() {
    // This is a placeholder - you would implement based on your API data
    // For current_year period, you could parse monthly data
    return [
      {'month': 'Jan', 'count': 5},
      {'month': 'Feb', 'count': 8},
      {'month': 'Mar', 'count': 12},
      {'month': 'Apr', 'count': 10},
      {'month': 'May', 'count': 15},
      {'month': 'Jun', 'count': 18},
      {'month': 'Jul', 'count': 14},
      {'month': 'Aug', 'count': 20},
      {'month': 'Sep', 'count': 16},
      {'month': 'Oct', 'count': 22},
      {'month': 'Nov', 'count': 19},
      {'month': 'Dec', 'count': 25},
    ];
  }

  /// Export data to Excel
  Future<void> exportToExcel() async {
    try {
      isExporting.value = true;

      // Create new Excel file
      var excel = Excel.createExcel();
      Sheet sheet = excel['Yield Analytics']; // Creates or opens sheet

      int row = 0;

      // Title
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue("YIELD ANALYTICS REPORT");
      row += 2;

      // Metadata
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue("Report Generated:");
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
              .value =
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
      row++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue("Period:");
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(_getPeriodDisplayName());
      row++;

      if (selectedCropId.value != null) {
        final crop = availableCrops.firstWhere(
          (c) => c['crop_id'] == selectedCropId.value,
          orElse: () => {'crop_name': 'Unknown'},
        );

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue("Filtered Crop:");
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(crop['crop_name'] ?? 'Unknown');
        row++;
      }

      row++;

      // Summary Section
      final data = dashboardData.value;
      if (data != null) {
        final stats = data['overall_stats'] ?? {};

        // Section Title
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue("SUMMARY");
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue("Total Yield Records:");
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value =
            DoubleCellValue((stats['total_yield_records'] ?? 0).toDouble());
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue("Total Crops:");
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = DoubleCellValue((stats['total_crops'] ?? 0).toDouble());
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue("Total Quantity:");
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(getTotalQuantityDisplay());
        row++;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue("Average per Yield:");
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(getAverageQuantityDisplay());
        row++;

        row++;

        // Detailed Crop Breakdown
        final periodData = getCurrentPeriodData();
        if (periodData != null && periodData['crops'] != null) {
          List crops = periodData['crops'];

          // Headers
          List<String> headers = [
            "Crop Name",
            "Total Yields",
            "Total Quantity",
            "Variant Count",
            "Units",
            "Avg Quantity per Yield",
          ];

          for (int i = 0; i < headers.length; i++) {
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
                .value = TextCellValue(headers[i]);
          }
          row++;

          // Data Rows
          for (var crop in crops) {
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
                .value = TextCellValue(crop['crop_name'] ?? 'Unknown');

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                .value = DoubleCellValue((crop['total_yield_records'] ??
                    0)
                .toDouble());

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                .value = DoubleCellValue((crop['total_quantity'] ??
                    0)
                .toDouble());

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                .value = DoubleCellValue((crop['variant_count'] ??
                    0)
                .toDouble());

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
                .value = TextCellValue(getUnitsDisplay(crop));

            double totalQty = (crop['total_quantity'] ?? 0).toDouble();
            int totalYields = crop['total_yield_records'] ?? 0;
            double avg = totalYields > 0 ? totalQty / totalYields : 0;

            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
                .value = DoubleCellValue(avg);

            row++;
          }
        }
      }

      // Save file
      final List<int>? bytes = excel.encode();
      if (bytes == null) throw Exception("Excel encode failed");

      await _saveAndOpenFile(bytes,
          'yield_analytics_${DateTime.now().millisecondsSinceEpoch}.xlsx');

      Get.snackbar(
        'Success',
        'Excel report generated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error exporting Excel: $e");
      Get.snackbar(
        'Error',
        'Failed to export Excel: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Save and open file
  Future<void> _saveAndOpenFile(List<int> bytes, String fileName) async {
    try {
      if (GetPlatform.isAndroid || GetPlatform.isIOS) {
        // Mobile platforms
        final directory = await getExternalStorageDirectory();
        final path = directory!.path;
        final file = File('$path/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open('$path/$fileName');
      } else if (GetPlatform.isWeb) {
        // Web platform
        // Note: You would need to implement web download here
        // This requires additional imports like dart:html
        Get.snackbar(
          'Info',
          'Web download not implemented in this example',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        // Desktop platforms
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        final file = File('$path/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open('$path/$fileName');
      }
    } catch (e) {
      print('Error saving file: $e');
      rethrow;
    }
  }

  /// Get period display name
  String _getPeriodDisplayName() {
    switch (selectedPeriod.value) {
      case 'current_week':
        return 'Current Week';
      case 'current_month':
        return 'Current Month';
      case 'last_month':
        return 'Last Month';
      case 'current_year':
        return 'Current Year';
      case 'custom':
        if (customStartDate.value != null && customEndDate.value != null) {
          return '${formatDate(customStartDate.value!)} - ${formatDate(customEndDate.value!)}';
        }
        return 'Custom Range';
      default:
        return 'Unknown Period';
    }
  }
}
