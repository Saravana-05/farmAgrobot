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

  // Revenue and Expense data (now API-driven)
  var totalRevenue = 0.0.obs;
  var totalExpenses = 0.0.obs;
  var monthlyRevenue = 0.0.obs;
  var monthlyExpenses = 0.0.obs;
  var weeklyRevenue = 0.0.obs;
  var weeklyExpenses = 0.0.obs;

  // Yield and Crop data
  var totalYield = 0.0.obs;
  var monthlyYield = 0.0.obs;
  var weeklyYield = 0.0.obs;
  var yieldPerHectare = 0.0.obs;
  var cropValue = 0.0.obs;
  var totalFarmArea = 5.0.obs;
  var averageMarketPrice = 0.0.obs;

  // API-based data storage
  var apiRevenueData = <String, dynamic>{}.obs;
  var apiExpenseData = <String, dynamic>{}.obs;
  var apiCropData = <String, dynamic>{}.obs;
  var apiQuickStats = <String, dynamic>{}.obs;

  // Error handling
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Crop-specific properties
  var selectedCropPeriod = 'current_week'.obs;
  var cropYieldData = <Map<String, dynamic>>[].obs;
  var isLoadingCropData = false.obs;
  var cropYieldHistory = <Map<String, dynamic>>[].obs;

  // Chart data (now API-driven)
  var monthlyData = <Map<String, dynamic>>[].obs;
  var weeklyData = <Map<String, dynamic>>[].obs;
  var expenseBreakdown = <Map<String, dynamic>>[].obs;
  var revenueBreakdown = <Map<String, dynamic>>[].obs;
  var yieldData = <Map<String, dynamic>>[].obs;
  var cropWiseYield = <Map<String, dynamic>>[].obs;

  // Period-specific data storage
  var currentYearData = <String, dynamic>{}.obs;
  var currentMonthData = <String, dynamic>{}.obs;
  var lastYearData = <String, dynamic>{}.obs;
  var lastMonthData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCropData();
    loadDashboardData();
    loadCropYieldData();
  }

  void initializeCropData() {
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
      {
        'id': 'banana',
        'name': 'Banana',
        'imagePath': 'assets/images/crops/banana.png',
        'primaryColor': 0xFFFFEB3B,
        'areaInHectares': 1.8,
        'pricePerKg': 35.0,
        'yields': {
          'current_week': 190.0,
          'current_month': 750.0,
          'last_month': 680.0,
          'current_year': 8500.0,
          'last_year': 7200.0,
        },
        'quality': 'Premium',
        'harvestDate': '2024-12-20',
      },
      // Add more crops as needed
    ];
  }

  /// Main method to load all dashboard data
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Load all dashboard data concurrently
      final results = await Future.wait([
        _loadRevenueData(),
        _loadExpenseData(),
        _loadQuickStats(),
        _loadPeriodSpecificData(),
      ]);

      // Check for critical failures
      bool hasFailure = false;
      for (int i = 0; i < results.length; i++) {
        if (!results[i]) {
          hasFailure = true;
          print('Failed to load data at index $i');
        }
      }

      if (hasFailure) {
        print('Some API calls failed, using partial data');
      }

      // Update calculated totals based on API data
      _calculateTotalsFromAPI();
      _updateChartDataFromAPI();
      _updateYieldMetrics();
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load dashboard data: ${e.toString()}';
      print('Error loading dashboard data: $e');

      // Fallback to minimal dummy data if all APIs fail
      _loadMinimalDummyData();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load revenue data from API
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

  /// Load expense data from API
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

  /// Load quick stats for dashboard overview
  Future<bool> _loadQuickStats() async {
    try {
      final result = await _dashboardService.getQuickRevenueStats();

      if (result['success'] == true) {
        apiQuickStats.value = result['data'] ?? {};
        _processQuickStats(apiQuickStats.value);
        return true;
      } else {
        print('Quick stats API error: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('Quick stats loading error: $e');
      return false;
    }
  }

  /// Load period-specific data for accurate comparisons
  Future<bool> _loadPeriodSpecificData() async {
    try {
      final results = await Future.wait([
        _dashboardService.getCurrentYearRevenueSummary(),
        _dashboardService.getCurrentMonthRevenueSummary(),
        _dashboardService.getLastYearRevenueSummary(),
        _dashboardService.getLastMonthRevenueSummary(),
        _dashboardService.getCurrentYearExpensesSummary(),
        _dashboardService.getCurrentMonthExpensesSummary(),
        _dashboardService.getLastYearExpensesSummary(),
        _dashboardService.getLastMonthExpensesSummary(),
      ]);

      // Process revenue period data
      if (results[0]['success'] == true) {
        currentYearData.value = results[0]['data'] ?? {};
      }
      if (results[1]['success'] == true) {
        currentMonthData.value = results[1]['data'] ?? {};
      }
      if (results[2]['success'] == true) {
        lastYearData.value = results[2]['data'] ?? {};
      }
      if (results[3]['success'] == true) {
        lastMonthData.value = results[3]['data'] ?? {};
      }

      // Process expense period data and merge with revenue data
      _processPeriodSpecificData(results);
      
      return true;
    } catch (e) {
      print('Period specific data loading error: $e');
      return false;
    }
  }

  /// Process revenue data from API response
  void _processRevenueData(Map<String, dynamic> revenueData) {
    try {
      final timePeriods = revenueData['time_periods'] as Map<String, dynamic>? ?? {};

      // Extract revenue values with comprehensive null safety
      final currentYear = timePeriods['current_year'] as Map<String, dynamic>? ?? {};
      final currentMonth = timePeriods['current_month'] as Map<String, dynamic>? ?? {};
      final lastMonth = timePeriods['last_month'] as Map<String, dynamic>? ?? {};
      final allTime = timePeriods['all_time'] as Map<String, dynamic>? ?? {};

      // Update revenue observables
      totalRevenue.value = (currentYear['total_revenue'] as num?)?.toDouble() ?? 
                          (allTime['total_revenue'] as num?)?.toDouble() ?? 0.0;
      
      monthlyRevenue.value = (currentMonth['total_revenue'] as num?)?.toDouble() ?? 0.0;

      // Calculate weekly revenue (approximate from monthly if not available)
      final last30Days = timePeriods['last_30_days'] as Map<String, dynamic>? ?? {};
      weeklyRevenue.value = (last30Days['total_revenue'] as num?)?.toDouble() ?? 0.0 / 4.3;

      // Process revenue breakdown for charts
      final currentYearBreakdown = revenueData['current_year_breakdown'] as Map<String, dynamic>? ?? {};
      final paymentBreakdown = currentYearBreakdown['payment_breakdown'] as List<dynamic>? ?? [];

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

      print('Revenue data processed: Total=${totalRevenue.value}, Monthly=${monthlyRevenue.value}');
    } catch (e) {
      print('Error processing revenue data: $e');
    }
  }

  /// Process expense data from API response
  void _processExpenseData(Map<String, dynamic> expenseData) {
    try {
      final timePeriods = expenseData['time_periods'] as Map<String, dynamic>? ?? {};

      // Extract expense values with comprehensive null safety
      final currentYear = timePeriods['current_year'] as Map<String, dynamic>? ?? {};
      final currentMonth = timePeriods['current_month'] as Map<String, dynamic>? ?? {};
      final lastMonth = timePeriods['last_month'] as Map<String, dynamic>? ?? {};
      final last30Days = timePeriods['last_30_days'] as Map<String, dynamic>? ?? {};
      final allTime = timePeriods['all_time'] as Map<String, dynamic>? ?? {};

      // Update expense observables
      totalExpenses.value = (currentYear['total_amount'] as num?)?.toDouble() ?? 
                           (allTime['total_amount'] as num?)?.toDouble() ?? 0.0;
      
      monthlyExpenses.value = (currentMonth['total_amount'] as num?)?.toDouble() ?? 0.0;

      // Calculate weekly expenses (approximate from monthly if not available)
      weeklyExpenses.value = (last30Days['total_amount'] as num?)?.toDouble() ?? 0.0 / 4.3;

      // Process expense breakdown for charts
      final currentYearBreakdown = expenseData['current_year_breakdown'] as Map<String, dynamic>? ?? {};
      final categoryStats = currentYearBreakdown['category_stats'] as List<dynamic>? ?? [];

      // Convert category breakdown to chart data
      expenseBreakdown.clear();
      for (final item in categoryStats) {
        final breakdownItem = item as Map<String, dynamic>;
        expenseBreakdown.add({
          'name': breakdownItem['expense_category'] ?? 'Unknown',
          'value': (breakdownItem['total_amount'] as num?)?.toDouble() ?? 0.0,
          'color': _getColorForExpenseCategory(breakdownItem['expense_category'] ?? ''),
        });
      }

      print('Expense data processed: Total=${totalExpenses.value}, Monthly=${monthlyExpenses.value}');
    } catch (e) {
      print('Error processing expense data: $e');
    }
  }

  /// Process quick stats data
  void _processQuickStats(Map<String, dynamic> quickStats) {
    try {
      // Quick stats might have additional insights for dashboard cards
      // This can include growth rates, trends, etc.
      final metrics = quickStats['metrics'] as Map<String, dynamic>? ?? {};
      final trends = quickStats['trends'] as Map<String, dynamic>? ?? {};
      
      // You can use this data for additional insights
      print('Quick stats processed with ${metrics.length} metrics and ${trends.length} trends');
    } catch (e) {
      print('Error processing quick stats: $e');
    }
  }

  /// Process period-specific data for accurate period comparisons
  void _processPeriodSpecificData(List<Map<String, dynamic>> results) {
    try {
      // Merge expense data into period-specific storage
      if (results[4]['success'] == true) {
        final expenseData = results[4]['data'] as Map<String, dynamic>? ?? {};
        currentYearData.value = {
          ...currentYearData.value,
          'expenses': expenseData,
        };
      }

      if (results[5]['success'] == true) {
        final expenseData = results[5]['data'] as Map<String, dynamic>? ?? {};
        currentMonthData.value = {
          ...currentMonthData.value,
          'expenses': expenseData,
        };
      }

      if (results[6]['success'] == true) {
        final expenseData = results[6]['data'] as Map<String, dynamic>? ?? {};
        lastYearData.value = {
          ...lastYearData.value,
          'expenses': expenseData,
        };
      }

      if (results[7]['success'] == true) {
        final expenseData = results[7]['data'] as Map<String, dynamic>? ?? {};
        lastMonthData.value = {
          ...lastMonthData.value,
          'expenses': expenseData,
        };
      }

      print('Period-specific data processed successfully');
    } catch (e) {
      print('Error processing period-specific data: $e');
    }
  }

  /// Update chart data based on API responses
  void _updateChartDataFromAPI() {
    try {
      // Generate monthly data based on API data
      _generateMonthlyDataFromAPI();
      
      // Generate weekly data based on API data
      _generateWeeklyDataFromAPI();
      
    } catch (e) {
      print('Error updating chart data from API: $e');
    }
  }

  /// Generate monthly chart data from API responses
  void _generateMonthlyDataFromAPI() {
    try {
      monthlyData.clear();
      
      // This is a simplified version - you should call monthly trend APIs for actual data
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      for (int i = 0; i < months.length; i++) {
        // Use actual monthly data if available, otherwise create reasonable estimates
        double monthlyRev = i == (DateTime.now().month - 1) 
            ? monthlyRevenue.value 
            : monthlyRevenue.value * (0.7 + (math.Random().nextDouble() * 0.6));
            
        double monthlyExp = i == (DateTime.now().month - 1) 
            ? monthlyExpenses.value 
            : monthlyExpenses.value * (0.7 + (math.Random().nextDouble() * 0.6));
            
        double monthlyYld = i == (DateTime.now().month - 1) 
            ? monthlyYield.value 
            : monthlyYield.value * (0.7 + (math.Random().nextDouble() * 0.6));

        monthlyData.add({
          'name': months[i],
          'revenue': monthlyRev,
          'expenses': monthlyExp,
          'yield': monthlyYld,
        });
      }
    } catch (e) {
      print('Error generating monthly data from API: $e');
    }
  }

  /// Generate weekly chart data from API responses
  void _generateWeeklyDataFromAPI() {
    try {
      weeklyData.clear();
      
      for (int week = 1; week <= 4; week++) {
        // Distribute monthly data across weeks with some variation
        double weeklyRev = (monthlyRevenue.value / 4) * (0.8 + (math.Random().nextDouble() * 0.4));
        double weeklyExp = (monthlyExpenses.value / 4) * (0.8 + (math.Random().nextDouble() * 0.4));
        double weeklyYld = (monthlyYield.value / 4) * (0.8 + (math.Random().nextDouble() * 0.4));
        
        weeklyData.add({
          'name': 'Week $week',
          'revenue': weeklyRev,
          'expenses': weeklyExp,
          'yield': weeklyYld,
        });
      }
    } catch (e) {
      print('Error generating weekly data from API: $e');
    }
  }

  /// Calculate derived values from API data
  void _calculateTotalsFromAPI() {
    try {
      // Update current period values based on selected period
      _updateCurrentPeriodFromAPI();
      
      // Recalculate any dependent values
      // Most values are now set directly from API responses
    } catch (e) {
      print('Error calculating totals from API: $e');
    }
  }

  /// Update current period data based on API results and selected period
  void _updateCurrentPeriodFromAPI() {
    try {
      switch (selectedPeriod.value) {
        case 'week':
          // Weekly values are approximated or calculated from monthly data
          break;
        case 'month':
          // Monthly values are set directly from API
          break;
        case 'year':
        default:
          // Yearly values are set directly from API
          break;
      }
    } catch (e) {
      print('Error updating current period from API: $e');
    }
  }

  /// Load crop yield data from API
  Future<void> loadCropYieldData() async {
    isLoadingCropData.value = true;

    try {
      final result = await _cropDashboardService.getCropDashboardStats();

      if (result['success'] == true) {
        apiCropData.value = result['data'] ?? {};
        _processCropData(apiCropData.value);
      } else {
        print('Crop API error: ${result['message']}');
        // Keep existing crop data initialization
        _generateCropYieldHistory();
      }
    } catch (e) {
      print('Error loading crop data: $e');
      // Keep existing crop data initialization
      _generateCropYieldHistory();
    } finally {
      isLoadingCropData.value = false;
    }
  }

  /// Process crop data from API
  void _processCropData(Map<String, dynamic> cropData) {
    try {
      final periods = cropData['periods'] as Map<String, dynamic>? ?? {};
      
      // Extract yield data for different periods
      final currentWeek = periods['current_week'] as Map<String, dynamic>? ?? {};
      final currentMonth = periods['current_month'] as Map<String, dynamic>? ?? {};
      final currentYear = periods['current_year'] as Map<String, dynamic>? ?? {};

      // Update yield values
      weeklyYield.value = (currentWeek['total_yield_records'] as num?)?.toDouble() ?? 0.0;
      monthlyYield.value = (currentMonth['total_yield_records'] as num?)?.toDouble() ?? 0.0;
      totalYield.value = (currentYear['total_yield_records'] as num?)?.toDouble() ?? 0.0;

      // Process crop breakdown if available
      _generateCropWiseYieldFromAPI(cropData);
      _generateCropYieldHistory();
    } catch (e) {
      print('Error processing crop data: $e');
    }
  }

  /// Generate crop-wise yield data from API
  void _generateCropWiseYieldFromAPI(Map<String, dynamic> cropData) {
    try {
      cropWiseYield.clear();

      // You can adapt this based on your actual API response structure
      // For now, keeping existing structure but with API-driven totals
      final existingCrops = [
        {'name': 'Lemon', 'yield': totalYield.value * 0.26, 'area': 2.5, 'price': 45.0, 'color': 0xFFFFA726},
        {'name': 'Banana', 'yield': totalYield.value * 0.42, 'area': 1.8, 'price': 35.0, 'color': 0xFFFFEB3B},
        {'name': 'Cotton', 'yield': totalYield.value * 0.12, 'area': 3.0, 'price': 85.0, 'color': 0xFFE0E0E0},
        {'name': 'Pepper', 'yield': totalYield.value * 0.04, 'area': 0.9, 'price': 380.0, 'color': 0xFF4CAF50},
        {'name': 'Others', 'yield': totalYield.value * 0.16, 'area': 2.0, 'price': 50.0, 'color': 0xFF81C784},
      ];

      cropWiseYield.addAll(existingCrops);
    } catch (e) {
      print('Error generating crop-wise yield from API: $e');
    }
  }

  /// Minimal dummy data as absolute fallback
  void _loadMinimalDummyData() {
    // Only set minimal values if API completely fails
    if (totalRevenue.value == 0.0) totalRevenue.value = 50000.0;
    if (totalExpenses.value == 0.0) totalExpenses.value = 30000.0;
    if (monthlyRevenue.value == 0.0) monthlyRevenue.value = 8500.0;
    if (monthlyExpenses.value == 0.0) monthlyExpenses.value = 5000.0;
    if (totalYield.value == 0.0) totalYield.value = 2000.0;
    if (monthlyYield.value == 0.0) monthlyYield.value = 300.0;

    _updateChartDataFromAPI();
    print('Loaded minimal dummy data as fallback');
  }

  // Helper methods for color assignment
  int _getColorForPaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash': return 0xFF4CAF50;
      case 'card':
      case 'credit_card':
      case 'debit_card': return 0xFF2196F3;
      case 'upi':
      case 'digital': return 0xFFFF9800;
      case 'bank_transfer': return 0xFF9C27B0;
      default: return 0xFF607D8B;
    }
  }

  int _getColorForExpenseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'seeds':
      case 'seed': return 0xFF4CAF50;
      case 'fertilizer':
      case 'fertilizers': return 0xFF2E7D32;
      case 'equipment': return 0xFF66BB6A;
      case 'labor':
      case 'labour': return 0xFF388E3C;
      case 'utilities': return 0xFF81C784;
      case 'fuel': return 0xFFFF5722;
      case 'pesticides': return 0xFF795548;
      default: return 0xFFA5D6A7;
    }
  }

  // API refresh methods
  Future<void> refreshRevenueData() async {
    await _loadRevenueData();
    _calculateTotalsFromAPI();
    _updateChartDataFromAPI();
  }

  Future<void> refreshExpenseData() async {
    await _loadExpenseData();
    _calculateTotalsFromAPI();
    _updateChartDataFromAPI();
  }

  Future<void> refreshCropData() async {
    await loadCropYieldData();
    _updateYieldMetrics();
  }

  Future<void> refreshAllApiData() async {
    await loadDashboardData();
    await loadCropYieldData();
  }

  // Period change with API integration
  Future<void> changePeriodAndRefresh(String period) async {
    selectedPeriod.value = period;

    try {
      switch (period) {
        case 'week':
          // Load current week data if available
          break;
        case 'month':
          final monthlyResult = await _dashboardService.getCurrentMonthRevenueSummary();
          if (monthlyResult['success'] == true) {
            // Process monthly specific data
            final data = monthlyResult['data'] as Map<String, dynamic>?;
            final metrics = data?['metrics'] as Map<String, dynamic>?;
            if (metrics != null) {
              monthlyRevenue.value = (metrics['total_revenue'] as num?)?.toDouble() ?? monthlyRevenue.value;
            }
          }
          
          final expenseResult = await _dashboardService.getCurrentMonthExpensesSummary();
          if (expenseResult['success'] == true) {
            final data = expenseResult['data'] as Map<String, dynamic>?;
            final metrics = data?['metrics'] as Map<String, dynamic>?;
            if (metrics != null) {
              monthlyExpenses.value = (metrics['total_amount'] as num?)?.toDouble() ?? monthlyExpenses.value;
            }
          }
          break;
        case 'year':
          final yearlyResult = await _dashboardService.getCurrentYearRevenueSummary();
          if (yearlyResult['success'] == true) {
            final data = yearlyResult['data'] as Map<String, dynamic>?;
            final metrics = data?['metrics'] as Map<String, dynamic>?;
            if (metrics != null) {
              totalRevenue.value = (metrics['total_revenue'] as num?)?.toDouble() ?? totalRevenue.value;
            }
          }
          
          final expenseYearResult = await _dashboardService.getCurrentYearExpensesSummary();
          if (expenseYearResult['success'] == true) {
            final data = expenseYearResult['data'] as Map<String, dynamic>?;
            final metrics = data?['metrics'] as Map<String, dynamic>?;
            if (metrics != null) {
              totalExpenses.value = (metrics['total_amount'] as num?)?.toDouble() ?? totalExpenses.value;
            }
          }
          break;
      }
    } catch (e) {
      print('Error changing period: $e');
    }

    _updateYieldMetrics();
    _updateChartDataFromAPI();
  }

  // Keep all existing crop and utility methods
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
      case 'current_week': return yields['current_month']?.toDouble() ?? 0.0 / 4;
      case 'current_month': return yields['last_month']?.toDouble() ?? 0.0;
      case 'last_month': return yields['current_month']?.toDouble() ?? 0.0;
      case 'current_year': return yields['last_year']?.toDouble() ?? 0.0;
      case 'last_year': return yields['current_year']?.toDouble() ?? 0.0;
      default: return 0.0;
    }
  }

  String getCropPeriodLabel() {
    switch (selectedCropPeriod.value) {
      case 'current_week': return 'This Week';
      case 'current_month': return 'This Month';
      case 'last_month': return 'Last Month';
      case 'current_year': return 'This Year';
      case 'last_year': return 'Last Year';
      default: return 'This Week';
    }
  }

  double getTotalYieldForPeriod() {
    double total = 0.0;
    for (var crop in cropYieldData) {
      total += getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
    }
    return total;
  }

  double getTotalCropValueForPeriod() {
    double totalValue = 0.0;
    for (var crop in cropYieldData) {
      double yield = getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
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
      double yield = getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
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

    double current = getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
    double previous = getPreviousYieldForPeriod(crop['yields'], selectedCropPeriod.value);

    if (previous == 0) return 0.0;
    return ((current - previous) / previous) * 100;
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
      double cropYield = getCurrentYieldForPeriod(crop['yields'], selectedCropPeriod.value);
      double cropPrice = crop['pricePerKg']?.toDouble() ?? 0.0;
      totalValue += (cropYield * cropPrice);
      totalYieldWeight += cropYield;
    }

    return totalYieldWeight > 0 ? totalValue / totalYieldWeight : 30.0;
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    _updateYieldMetrics();
    _updateChartDataFromAPI();
  }

  void refreshDashboard() {
    loadDashboardData();
    loadCropYieldData();
  }

  void onTabSelected(int index) {
    selectedIndex.value = index;
  }

  // Utility methods for formatting and calculations
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
    return ((totalRevenue.value - totalExpenses.value) / totalRevenue.value) * 100;
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
    double standardYield = 3000.0; // Standard benchmark
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

  List<Map<String, dynamic>> getTopCrops({int limit = 3}) {
    var sortedCrops = List<Map<String, dynamic>>.from(cropWiseYield);
    sortedCrops.sort((a, b) => (b['yield'] * b['price']).compareTo(a['yield'] * a['price']));
    return sortedCrops.take(limit).toList();
  }

  double getCropDiversityIndex() {
    if (cropWiseYield.isEmpty) return 0;

    double totalYield = cropWiseYield.fold(0.0, (sum, crop) => sum + crop['yield']);
    double diversity = 0.0;

    for (var crop in cropWiseYield) {
      double proportion = crop['yield'] / totalYield;
      if (proportion > 0) {
        diversity -= proportion * (math.log(proportion) / math.log(cropWiseYield.length));
      }
    }

    return diversity * 100;
  }

  String getYieldTrend() {
    if (selectedPeriod.value == 'week' && weeklyData.length > 1) {
      double current = weeklyData.last['yield'];
      double previous = weeklyData[weeklyData.length - 2]['yield'];
      double change = ((current - previous) / previous) * 100;
      return change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';
    } else if (selectedPeriod.value == 'month' && monthlyData.length > 1) {
      double current = monthlyData.last['yield'];
      double previous = monthlyData[monthlyData.length - 2]['yield'];
      double change = ((current - previous) / previous) * 100;
      return change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';
    }
    return '0%';
  }

  String getRevenueTrend() {
    // Calculate revenue trend based on period-specific data
    try {
      if (selectedPeriod.value == 'month' && currentMonthData.isNotEmpty && lastMonthData.isNotEmpty) {
        final currentMetrics = currentMonthData['metrics'] as Map<String, dynamic>?;
        final lastMetrics = lastMonthData['metrics'] as Map<String, dynamic>?;
        
        if (currentMetrics != null && lastMetrics != null) {
          double current = (currentMetrics['total_revenue'] as num?)?.toDouble() ?? 0.0;
          double previous = (lastMetrics['total_revenue'] as num?)?.toDouble() ?? 0.0;
          
          if (previous > 0) {
            double change = ((current - previous) / previous) * 100;
            return change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';
          }
        }
      }
      
      if (selectedPeriod.value == 'year' && currentYearData.isNotEmpty && lastYearData.isNotEmpty) {
        final currentMetrics = currentYearData['metrics'] as Map<String, dynamic>?;
        final lastMetrics = lastYearData['metrics'] as Map<String, dynamic>?;
        
        if (currentMetrics != null && lastMetrics != null) {
          double current = (currentMetrics['total_revenue'] as num?)?.toDouble() ?? 0.0;
          double previous = (lastMetrics['total_revenue'] as num?)?.toDouble() ?? 0.0;
          
          if (previous > 0) {
            double change = ((current - previous) / previous) * 100;
            return change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';
          }
        }
      }
    } catch (e) {
      print('Error calculating revenue trend: $e');
    }
    
    return '0%';
  }

  String getExpenseTrend() {
    // Calculate expense trend based on period-specific data
    try {
      if (selectedPeriod.value == 'month' && currentMonthData.isNotEmpty && lastMonthData.isNotEmpty) {
        final currentExpenses = currentMonthData['expenses'] as Map<String, dynamic>?;
        final lastExpenses = lastMonthData['expenses'] as Map<String, dynamic>?;
        
        if (currentExpenses != null && lastExpenses != null) {
          final currentMetrics = currentExpenses['metrics'] as Map<String, dynamic>?;
          final lastMetrics = lastExpenses['metrics'] as Map<String, dynamic>?;
          
          if (currentMetrics != null && lastMetrics != null) {
            double current = (currentMetrics['total_amount'] as num?)?.toDouble() ?? 0.0;
            double previous = (lastMetrics['total_amount'] as num?)?.toDouble() ?? 0.0;
            
            if (previous > 0) {
              double change = ((current - previous) / previous) * 100;
              return change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';
            }
          }
        }
      }
      
      if (selectedPeriod.value == 'year' && currentYearData.isNotEmpty && lastYearData.isNotEmpty) {
        final currentExpenses = currentYearData['expenses'] as Map<String, dynamic>?;
        final lastExpenses = lastYearData['expenses'] as Map<String, dynamic>?;
        
        if (currentExpenses != null && lastExpenses != null) {
          final currentMetrics = currentExpenses['metrics'] as Map<String, dynamic>?;
          final lastMetrics = lastExpenses['metrics'] as Map<String, dynamic>?;
          
          if (currentMetrics != null && lastMetrics != null) {
            double current = (currentMetrics['total_amount'] as num?)?.toDouble() ?? 0.0;
            double previous = (lastMetrics['total_amount'] as num?)?.toDouble() ?? 0.0;
            
            if (previous > 0) {
              double change = ((current - previous) / previous) * 100;
              return change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';
            }
          }
        }
      }
    } catch (e) {
      print('Error calculating expense trend: $e');
    }
    
    return '0%';
  }

  // Additional helper methods for API data validation
  bool get hasValidRevenueData => apiRevenueData.isNotEmpty && totalRevenue.value > 0;
  bool get hasValidExpenseData => apiExpenseData.isNotEmpty && totalExpenses.value >= 0;
  bool get hasValidCropData => apiCropData.isNotEmpty && totalYield.value > 0;

  // Method to check data freshness and trigger refresh if needed
  Future<void> checkAndRefreshStaleData() async {
    try {
      // You can implement logic to check if data is stale
      // For example, check timestamps or implement cache expiry
      
      final now = DateTime.now();
      // Refresh data if it's older than 1 hour (example)
      // This would require storing timestamps when data was last fetched
      
      if (!hasValidRevenueData || !hasValidExpenseData) {
        print('Detected missing data, triggering refresh...');
        await refreshAllApiData();
      }
    } catch (e) {
      print('Error checking stale data: $e');
    }
  }

  // Method to get dashboard summary for quick overview
  Map<String, dynamic> getDashboardSummary() {
    return {
      'total_revenue': totalRevenue.value,
      'total_expenses': totalExpenses.value,
      'profit': totalRevenue.value - totalExpenses.value,
      'profit_margin': getProfitMargin(),
      'total_yield': totalYield.value,
      'yield_per_hectare': yieldPerHectare.value,
      'crop_value': cropValue.value,
      'period': selectedPeriod.value,
      'data_status': {
        'has_revenue_data': hasValidRevenueData,
        'has_expense_data': hasValidExpenseData,
        'has_crop_data': hasValidCropData,
        'has_errors': hasError.value,
        'error_message': errorMessage.value,
      }
    };
  }
}