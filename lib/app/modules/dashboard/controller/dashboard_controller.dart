import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/dashboard/dashboard_service.dart';
import '../../../data/services/sales/sales_service.dart';

class DashboardController extends GetxController {
  // Service instance
  final DashboardService _dashboardService = DashboardService();
  final SalesService _salesService = SalesService();
  // Observable variables
  var selectedIndex = 1.obs;
  var selectedPeriod = 'month'.obs;
  var isLoading = false.obs;

  // Recent sales data
  var recentSales = <Map<String, dynamic>>[].obs;
  var recentSalesPeriod = ''.obs;
  var recentSalesPeriodLabel = ''.obs;

  // Revenue and Expense data (API-driven)
  var totalRevenue = 0.0.obs;
  var totalExpenses = 0.0.obs;
  var monthlyRevenue = 0.0.obs;
  var monthlyExpenses = 0.0.obs;
  var weeklyRevenue = 0.0.obs;
  var weeklyExpenses = 0.0.obs;

  // Track if weekly data was fetched from API
  var hasWeeklyRevenueData = false.obs;
  var hasWeeklyExpenseData = false.obs;

  // API-based data storage
  var revenueData = <String, dynamic>{}.obs;
  var expenseData = <String, dynamic>{}.obs;

  // Error handling
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Crop-specific properties
  var selectedCropPeriod = 'current_week'.obs;
  var cropYieldData = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Main method to load all dashboard data
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    // Reset flags before loading
    hasWeeklyRevenueData.value = false;
    hasWeeklyExpenseData.value = false;

    try {
      // Load revenue and expense data concurrently
      final results = await Future.wait([
        _loadRevenueData(),
        _loadExpenseData(),
        _loadRecentSales(),
      ]);

      bool revenueSuccess = results[0];
      bool expenseSuccess = results[1];
      bool recentSalesSuccess = results[2];

      // If both failed, show error
      if (!revenueSuccess && !expenseSuccess) {
        hasError.value = true;
        errorMessage.value =
            'Failed to load financial data. Please check your connection and try again.';
      } else if (!revenueSuccess) {
        print('Warning: Revenue data failed to load');
        hasError.value = true;
        errorMessage.value =
            'Failed to load revenue data. Showing expense data only.';
      } else if (!expenseSuccess) {
        print('Warning: Expense data failed to load');
        // Don't show error, just continue with revenue data
      }

      // Only calculate weekly values if API didn't provide them
      _calculateWeeklyValues();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load dashboard data: ${e.toString()}';
      print('Error loading dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _loadRecentSales() async {
    try {
      final result = await SalesService.getRecentSales();

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null) {
          recentSales.value = List<Map<String, dynamic>>.from(
              (data['sales'] as List).map((e) => Map<String, dynamic>.from(e)));
          recentSalesPeriod.value = data['period'] ?? '';
          recentSalesPeriodLabel.value = data['period_label'] ?? '';

          print('Recent sales loaded: ${recentSales.length} sales');

          return true; // SUCCESS
        }
      } else {
        print('Failed to load recent sales: ${result['message']}');
        return false; // FAIL
      }
    } catch (e) {
      print('Error loading recent sales: $e');
      return false; // FAIL
    }

