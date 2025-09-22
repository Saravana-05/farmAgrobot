import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../data/services/dashboard/crop_dashboard_service.dart';
import '../../../data/services/dashboard/dashboard_service.dart';

class DashboardController extends GetxController {
  // Service instances
  final DashboardService _dashboardService = DashboardService();
  final CropDashboardService _cropDashboardService = CropDashboardService();

  // Observable variables (existing ones)
  var selectedIndex = 1.obs;
  var selectedPeriod = 'month'.obs;
  var isLoading = false.obs;
  var currentMetricIndex = 0.obs;

  // Revenue and Expense data (existing)
  var totalRevenue = 0.0.obs;
  var totalExpenses = 0.0.obs;
  var monthlyRevenue = 0.0.obs;
  var monthlyExpenses = 0.0.obs;
  var weeklyRevenue = 0.0.obs;
  var weeklyExpenses = 0.0.obs;

  // Yield and Crop data (existing, enhanced)
  var totalYield = 0.0.obs;
  var monthlyYield = 0.0.obs;
  var weeklyYield = 0.0.obs;
  var yieldPerHectare = 0.0.obs;
  var cropValue = 0.0.obs;
  var totalFarmArea = 5.0.obs;
  var averageMarketPrice = 0.0.obs;

  // NEW: API-based data storage
  var apiRevenueData = <String, dynamic>{}.obs;
  var apiExpenseData = <String, dynamic>{}.obs;
  var apiCropData = <String, dynamic>{}.obs;

  // Error handling
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // NEW: Crop-specific properties (keeping existing structure)
  var selectedCropPeriod = 'current_week'.obs;
  var cropYieldData = <Map<String, dynamic>>[].obs;
  var isLoadingCropData = false.obs;
  var cropYieldHistory = <Map<String, dynamic>>[].obs;

