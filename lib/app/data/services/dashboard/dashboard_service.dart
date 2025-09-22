import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';

class DashboardService extends GetxService {
  /// Get comprehensive expenses dashboard statistics
  /// Returns current year, last year, current month, last month, and breakdown data
  Future<Map<String, dynamic>> getExpensesDashboardStats() async {
    try {
      print('Attempting to fetch expenses dashboard stats from: $dashboardExpenseStatsUrl');

      final response = await http.get(
        Uri.parse(dashboardExpenseStatsUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Expenses dashboard stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Expenses dashboard stats response: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch expenses dashboard stats';
        } catch (e) {
          errorMessage = 'Failed to fetch expenses dashboard stats (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get expenses monthly trend data for current and last year
  /// Returns monthly expense trends with count and amount for each month
  Future<Map<String, dynamic>> getExpensesMonthlyTrendData() async {
    try {
      print('Attempting to fetch expenses monthly trend data from: $monthlyExpenseTrendUrl');

      final response = await http.get(
        Uri.parse(monthlyExpenseTrendUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Expenses monthly trend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Expenses monthly trend response: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch expenses monthly trend data';
        } catch (e) {
          errorMessage = 'Failed to fetch expenses monthly trend data (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get expenses comparison statistics between different periods
  /// Returns yearly and monthly comparison data with percentage changes
  Future<Map<String, dynamic>> getExpensesComparisonStats() async {
    try {
      print('Attempting to fetch expenses comparison stats from: $comparisonExpenseStatsUrl');

      final response = await http.get(
        Uri.parse(comparisonExpenseStatsUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Expenses comparison stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Expenses comparison stats response: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch expenses comparison stats';
        } catch (e) {
          errorMessage = 'Failed to fetch expenses comparison stats (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get expenses summary by period type
  /// [periodType] can be: 'current_year', 'last_year', 'current_month', 'last_month', 'all_time'
  Future<Map<String, dynamic>> getExpensesSummaryByPeriod(String periodType) async {
    if (periodType.isEmpty) {
      return {
        'success': false,
        'message': 'Period type is required',
      };
    }

    try {
      final String url = '$summaryExpenseByPeriodUrl$periodType/';
      print('Attempting to fetch expenses summary for $periodType from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Expenses summary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Expenses summary response for $periodType: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch expenses summary data';
        } catch (e) {
          errorMessage = 'Failed to fetch expenses summary data (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Convenience method to get current year expenses summary
  Future<Map<String, dynamic>> getCurrentYearExpensesSummary() async {
    return await getExpensesSummaryByPeriod('current_year');
  }

  /// Convenience method to get current month expenses summary
  Future<Map<String, dynamic>> getCurrentMonthExpensesSummary() async {
    return await getExpensesSummaryByPeriod('current_month');
  }

  /// Convenience method to get last year expenses summary
  Future<Map<String, dynamic>> getLastYearExpensesSummary() async {
    return await getExpensesSummaryByPeriod('last_year');
  }

  /// Convenience method to get last month expenses summary
  Future<Map<String, dynamic>> getLastMonthExpensesSummary() async {
    return await getExpensesSummaryByPeriod('last_month');
  }

  /// Convenience method to get all time expenses summary
  Future<Map<String, dynamic>> getAllTimeExpensesSummary() async {
    return await getExpensesSummaryByPeriod('all_time');
  }

  /// Get expenses dashboard overview data for main dashboard screen
  /// This combines the most important expenses stats in a single call
  Future<Map<String, dynamic>> getExpensesDashboardOverview() async {
    try {
      // Get dashboard stats which includes time periods and breakdowns
      final dashboardResult = await getExpensesDashboardStats();
      
      if (!dashboardResult['success']) {
        return dashboardResult;
      }

      final dashboardData = dashboardResult['data'];
      
      // Extract the most important data for overview
      final timePeriods = dashboardData['time_periods'];
      final currentYearBreakdown = dashboardData['current_year_breakdown'];
      
      return {
        'success': true,
        'data': {
          'current_year': timePeriods['current_year'],
          'current_month': timePeriods['current_month'],
          'last_year': timePeriods['last_year'],
          'last_month': timePeriods['last_month'],
          'last_30_days': timePeriods['last_30_days'],
          'all_time': timePeriods['all_time'],
          'category_stats': currentYearBreakdown['category_stats'],
          'payment_mode_stats': currentYearBreakdown['payment_mode_stats'],
          'top_spenders': currentYearBreakdown['top_spenders'],
        },
        'message': 'Expenses dashboard overview retrieved successfully',
      };
    } catch (e) {
      print('Error getting expenses dashboard overview: $e');
      return {
        'success': false,
        'message': 'Failed to get expenses dashboard overview: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Static method to get all expenses dashboard data at once (for initialization)
  static Future<Map<String, dynamic>> getAllExpensesDashboardData() async {
    final DashboardService service = DashboardService();
    
    try {
      final futures = await Future.wait([
        service.getExpensesDashboardStats(),
        service.getExpensesMonthlyTrendData(),
        service.getExpensesComparisonStats(),
      ]);

      final dashboardStats = futures[0];
      final monthlyTrend = futures[1];
      final comparisonStats = futures[2];

      // Check if any request failed
      if (!dashboardStats['success'] || 
          !monthlyTrend['success'] || 
          !comparisonStats['success']) {
        
        // Return the first error encountered
        for (var result in futures) {
          if (!result['success']) {
            return result;
          }
        }
      }

      return {
        'success': true,
        'data': {
          'dashboard_stats': dashboardStats['data'],
          'monthly_trend': monthlyTrend['data'],
          'comparison_stats': comparisonStats['data'],
        },
        'message': 'All expenses dashboard data retrieved successfully',
      };
    } catch (e) {
      print('Error getting all expenses dashboard data: $e');
      return {
        'success': false,
        'message': 'Failed to get expenses dashboard data: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get comprehensive revenue dashboard statistics
  /// Returns current year, last year, current month, last month, and breakdown data
  Future<Map<String, dynamic>> getRevenueDashboardStats({String? merchantId}) async {
    try {
      String url = dashboardRevenueUrl;
      
      // Add merchant filter if provided
      if (merchantId != null && merchantId.isNotEmpty) {
        url += '?merchant_id=$merchantId';
      }
      
      print('Attempting to fetch revenue dashboard stats from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Revenue dashboard stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Revenue dashboard stats response: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch revenue dashboard stats';
        } catch (e) {
          errorMessage = 'Failed to fetch revenue dashboard stats (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get quick statistics with time period comparisons for dashboard cards
  /// Optimized for speed and minimal data transfer
  Future<Map<String, dynamic>> getQuickRevenueStats({String? merchantId}) async {
    try {
      String url = dashboardQuickStatsUrl;
      
      // Add merchant filter if provided
      if (merchantId != null && merchantId.isNotEmpty) {
        url += '?merchant_id=$merchantId';
      }
      
      print('Attempting to fetch quick revenue stats from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 20));
        },
      );

      print('Quick revenue stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Quick revenue stats response: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'generated_at': jsonResponse['generated_at'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch quick revenue stats';
        } catch (e) {
          errorMessage = 'Failed to fetch quick revenue stats (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get revenue summary by period type
  /// [periodType] can be: 'current_year', 'last_year', 'current_month', 'last_month', 'all_time'
  Future<Map<String, dynamic>> getRevenueSummaryByPeriod(
    String periodType, {
    String? merchantId,
  }) async {
    if (periodType.isEmpty) {
      return {
        'success': false,
        'message': 'Period type is required',
      };
    }

    try {
      String url = '$dashboardRevenueByPeriodUrl$periodType/';
      
      // Add merchant filter if provided
      if (merchantId != null && merchantId.isNotEmpty) {
        url += '?merchant_id=$merchantId';
      }
      
      print('Attempting to fetch revenue summary for $periodType from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Revenue summary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Revenue summary response for $periodType: $jsonResponse');
        
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        print('Server response: ${response.statusCode} - ${response.body}');
        
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage = errorResponse['message'] ?? 'Failed to fetch revenue summary data';
        } catch (e) {
          errorMessage = 'Failed to fetch revenue summary data (Status: ${response.statusCode})';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}');
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}');
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Convenience method to get current year revenue summary
  Future<Map<String, dynamic>> getCurrentYearRevenueSummary({String? merchantId}) async {
    return await getRevenueSummaryByPeriod('current_year', merchantId: merchantId);
  }

  /// Convenience method to get current month revenue summary
  Future<Map<String, dynamic>> getCurrentMonthRevenueSummary({String? merchantId}) async {
    return await getRevenueSummaryByPeriod('current_month', merchantId: merchantId);
  }

  /// Convenience method to get last year revenue summary
  Future<Map<String, dynamic>> getLastYearRevenueSummary({String? merchantId}) async {
    return await getRevenueSummaryByPeriod('last_year', merchantId: merchantId);
  }

  /// Convenience method to get last month revenue summary
  Future<Map<String, dynamic>> getLastMonthRevenueSummary({String? merchantId}) async {
    return await getRevenueSummaryByPeriod('last_month', merchantId: merchantId);
  }

  /// Convenience method to get all time revenue summary
  Future<Map<String, dynamic>> getAllTimeRevenueSummary({String? merchantId}) async {
    return await getRevenueSummaryByPeriod('all_time', merchantId: merchantId);
  }

  /// Get revenue dashboard overview data for main dashboard screen
  /// This combines the most important revenue stats in a single call
  Future<Map<String, dynamic>> getRevenueDashboardOverview({String? merchantId}) async {
    try {
      // Get dashboard stats which includes time periods and breakdowns
      final dashboardResult = await getRevenueDashboardStats(merchantId: merchantId);
      
      if (!dashboardResult['success']) {
        return dashboardResult;
      }

      final dashboardData = dashboardResult['data'] as Map<String, dynamic>?;
      if (dashboardData == null) {
        return {
          'success': false,
          'message': 'Dashboard data is null',
        };
      }
      
      // Extract the most important data for overview with null safety
      final timePeriods = dashboardData['time_periods'] as Map<String, dynamic>?;
      final comparisons = dashboardData['comparisons'] as Map<String, dynamic>?;
      final currentYearBreakdown = dashboardData['current_year_breakdown'] as Map<String, dynamic>?;
      final recentActivity = dashboardData['recent_activity'] as Map<String, dynamic>?;
      
      return {
        'success': true,
        'data': {
          'current_year': timePeriods?['current_year'],
          'current_month': timePeriods?['current_month'],
          'last_year': timePeriods?['last_year'],
          'last_month': timePeriods?['last_month'],
          'all_time': timePeriods?['all_time'],
          'yearly_comparison': comparisons?['yearly_comparison'],
          'monthly_comparison': comparisons?['monthly_comparison'],
          'payment_breakdown': currentYearBreakdown?['payment_breakdown'],
          'recent_activity': recentActivity,
        },
        'message': 'Revenue dashboard overview retrieved successfully',
      };
    } catch (e) {
      print('Error getting revenue dashboard overview: $e');
      return {
        'success': false,
        'message': 'Failed to get revenue dashboard overview: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get combined revenue and expenses dashboard data
  /// This is useful for main dashboard screens that show both metrics
  Future<Map<String, dynamic>> getCombinedDashboardData({
    String? merchantId,
    bool includeExpenses = true,
  }) async {
    try {
      final futures = <Future<Map<String, dynamic>>>[];
      
      // Always include revenue data
      futures.add(getRevenueDashboardStats(merchantId: merchantId));
      futures.add(getQuickRevenueStats(merchantId: merchantId));
      
      // Add expenses data if requested
      if (includeExpenses) {
        final expensesService = DashboardService();
        futures.add(expensesService.getExpensesDashboardStats());
        futures.add(expensesService.getExpensesComparisonStats());
      }

      final results = await Future.wait(futures);
      
      // Check if any request failed
      for (var result in results) {
        if (result['success'] != true) {
          return result; // Return first error encountered
        }
      }

      final response = {
        'success': true,
        'data': {
          'revenue_stats': results[0]['data'],
          'revenue_quick_stats': results[1]['data'],
        },
        'message': 'Combined dashboard data retrieved successfully',
      };

      if (includeExpenses && results.length > 2) {
        final responseData = response['data'] as Map<String, dynamic>;
        responseData['expenses_stats'] = results[2]['data'];
        responseData['expenses_comparison'] = results[3]['data'];
      }

      return response;
    } catch (e) {
      print('Error getting combined dashboard data: $e');
      return {
        'success': false,
        'message': 'Failed to get combined dashboard data: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Static method to get all revenue dashboard data at once (for initialization)
  static Future<Map<String, dynamic>> getAllRevenueDashboardData({
    String? merchantId,
  }) async {
    final DashboardService service = DashboardService();
    
    try {
      final futures = await Future.wait([
        service.getRevenueDashboardStats(merchantId: merchantId),
        service.getQuickRevenueStats(merchantId: merchantId),
        service.getCurrentYearRevenueSummary(merchantId: merchantId),
        service.getCurrentMonthRevenueSummary(merchantId: merchantId),
      ]);

      final dashboardStats = futures[0];
      final quickStats = futures[1];
      final currentYearSummary = futures[2];
      final currentMonthSummary = futures[3];

      // Check if any request failed with null safety
      final results = [dashboardStats, quickStats, currentYearSummary, currentMonthSummary];
      for (var result in results) {
        if (result['success'] != true) {
          return result; // Return first error encountered
        }
      }

      return {
        'success': true,
        'data': {
          'dashboard_stats': dashboardStats['data'],
          'quick_stats': quickStats['data'],
          'current_year_summary': currentYearSummary['data'],
          'current_month_summary': currentMonthSummary['data'],
        },
        'message': 'All revenue dashboard data retrieved successfully',
      };
    } catch (e) {
      print('Error getting all revenue dashboard data: $e');
      return {
        'success': false,
        'message': 'Failed to get revenue dashboard data: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get revenue comparison between two periods
  Future<Map<String, dynamic>> getRevenueComparison({
    required String currentPeriod,
    required String comparisonPeriod,
    String? merchantId,
  }) async {
    try {
      final futures = await Future.wait([
        getRevenueSummaryByPeriod(currentPeriod, merchantId: merchantId),
        getRevenueSummaryByPeriod(comparisonPeriod, merchantId: merchantId),
      ]);

      final currentResult = futures[0];
      final comparisonResult = futures[1];

      if (currentResult['success'] != true || comparisonResult['success'] != true) {
        return {
          'success': false,
          'message': 'Failed to fetch comparison data',
        };
      }

      final currentData = currentResult['data'] as Map<String, dynamic>?;
      final comparisonData = comparisonResult['data'] as Map<String, dynamic>?;
      
      if (currentData == null || comparisonData == null) {
        return {
          'success': false,
          'message': 'Comparison data is null',
        };
      }
      
      // Calculate percentage changes with null safety
      final currentMetrics = currentData['metrics'] as Map<String, dynamic>?;
      final comparisonMetrics = comparisonData['metrics'] as Map<String, dynamic>?;
      
      final currentRevenue = (currentMetrics?['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final comparisonRevenue = (comparisonMetrics?['total_revenue'] as num?)?.toDouble() ?? 0.0;
      
      double percentageChange = 0.0;
      if (comparisonRevenue > 0) {
        percentageChange = ((currentRevenue - comparisonRevenue) / comparisonRevenue) * 100;
      } else if (currentRevenue > 0) {
        percentageChange = 100.0;
      }

      return {
        'success': true,
        'data': {
          'current_period': currentData,
          'comparison_period': comparisonData,
          'comparison_metrics': {
            'revenue_change': currentRevenue - comparisonRevenue,
            'revenue_percentage_change': percentageChange,
            'trend': percentageChange > 0 ? 'up' : percentageChange < 0 ? 'down' : 'stable',
          }
        },
        'message': 'Revenue comparison retrieved successfully',
      };
    } catch (e) {
      print('Error getting revenue comparison: $e');
      return {
        'success': false,
        'message': 'Failed to get revenue comparison: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }
}