    return false; // fallback
  }

  /// Load revenue data from API
  Future<bool> _loadRevenueData() async {
    try {
      print('Loading revenue data...');
      final result = await _dashboardService.getRevenueDashboardStats();

      print('Revenue API result: ${result['success']}');

      if (result['success'] == true) {
        final data = result['data'];
        print('Revenue data received: ${data?.toString()}');

        if (data != null) {
          revenueData.value = data;
          _processRevenueData(data);
          return true;
        } else {
          print('Revenue data is null');
          return false;
        }
      } else {
        print('Revenue API error: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Revenue data loading error: $e');
      return false;
    }
  }

  /// Load expense data from API
  Future<bool> _loadExpenseData() async {
    try {
      print('Loading expense data...');
      final expenseResult = await _dashboardService.getExpensesDashboardStats();

      print('Expense API result: ${expenseResult['success']}');

      if (expenseResult['success'] == true) {
        final data = expenseResult['data'];
        print('Expense data received: ${data?.toString()}');

        if (data != null) {
          expenseData.value = data;
          _processExpenseData(data);
          return true;
        } else {
          print('Expense data is null');
          return false;
        }
      } else {
        print('Expense API error: ${expenseResult['message']}');
        // Set expenses to 0 if API fails
        totalExpenses.value = 0.0;
        monthlyExpenses.value = 0.0;
        weeklyExpenses.value = 0.0;
        return false;
      }
    } catch (e) {
      print('Expense data loading error: $e');
      // Set expenses to 0 if API fails
      totalExpenses.value = 0.0;
      monthlyExpenses.value = 0.0;
      weeklyExpenses.value = 0.0;
      return false;
    }
  }

  /// Process revenue data from API response
  /// Your revenue API should return data with 'total_revenue' field
  void _processRevenueData(Map<String, dynamic> data) {
    try {
      print('Processing revenue data...');
      print('Full revenue data structure: ${data.toString()}');

      final timePeriods = data['time_periods'] as Map<String, dynamic>?;

      if (timePeriods == null) {
        print('No time_periods found in revenue data');
        return;
      }

      print('Time periods available: ${timePeriods.keys.toList()}');

      // Current Year Revenue
      if (timePeriods['current_year'] != null) {
        final currentYear = timePeriods['current_year'] as Map<String, dynamic>;
        final yearRevenue =
            currentYear['total_revenue'] ?? currentYear['amount'];
        totalRevenue.value = _convertToDouble(yearRevenue);
        print('Year revenue: ${totalRevenue.value}');
      }

      // Current Month Revenue
      if (timePeriods['current_month'] != null) {
        final currentMonth =
            timePeriods['current_month'] as Map<String, dynamic>;
        final monthRevenue =
            currentMonth['total_revenue'] ?? currentMonth['amount'];
        monthlyRevenue.value = _convertToDouble(monthRevenue);
        print('Month revenue: ${monthlyRevenue.value}');
      }

      // Current Week Revenue (check for actual API data)
      if (timePeriods['current_week'] != null) {
        final currentWeek = timePeriods['current_week'] as Map<String, dynamic>;
        final weekRevenue =
            currentWeek['total_revenue'] ?? currentWeek['amount'];
        weeklyRevenue.value = _convertToDouble(weekRevenue);
        hasWeeklyRevenueData.value = true;
        print(
            '✅ Weekly revenue from API (current_week): ${weeklyRevenue.value}');
      } else if (timePeriods['last_7_days'] != null) {
        final last7Days = timePeriods['last_7_days'] as Map<String, dynamic>;
        final week7Revenue = last7Days['total_revenue'] ?? last7Days['amount'];
        weeklyRevenue.value = _convertToDouble(week7Revenue);
        hasWeeklyRevenueData.value = true;
        print(
            '✅ Weekly revenue from API (last_7_days): ${weeklyRevenue.value}');
      } else {
        print(
            '⚠️ No weekly revenue data available from API - will use fallback');
        hasWeeklyRevenueData.value = false;
      }

      // Fallback to all_time if current_year is 0
      if (totalRevenue.value == 0.0 && timePeriods['all_time'] != null) {
        final allTime = timePeriods['all_time'] as Map<String, dynamic>;
        final allTimeRevenue = allTime['total_revenue'] ?? allTime['amount'];
        totalRevenue.value = _convertToDouble(allTimeRevenue);
        print('Using all_time revenue: ${totalRevenue.value}');
      }

      print(
          '✅ Revenue processed - Total: ₹${totalRevenue.value}, Monthly: ₹${monthlyRevenue.value}, Weekly: ₹${weeklyRevenue.value}');
    } catch (e) {
      print('Error processing revenue data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Process expense data from API response
  /// Your expense API returns data with 'amount' field in time_periods
  void _processExpenseData(Map<String, dynamic> data) {
    try {
      print('Processing expense data...');
      print('Full expense data structure: ${data.toString()}');

      final timePeriods = data['time_periods'] as Map<String, dynamic>?;

      if (timePeriods == null) {
        print('No time_periods found in expense data');
        return;
      }

      print('Time periods available: ${timePeriods.keys.toList()}');

      // Current Year Expenses
      if (timePeriods['current_year'] != null) {
        final currentYear = timePeriods['current_year'] as Map<String, dynamic>;
        final yearExpense = currentYear['amount'];
        totalExpenses.value = _convertToDouble(yearExpense);
        print('Year expenses: ${totalExpenses.value}');
      }

      // Current Month Expenses
      if (timePeriods['current_month'] != null) {
        final currentMonth =
            timePeriods['current_month'] as Map<String, dynamic>;
        final monthExpense = currentMonth['amount'];
        monthlyExpenses.value = _convertToDouble(monthExpense);
        print('Month expenses: ${monthlyExpenses.value}');
      }

      // Current Week Expenses (check for actual API data)
      if (timePeriods['current_week'] != null) {
        final currentWeek = timePeriods['current_week'] as Map<String, dynamic>;
        final weekExpense = currentWeek['amount'];
        weeklyExpenses.value = _convertToDouble(weekExpense);
        hasWeeklyExpenseData.value = true;
        print(
            '✅ Weekly expenses from API (current_week): ${weeklyExpenses.value}');
      } else if (timePeriods['last_7_days'] != null) {
        final last7Days = timePeriods['last_7_days'] as Map<String, dynamic>;
        final week7Expense = last7Days['amount'];
        weeklyExpenses.value = _convertToDouble(week7Expense);
        hasWeeklyExpenseData.value = true;
        print(
            '✅ Weekly expenses from API (last_7_days): ${weeklyExpenses.value}');
      } else {
        print(
            '⚠️ No weekly expense data available from API - will use fallback');
        hasWeeklyExpenseData.value = false;
      }

      // Fallback to all_time if current_year is 0
      if (totalExpenses.value == 0.0 && timePeriods['all_time'] != null) {
        final allTime = timePeriods['all_time'] as Map<String, dynamic>;
        final allTimeExpense = allTime['amount'];
        totalExpenses.value = _convertToDouble(allTimeExpense);
        print('Using all_time expenses: ${totalExpenses.value}');
      }

      print(
          '✅ Expenses processed - Total: ₹${totalExpenses.value}, Monthly: ₹${monthlyExpenses.value}, Weekly: ₹${weeklyExpenses.value}');
    } catch (e) {
      print('Error processing expense data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Helper method to convert various number types to double
  double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Failed to parse string to double: $value');
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Calculate weekly values only if API didn't provide them
  void _calculateWeeklyValues() {
    // Calculate weekly revenue if not from API
    if (!hasWeeklyRevenueData.value && monthlyRevenue.value > 0) {
      weeklyRevenue.value = monthlyRevenue.value / 4.3;
      print(
          '📊 Calculated weekly revenue from monthly (fallback): ${weeklyRevenue.value}');
    } else if (hasWeeklyRevenueData.value) {
      print('📊 Using weekly revenue from API: ${weeklyRevenue.value}');
    }

    // Calculate weekly expenses if not from API
    if (!hasWeeklyExpenseData.value && monthlyExpenses.value > 0) {
      weeklyExpenses.value = monthlyExpenses.value / 4.3;
      print(
          '📊 Calculated weekly expenses from monthly (fallback): ${weeklyExpenses.value}');
    } else if (hasWeeklyExpenseData.value) {
      print('📊 Using weekly expenses from API: ${weeklyExpenses.value}');
    }
  }

  /// Period change handler
  Future<void> changePeriod(String period) async {
    selectedPeriod.value = period;
    print('Period changed to: $period');
    // Data already loaded in loadDashboardData()
    // No need to reload for week/month/year - just use the already loaded data
  }

  // Crop methods
  void changeCropPeriod(String? period) {
    if (period != null) {
      selectedCropPeriod.value = period;
    }
  }

  double getCurrentYieldForPeriod(Map<String, dynamic> yields, String period) {
    return yields[period]?.toDouble() ?? 0.0;
  }

  String getCropPeriodLabel() {
    switch (selectedCropPeriod.value) {
      case 'current_week':
        return 'This Week';
      case 'current_month':
        return 'This Month';
      case 'last_month':
        return 'Last Month';
      case 'current_year':
        return 'This Year';
      case 'last_year':
        return 'Last Year';
      default:
        return 'This Week';
    }
  }

  double getTotalYieldForPeriod() {
    double total = 0.0;
    for (var crop in cropYieldData) {
      total +=
          getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
    }
    return total;
  }

  double getTotalCropValueForPeriod() {
    double totalValue = 0.0;
    for (var crop in cropYieldData) {
      double yield =
          getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
      double price = crop['pricePerKg']?.toDouble() ?? 0.0;
      totalValue += (yield * price);
    }
    return totalValue;
  }

  void refreshDashboard() {
    loadDashboardData();
  }

  void onTabSelected(int index) {
    selectedIndex.value = index;
  }

  String formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).round()}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).round()}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).round()}K';
    }
    return '₹${amount.round()}';
  }

  double getProfitMargin() {
    double revenue = 0.0;
    double expenses = 0.0;

    switch (selectedPeriod.value) {
      case 'week':
        revenue = weeklyRevenue.value;
        expenses = weeklyExpenses.value;
        break;
      case 'month':
        revenue = monthlyRevenue.value;
        expenses = monthlyExpenses.value;
        break;
      case 'year':
      default:
        revenue = totalRevenue.value;
        expenses = totalExpenses.value;
    }

    if (revenue == 0) return 0;
    return ((revenue - expenses) / revenue) * 100;
  }

  String getProfitMarginText() {
    double margin = getProfitMargin();
    return '${margin.toStringAsFixed(1)}%';
  }

  Color getProfitMarginColor() {
    double margin = getProfitMargin();
    if (margin > 30) return Color(0xFF4CAF50);
    if (margin > 15) return Color(0xFFFF9800);
    return Color(0xFFF44336);
  }

  double getCurrentPeriodRevenue() {
    switch (selectedPeriod.value) {
      case 'week':
        return weeklyRevenue.value;
      case 'month':
        return monthlyRevenue.value;
      case 'year':
      default:
        return totalRevenue.value;
    }
  }

  double getCurrentPeriodExpenses() {
    switch (selectedPeriod.value) {
      case 'week':
        return weeklyExpenses.value;
      case 'month':
        return monthlyExpenses.value;
      case 'year':
      default:
        return totalExpenses.value;
    }
  }

  // Get payment status color
  Color getPaymentStatusColor(String? paymentStatus) {
    switch (paymentStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get sale status color
  Color getSaleStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get dashboard summary for quick overview
  Map<String, dynamic> getDashboardSummary() {
    double revenue = getCurrentPeriodRevenue();
    double expenses = getCurrentPeriodExpenses();

    return {
      'total_revenue': revenue,
      'total_expenses': expenses,
      'profit': revenue - expenses,
      'profit_margin': getProfitMargin(),
      'period': selectedPeriod.value,
      'data_status': {
        'has_revenue_data': revenueData.isNotEmpty && revenue > 0,
        'has_expense_data': expenseData.isNotEmpty && expenses >= 0,
        'has_weekly_revenue_from_api': hasWeeklyRevenueData.value,
        'has_weekly_expense_from_api': hasWeeklyExpenseData.value,
        'has_errors': hasError.value,
        'error_message': errorMessage.value,
      }
    };
  }
}