  // Chart data (existing)
  var monthlyData = <Map<String, dynamic>>[].obs;
  var weeklyData = <Map<String, dynamic>>[].obs;
  var expenseBreakdown = <Map<String, dynamic>>[].obs;
  var revenueBreakdown = <Map<String, dynamic>>[].obs;
  var yieldData = <Map<String, dynamic>>[].obs;
  var cropWiseYield = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeCropData();
    loadDashboardData();
    loadCropYieldData();
  }

  void initializeCropData() {
    // Keep your existing crop data initialization
    cropYieldData.value = [
      {
        'id': 'lemon',
        'name': 'Lemon',
        'imagePath': 'assets/images/crops/lemon.png',
        'primaryColor': 0xFFFFA726,
        'areaInHectares': 2.5,
        'pricePerKg': 45.0,
        'yields': {
          'current_week': 125.0,
          'current_month': 480.0,
          'last_month': 520.0,
          'current_year': 5200.0,
          'last_year': 4800.0,
        },
        'quality': 'A Grade',
        'harvestDate': '2024-12-15',
      },
      // ... rest of your crops data
    ];
  }

  // NEW: API Integration Methods
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Load all dashboard data concurrently
      final results = await Future.wait([
        _loadRevenueData(),
        _loadExpenseData(),
        _loadCombinedDashboardData(),
      ]);

      // Check for errors
      for (int i = 0; i < results.length; i++) {
        if (!results[i]) {
          print('Failed to load data at index $i');
        }
      }

      // Update calculated totals based on API data
      _calculateTotalsFromAPI();
      _updateYieldMetrics();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load dashboard data: ${e.toString()}';
      print('Error loading dashboard data: $e');

      // Fallback to dummy data if API fails
      _loadDummyData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _loadRevenueData() async {
    try {
      final result = await _dashboardService.getRevenueDashboardStats();

      if (result['success'] == true) {
        apiRevenueData.value = result['data'] ?? {};
        _processRevenueData(apiRevenueData.value);
        return true;
      } else {
        print('Revenue API error: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Revenue data loading error: $e');
      return false;
    }
  }

  Future<bool> _loadExpenseData() async {
    try {
      final result = await _dashboardService.getExpensesDashboardStats();

      if (result['success'] == true) {
        apiExpenseData.value = result['data'] ?? {};
        _processExpenseData(apiExpenseData.value);
        return true;
      } else {
        print('Expense API error: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Expense data loading error: $e');
      return false;
    }
  }

  Future<bool> _loadCombinedDashboardData() async {
    try {
      final result = await _dashboardService.getCombinedDashboardData(
        includeExpenses: true,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};

        // Update both revenue and expense data from combined response
        if (data.containsKey('revenue_stats')) {
          _processRevenueData(data['revenue_stats']);
        }
        if (data.containsKey('expenses_stats')) {
          _processExpenseData(data['expenses_stats']);
        }

        return true;
      } else {
        print('Combined dashboard API error: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Combined dashboard data loading error: $e');
      return false;
    }
  }

  void _processRevenueData(Map<String, dynamic> revenueData) {
    try {
      final timePeriods =
          revenueData['time_periods'] as Map<String, dynamic>? ?? {};

      // Extract revenue values with null safety
      final currentYear =
          timePeriods['current_year'] as Map<String, dynamic>? ?? {};
      final currentMonth =
          timePeriods['current_month'] as Map<String, dynamic>? ?? {};
      final lastMonth =
          timePeriods['last_month'] as Map<String, dynamic>? ?? {};

      totalRevenue.value =
          (currentYear['total_revenue'] as num?)?.toDouble() ?? 0.0;
      monthlyRevenue.value =
          (currentMonth['total_revenue'] as num?)?.toDouble() ?? 0.0;

      // Process revenue breakdown if available
      final currentYearBreakdown =
          revenueData['current_year_breakdown'] as Map<String, dynamic>? ?? {};
      final paymentBreakdown =
          currentYearBreakdown['payment_breakdown'] as List<dynamic>? ?? [];

      // Convert payment breakdown to chart data
      revenueBreakdown.clear();
      for (final item in paymentBreakdown) {
        final breakdownItem = item as Map<String, dynamic>;
        revenueBreakdown.add({
          'name': breakdownItem['payment_mode'] ?? 'Unknown',
          'value': (breakdownItem['total_amount'] as num?)?.toDouble() ?? 0.0,
          'color': _getColorForPaymentMode(breakdownItem['payment_mode'] ?? ''),
        });
      }

      // Generate monthly data from API (you might need to call monthly trend API)
      _generateMonthlyRevenueData();
    } catch (e) {
      print('Error processing revenue data: $e');
    }
  }

  void _processExpenseData(Map<String, dynamic> expenseData) {
    try {
      final timePeriods =
          expenseData['time_periods'] as Map<String, dynamic>? ?? {};

      // Extract expense values with null safety
      final currentYear =
          timePeriods['current_year'] as Map<String, dynamic>? ?? {};
      final currentMonth =
          timePeriods['current_month'] as Map<String, dynamic>? ?? {};

      totalExpenses.value =
          (currentYear['total_amount'] as num?)?.toDouble() ?? 0.0;
      monthlyExpenses.value =
          (currentMonth['total_amount'] as num?)?.toDouble() ?? 0.0;

      // Process expense breakdown if available
      final currentYearBreakdown =
          expenseData['current_year_breakdown'] as Map<String, dynamic>? ?? {};
      final categoryStats =
          currentYearBreakdown['category_stats'] as List<dynamic>? ?? [];

      // Convert category breakdown to chart data
      expenseBreakdown.clear();
      for (final item in categoryStats) {
        final breakdownItem = item as Map<String, dynamic>;
        expenseBreakdown.add({
          'name': breakdownItem['expense_category'] ?? 'Unknown',
          'value': (breakdownItem['total_amount'] as num?)?.toDouble() ?? 0.0,
          'color': _getColorForExpenseCategory(
              breakdownItem['expense_category'] ?? ''),
        });
      }

      // Generate monthly expense data
      _generateMonthlyExpenseData();
    } catch (e) {
      print('Error processing expense data: $e');
    }
  }

  Future<void> loadCropYieldData() async {
    isLoadingCropData.value = true;

    try {
      final result = await _cropDashboardService.getCropDashboardStats();

      if (result['success'] == true) {
        apiCropData.value = result['data'] ?? {};
        _processCropData(apiCropData.value);
      } else {
        print('Crop API error: ${result['message']}');
        // Fallback to existing crop data initialization
        _generateCropYieldHistory();
      }
    } catch (e) {
      print('Error loading crop data: $e');
      // Fallback to existing crop data initialization
      _generateCropYieldHistory();
    } finally {
      isLoadingCropData.value = false;
    }
  }

  void _processCropData(Map<String, dynamic> cropData) {
    try {
      final periods = cropData['periods'] as Map<String, dynamic>? ?? {};
      final overallStats =
          cropData['overall_stats'] as Map<String, dynamic>? ?? {};

      // Extract yield data for different periods
      final currentWeek =
          periods['current_week'] as Map<String, dynamic>? ?? {};
      final currentMonth =
          periods['current_month'] as Map<String, dynamic>? ?? {};
      final currentYear =
          periods['current_year'] as Map<String, dynamic>? ?? {};

      // Update yield values
      weeklyYield.value =
          (currentWeek['total_yield_records'] as num?)?.toDouble() ?? 0.0;
      monthlyYield.value =
          (currentMonth['total_yield_records'] as num?)?.toDouble() ?? 0.0;
      totalYield.value =
          (currentYear['total_yield_records'] as num?)?.toDouble() ?? 0.0;

      // Process crop breakdown if available
      _generateCropWiseYieldFromAPI(cropData);
      _generateCropYieldHistory();
    } catch (e) {
      print('Error processing crop data: $e');
    }
  }

  void _generateCropWiseYieldFromAPI(Map<String, dynamic> cropData) {
    // This would need to be adapted based on your actual API response structure
    cropWiseYield.clear();

    // For now, keep existing structure but you can adapt based on API response
    final existingCrops = [
      {
        'name': 'Lemon',
        'yield': 5200.0,
        'area': 2.5,
        'price': 45.0,
        'color': 0xFFFFA726
      },
      {
        'name': 'Banana',
        'yield': 8500.0,
        'area': 1.8,
        'price': 35.0,
        'color': 0xFFFFEB3B
      },
      {
        'name': 'Cotton',
        'yield': 2400.0,
        'area': 3.0,
        'price': 85.0,
        'color': 0xFFE0E0E0
      },
      {
        'name': 'Pepper',
        'yield': 820.0,
        'area': 0.9,
        'price': 380.0,
        'color': 0xFF4CAF50
      },
      {
        'name': 'Others',
        'yield': 3200.0,
        'area': 2.0,
        'price': 50.0,
        'color': 0xFF81C784
      },
    ];

    cropWiseYield.addAll(existingCrops);
  }

  void _calculateTotalsFromAPI() {
    // Recalculate derived values based on API data
    try {
      // These values are now set from API data processing
      // Additional calculations can be done here if needed

      // Calculate current period yield based on selected period
      _updateCurrentPeriodFromAPI();
    } catch (e) {
      print('Error calculating totals from API: $e');
    }
  }

  void _updateCurrentPeriodFromAPI() {
    // Update current period data based on API results
    switch (selectedPeriod.value) {
      case 'week':
        // weeklyRevenue and weeklyExpenses are handled in API processing
        break;
      case 'month':
        // monthlyRevenue and monthlyExpenses are handled in API processing
        break;
      case 'year':
      default:
        // totalRevenue and totalExpenses are handled in API processing
        break;
    }
  }

  void _generateMonthlyRevenueData() {
    // This should ideally call the monthly trend API
    // For now, generate sample data or call the trend API
    _loadMonthlyTrendData();
  }

  void _generateMonthlyExpenseData() {
    // This should ideally call the monthly expense trend API
    // For now, generate sample data or call the trend API
    _loadMonthlyExpenseTrendData();
  }

  Future<void> _loadMonthlyTrendData() async {
    try {
      // You could call monthly trend APIs here
      // For now, keeping existing monthly data structure
      if (monthlyData.isEmpty) {
        monthlyData.value = [
          {
            'name': 'Jan',
            'revenue': monthlyRevenue.value * 0.8,
            'expenses': monthlyExpenses.value * 0.8,
            'yield': monthlyYield.value * 0.8
          },
          {
            'name': 'Feb',
            'revenue': monthlyRevenue.value * 0.9,
            'expenses': monthlyExpenses.value * 0.9,
            'yield': monthlyYield.value * 0.9
          },
          {
            'name': 'Mar',
            'revenue': monthlyRevenue.value * 0.85,
            'expenses': monthlyExpenses.value * 0.85,
            'yield': monthlyYield.value * 0.85
          },
          {
            'name': 'Apr',
            'revenue': monthlyRevenue.value * 1.1,
            'expenses': monthlyExpenses.value * 1.1,
            'yield': monthlyYield.value * 1.1
          },
          {
            'name': 'May',
            'revenue': monthlyRevenue.value * 0.95,
            'expenses': monthlyExpenses.value * 0.95,
            'yield': monthlyYield.value * 0.95
          },
          {
            'name': 'Jun',
            'revenue': monthlyRevenue.value * 1.2,
            'expenses': monthlyExpenses.value * 1.2,
            'yield': monthlyYield.value * 1.2
          },
          {
            'name': 'Jul',
            'revenue': monthlyRevenue.value * 1.3,
            'expenses': monthlyExpenses.value * 1.3,
            'yield': monthlyYield.value * 1.3
          },
          {
            'name': 'Aug',
            'revenue': monthlyRevenue.value * 1.15,
            'expenses': monthlyExpenses.value * 1.15,
            'yield': monthlyYield.value * 1.15
          },
          {
            'name': 'Sep',
            'revenue': monthlyRevenue.value * 1.25,
            'expenses': monthlyExpenses.value * 1.25,
            'yield': monthlyYield.value * 1.25
          },
          {
            'name': 'Oct',
            'revenue': monthlyRevenue.value * 1.4,
            'expenses': monthlyExpenses.value * 1.4,
            'yield': monthlyYield.value * 1.4
          },
          {
            'name': 'Nov',
            'revenue': monthlyRevenue.value * 1.3,
            'expenses': monthlyExpenses.value * 1.3,
            'yield': monthlyYield.value * 1.3
          },
          {
            'name': 'Dec',
            'revenue': monthlyRevenue.value,
            'expenses': monthlyExpenses.value,
            'yield': monthlyYield.value
          },
        ];
      }
    } catch (e) {
      print('Error loading monthly trend data: $e');
    }
  }

  Future<void> _loadMonthlyExpenseTrendData() async {
    try {
      final result = await _dashboardService.getExpensesMonthlyTrendData();

      if (result['success'] == true) {
        final trendData = result['data'] as Map<String, dynamic>? ?? {};
        // Process monthly expense trend data here
        // Update monthlyData with actual API response
      }
    } catch (e) {
      print('Error loading monthly expense trend data: $e');
    }
  }

  // Helper methods for color assignment
  int _getColorForPaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return 0xFF4CAF50;
      case 'card':
      case 'credit_card':
      case 'debit_card':
        return 0xFF2196F3;
      case 'upi':
      case 'digital':
        return 0xFFFF9800;
      case 'bank_transfer':
        return 0xFF9C27B0;
      default:
        return 0xFF607D8B;
    }
  }

  int _getColorForExpenseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'seeds':
      case 'seed':
        return 0xFF4CAF50;
      case 'fertilizer':
      case 'fertilizers':
        return 0xFF2E7D32;
      case 'equipment':
        return 0xFF66BB6A;
      case 'labor':
      case 'labour':
        return 0xFF388E3C;
      case 'utilities':
        return 0xFF81C784;
      case 'fuel':
        return 0xFFFF5722;
      case 'pesticides':
        return 0xFF795548;
      default:
        return 0xFFA5D6A7;
    }
  }

  // NEW: API-specific refresh methods
  Future<void> refreshRevenueData() async {
    await _loadRevenueData();
    _calculateTotalsFromAPI();
  }

  Future<void> refreshExpenseData() async {
    await _loadExpenseData();
    _calculateTotalsFromAPI();
  }

  Future<void> refreshCropData() async {
    await loadCropYieldData();
    _updateYieldMetrics();
  }

  Future<void> refreshAllApiData() async {
    await loadDashboardData();
    await loadCropYieldData();
  }

  // NEW: Period-specific API calls
  Future<void> changePeriodAndRefresh(String period) async {
    selectedPeriod.value = period;

    // Load period-specific data from APIs
    try {
      switch (period) {
        case 'week':
          // Load current week data
          break;
        case 'month':
          final monthlyResult =
              await _dashboardService.getCurrentMonthRevenueSummary();
          if (monthlyResult['success'] == true) {
            // Process monthly specific data
          }
          break;
        case 'year':
          final yearlyResult =
              await _dashboardService.getCurrentYearRevenueSummary();
          if (yearlyResult['success'] == true) {
            // Process yearly specific data
          }
          break;
      }
    } catch (e) {
      print('Error changing period: $e');
    }

    _updateYieldMetrics();
  }

  // Keep all your existing methods below
  void _generateCropYieldHistory() {
    cropYieldHistory.clear();

    for (var crop in cropYieldData) {
      List<Map<String, dynamic>> history = [];

      for (int week = 1; week <= 4; week++) {
        double baseYield = crop['yields']['current_month'] / 4;
        double variation = (math.Random().nextDouble() - 0.5) * 0.3;
        history.add({
          'period': 'Week $week',
          'yield': baseYield * (1 + variation),
          'date': DateTime.now().subtract(Duration(days: (4 - week) * 7)),
        });
      }

      cropYieldHistory.add({
        'cropId': crop['id'],
        'history': history,
      });
    }
  }

  // Keep all your existing crop-specific methods
  void changeCropPeriod(String? period) {
    if (period != null) {
      selectedCropPeriod.value = period;
    }
  }

  double getCurrentYieldForPeriod(Map<String, dynamic> yields, String period) {
    return yields[period]?.toDouble() ?? 0.0;
  }

  double getPreviousYieldForPeriod(Map<String, dynamic> yields, String period) {
    switch (period) {
      case 'current_week':
        return yields['current_month']?.toDouble() ?? 0.0 / 4;
      case 'current_month':
        return yields['last_month']?.toDouble() ?? 0.0;
      case 'last_month':
        return yields['current_month']?.toDouble() ?? 0.0;
      case 'current_year':
        return yields['last_year']?.toDouble() ?? 0.0;
      case 'last_year':
        return yields['current_year']?.toDouble() ?? 0.0;
      default:
        return 0.0;
    }
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

  // Keep all your existing calculation methods
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

  Map<String, dynamic>? getBestPerformingCrop() {
    if (cropYieldData.isEmpty) return null;

    Map<String, dynamic>? bestCrop;
    double bestValue = 0.0;

    for (var crop in cropYieldData) {
      double yield =
          getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
      double price = crop['pricePerKg']?.toDouble() ?? 0.0;
      double value = yield * price;

      if (value > bestValue) {
        bestValue = value;
        bestCrop = crop;
      }
    }

    return bestCrop;
  }

  double getCropYieldTrend(String cropId) {
    var crop = cropYieldData.firstWhereOrNull((c) => c['id'] == cropId);
    if (crop == null) return 0.0;

    double current =
        getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
    double previous =
        getPreviousYieldForPeriod(crop['yields'], selectedCropPeriod.value);

    if (previous == 0) return 0.0;
    return ((current - previous) / previous) * 100;
  }

  // Fallback to dummy data if API fails
  void _loadDummyData() {
    monthlyData.value = [
      {'name': 'Jan', 'revenue': 45000.0, 'expenses': 28000.0, 'yield': 1200.0},
      {'name': 'Feb', 'revenue': 52000.0, 'expenses': 31000.0, 'yield': 1400.0},
      {'name': 'Mar', 'revenue': 48000.0, 'expenses': 29000.0, 'yield': 1300.0},
      {'name': 'Apr', 'revenue': 61000.0, 'expenses': 35000.0, 'yield': 1650.0},
      {'name': 'May', 'revenue': 55000.0, 'expenses': 33000.0, 'yield': 1500.0},
      {'name': 'Jun', 'revenue': 67000.0, 'expenses': 38000.0, 'yield': 1800.0},
      {'name': 'Jul', 'revenue': 73000.0, 'expenses': 42000.0, 'yield': 1950.0},
      {'name': 'Aug', 'revenue': 69000.0, 'expenses': 40000.0, 'yield': 1850.0},
      {'name': 'Sep', 'revenue': 76000.0, 'expenses': 45000.0, 'yield': 2000.0},
      {'name': 'Oct', 'revenue': 82000.0, 'expenses': 48000.0, 'yield': 2200.0},
      {'name': 'Nov', 'revenue': 78000.0, 'expenses': 46000.0, 'yield': 2100.0},
      {'name': 'Dec', 'revenue': 85000.0, 'expenses': 50000.0, 'yield': 2300.0},
    ];

    weeklyData.value = [
      {
        'name': 'Week 1',
        'revenue': 18000.0,
        'expenses': 11000.0,
        'yield': 480.0
      },
      {
        'name': 'Week 2',
        'revenue': 22000.0,
        'expenses': 13000.0,
        'yield': 590.0
      },
      {
        'name': 'Week 3',
        'revenue': 20000.0,
        'expenses': 12000.0,
        'yield': 540.0
      },
      {
        'name': 'Week 4',
        'revenue': 25000.0,
        'expenses': 14500.0,
        'yield': 690.0
      },
    ];

    cropWiseYield.value = [
      {
        'name': 'Lemon',
        'yield': 5200.0,
        'area': 2.5,
        'price': 45.0,
        'color': 0xFFFFA726
      },
      {
        'name': 'Banana',
        'yield': 8500.0,
        'area': 1.8,
        'price': 35.0,
        'color': 0xFFFFEB3B
      },
      {
        'name': 'Cotton',
        'yield': 2400.0,
        'area': 3.0,
        'price': 85.0,
        'color': 0xFFE0E0E0
      },
      {
        'name': 'Pepper',
        'yield': 820.0,
        'area': 0.9,
        'price': 380.0,
        'color': 0xFF4CAF50
      },
      {
        'name': 'Others',
        'yield': 3200.0,
        'area': 2.0,
        'price': 50.0,
        'color': 0xFF81C784
      },
    ];

    expenseBreakdown.value = [
      {'name': 'Seeds & Plants', 'value': 25000.0, 'color': 0xFF4CAF50},
      {'name': 'Fertilizers', 'value': 18000.0, 'color': 0xFF2E7D32},
      {'name': 'Equipment', 'value': 12000.0, 'color': 0xFF66BB6A},
      {'name': 'Labor', 'value': 22000.0, 'color': 0xFF388E3C},
      {'name': 'Utilities', 'value': 8000.0, 'color': 0xFF81C784},
      {'name': 'Others', 'value': 5000.0, 'color': 0xFFA5D6A7},
    ];

    revenueBreakdown.value = [
      {'name': 'Lemon', 'value': 234000.0, 'color': 0xFFFFA726},
      {'name': 'Banana', 'value': 297500.0, 'color': 0xFFFFEB3B},
      {'name': 'Cotton', 'value': 204000.0, 'color': 0xFFE0E0E0},
      {'name': 'Pepper', 'value': 311600.0, 'color': 0xFF4CAF50},
      {'name': 'Others', 'value': 185000.0, 'color': 0xFF81C784},
    ];

    _calculateTotals();
    _updateYieldMetrics();
  }

  void _calculateTotals() {
    totalRevenue.value =
        monthlyData.fold(0.0, (sum, item) => sum + item['revenue']);
    totalExpenses.value =
        monthlyData.fold(0.0, (sum, item) => sum + item['expenses']);

    var currentMonth = monthlyData.last;
    monthlyRevenue.value = currentMonth['revenue'];
    monthlyExpenses.value = currentMonth['expenses'];
    monthlyYield.value = currentMonth['yield'];

    var currentWeek = weeklyData.last;
    weeklyRevenue.value = currentWeek['revenue'];
    weeklyExpenses.value = currentWeek['expenses'];
    weeklyYield.value = currentWeek['yield'];

    totalYield.value =
        monthlyData.fold(0.0, (sum, item) => sum + item['yield']);
  }

  void _updateYieldMetrics() {
    String period = selectedPeriod.value;

    switch (period) {
      case 'week':
        yieldPerHectare.value = weeklyYield.value / totalFarmArea.value;
        averageMarketPrice.value = _calculateAveragePrice();
        cropValue.value = weeklyYield.value * averageMarketPrice.value;
        break;
      case 'month':
        yieldPerHectare.value = monthlyYield.value / totalFarmArea.value;
        averageMarketPrice.value = _calculateAveragePrice();
        cropValue.value = monthlyYield.value * averageMarketPrice.value;
        break;
      case 'year':
      default:
        yieldPerHectare.value = totalYield.value / totalFarmArea.value;
        averageMarketPrice.value = _calculateAveragePrice();
        cropValue.value = totalYield.value * averageMarketPrice.value;
    }
  }

  double _calculateAveragePrice() {
    if (cropYieldData.isEmpty) return 30.0;

    double totalValue = 0.0;
    double totalYieldWeight = 0.0;

    for (var crop in cropYieldData) {
      double cropYield =
          getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
      double cropPrice = crop['pricePerKg']?.toDouble() ?? 0.0;
      totalValue += (cropYield * cropPrice);
      totalYieldWeight += cropYield;
    }

    return totalYieldWeight > 0 ? totalValue / totalYieldWeight : 30.0;
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    _updateYieldMetrics();
  }

  void refreshDashboard() {
    loadDashboardData();
    loadCropYieldData();
  }

  void onTabSelected(int index) {
    selectedIndex.value = index;
  }

  String formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  String formatYield(double yield) {
    if (yield >= 1000) {
      return '${(yield / 1000).toStringAsFixed(1)}T';
    }
    return '${yield.toStringAsFixed(0)}kg';
  }

  double getProfitMargin() {
    if (totalRevenue.value == 0) return 0;
    return ((totalRevenue.value - totalExpenses.value) / totalRevenue.value) *
        100;
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

  double getYieldEfficiency() {
    double standardYield = 3000.0;
    if (standardYield == 0) return 0;
    return (yieldPerHectare.value / standardYield) * 100;
  }

  String getYieldEfficiencyText() {
    double efficiency = getYieldEfficiency();
    return '${efficiency.toStringAsFixed(1)}%';
  }

  Color getYieldEfficiencyColor() {
    double efficiency = getYieldEfficiency();
    if (efficiency > 80) return Color(0xFF4CAF50);
    if (efficiency > 60) return Color(0xFFFF9800);
    return Color(0xFFF44336);
  }

  double getCurrentPeriodYield() {
    switch (selectedPeriod.value) {
      case 'week':
        return weeklyYield.value;
      case 'month':
        return monthlyYield.value;
      case 'year':
      default:
        return totalYield.value;
    }
  }

  List<Map<String, dynamic>> getTopCrops({int limit = 3}) {
    var sortedCrops = List<Map<String, dynamic>>.from(cropWiseYield);
    sortedCrops.sort(
        (a, b) => (b['yield'] * b['price']).compareTo(a['yield'] * a['price']));
    return sortedCrops.take(limit).toList();
  }

  double getCropDiversityIndex() {
    if (cropWiseYield.isEmpty) return 0;

    double totalYield =
        cropWiseYield.fold(0.0, (sum, crop) => sum + crop['yield']);
    double diversity = 0.0;

    for (var crop in cropWiseYield) {
      double proportion = crop['yield'] / totalYield;
      if (proportion > 0) {
        diversity -= proportion *
            (math.log(proportion) / math.log(cropWiseYield.length));
      }
    }

    return diversity * 100;
  }

  String getYieldTrend() {
    if (selectedPeriod.value == 'week' && weeklyData.length > 1) {
      double current = weeklyData.last['yield'];
      double previous = weeklyData[weeklyData.length - 2]['yield'];
      double change = ((current - previous) / previous) * 100;
      return change >= 0
          ? '+${change.toStringAsFixed(1)}%'
          : '${change.toStringAsFixed(1)}%';
    } else if (selectedPeriod.value == 'month' && monthlyData.length > 1) {
      double current = monthlyData.last['yield'];
      double previous = monthlyData[monthlyData.length - 2]['yield'];
      double change = ((current - previous) / previous) * 100;
      return change >= 0
          ? '+${change.toStringAsFixed(1)}%'
          : '${change.toStringAsFixed(1)}%';
    }
    return '0%';
  }
}
