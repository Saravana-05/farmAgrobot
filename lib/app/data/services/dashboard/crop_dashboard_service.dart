import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';

class CropDashboardService extends GetxService {
  /// Get comprehensive crop dashboard statistics
  /// Returns current week, current month, last month, current year data with quantities and units
  Future<Map<String, dynamic>> getCropDashboardStats({
    String? cropId,
    String? farmSegmentId,
  }) async {
    try {
      String url = cropDashboardUrl;
      
      // Add filters if provided
      List<String> queryParams = [];
      if (cropId != null && cropId.isNotEmpty) {
        queryParams.add('crop_id=$cropId');
      }
      if (farmSegmentId != null && farmSegmentId.isNotEmpty) {
        queryParams.add('farm_segment_id=$farmSegmentId');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      print('Attempting to fetch crop dashboard stats from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Crop dashboard stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Crop dashboard stats response: $jsonResponse');
        
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
          errorMessage = errorResponse['message'] ?? 'Failed to fetch crop dashboard stats';
        } catch (e) {
          errorMessage = 'Failed to fetch crop dashboard stats (Status: ${response.statusCode})';
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

  /// Get crop comparison dashboard showing quantity trends across time periods
  /// Allows comparing multiple crops side by side
  Future<Map<String, dynamic>> getCropComparisonDashboard({
    List<String>? compareCropIds,
    String? farmSegmentId,
  }) async {
    try {
      String url = cropComparisonDashboardUrl;
      
      // Add filters if provided
      List<String> queryParams = [];
      if (compareCropIds != null && compareCropIds.isNotEmpty) {
        queryParams.add('compare_crops=${compareCropIds.join(',')}');
      }
      if (farmSegmentId != null && farmSegmentId.isNotEmpty) {
        queryParams.add('farm_segment_id=$farmSegmentId');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      print('Attempting to fetch crop comparison dashboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Crop comparison dashboard response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Crop comparison dashboard response: $jsonResponse');
        
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
          errorMessage = errorResponse['message'] ?? 'Failed to fetch crop comparison dashboard';
        } catch (e) {
          errorMessage = 'Failed to fetch crop comparison dashboard (Status: ${response.statusCode})';
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

  /// Get detailed crop performance metrics including growth trends and efficiency
  /// Provides in-depth analysis for a specific crop over time
  Future<Map<String, dynamic>> getCropPerformanceMetrics({
    required String cropId,
    int monthsBack = 6,
  }) async {
    if (cropId.isEmpty) {
      return {
        'success': false,
        'message': 'Crop ID is required',
      };
    }

    try {
      String url = '$cropPerformanceMetricsUrl?crop_id=$cropId&months_back=$monthsBack';
      
      print('Attempting to fetch crop performance metrics from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      print('Crop performance metrics response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Crop performance metrics response: $jsonResponse');
        
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
          errorMessage = errorResponse['message'] ?? 'Failed to fetch crop performance metrics';
        } catch (e) {
          errorMessage = 'Failed to fetch crop performance metrics (Status: ${response.statusCode})';
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

  /// Get crop dashboard overview data for main dashboard screen
  /// This combines the most important crop stats in a single call
  Future<Map<String, dynamic>> getCropDashboardOverview({
    String? cropId,
    String? farmSegmentId,
  }) async {
    try {
      // Get dashboard stats which includes all time periods
      final dashboardResult = await getCropDashboardStats(
        cropId: cropId,
        farmSegmentId: farmSegmentId,
      );
      
      if (dashboardResult['success'] != true) {
        return dashboardResult;
      }

      final dashboardData = dashboardResult['data'] as Map<String, dynamic>?;
      if (dashboardData == null) {
        return {
          'success': false,
          'message': 'Crop dashboard data is null',
        };
      }
      
      // Extract the most important data for overview with null safety
      final overallStats = dashboardData['overall_stats'] as Map<String, dynamic>?;
      final periods = dashboardData['periods'] as Map<String, dynamic>?;
      
      return {
        'success': true,
        'data': {
          'overall_stats': overallStats,
          'current_week': periods?['current_week'],
          'current_month': periods?['current_month'],
          'last_month': periods?['last_month'],
          'current_year': periods?['current_year'],
        },
        'message': 'Crop dashboard overview retrieved successfully',
      };
    } catch (e) {
      print('Error getting crop dashboard overview: $e');
      return {
        'success': false,
        'message': 'Failed to get crop dashboard overview: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Convenience method to get current week crop data
  Future<Map<String, dynamic>> getCurrentWeekCropData({
    String? cropId,
    String? farmSegmentId,
  }) async {
    final result = await getCropDashboardStats(cropId: cropId, farmSegmentId: farmSegmentId);
    
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final periods = data?['periods'] as Map<String, dynamic>?;
      
      return {
        'success': true,
        'data': periods?['current_week'],
        'message': 'Current week crop data retrieved successfully',
      };
    }
    
    return result;
  }

  /// Convenience method to get current month crop data
  Future<Map<String, dynamic>> getCurrentMonthCropData({
    String? cropId,
    String? farmSegmentId,
  }) async {
    final result = await getCropDashboardStats(cropId: cropId, farmSegmentId: farmSegmentId);
    
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final periods = data?['periods'] as Map<String, dynamic>?;
      
      return {
        'success': true,
        'data': periods?['current_month'],
        'message': 'Current month crop data retrieved successfully',
      };
    }
    
    return result;
  }

  /// Convenience method to get last month crop data
  Future<Map<String, dynamic>> getLastMonthCropData({
    String? cropId,
    String? farmSegmentId,
  }) async {
    final result = await getCropDashboardStats(cropId: cropId, farmSegmentId: farmSegmentId);
    
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final periods = data?['periods'] as Map<String, dynamic>?;
      
      return {
        'success': true,
        'data': periods?['last_month'],
        'message': 'Last month crop data retrieved successfully',
      };
    }
    
    return result;
  }

  /// Convenience method to get current year crop data
  Future<Map<String, dynamic>> getCurrentYearCropData({
    String? cropId,
    String? farmSegmentId,
  }) async {
    final result = await getCropDashboardStats(cropId: cropId, farmSegmentId: farmSegmentId);
    
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final periods = data?['periods'] as Map<String, dynamic>?;
      
      return {
        'success': true,
        'data': periods?['current_year'],
        'message': 'Current year crop data retrieved successfully',
      };
    }
    
    return result;
  }

  /// Get combined crop and yield analytics for comprehensive dashboard
  Future<Map<String, dynamic>> getCombinedCropAnalytics({
    String? cropId,
    String? farmSegmentId,
    List<String>? compareCropIds,
  }) async {
    try {
      final futures = <Future<Map<String, dynamic>>>[];
      
      // Always include basic dashboard data
      futures.add(getCropDashboardStats(cropId: cropId, farmSegmentId: farmSegmentId));
      
      // Add comparison data if crop IDs provided
      if (compareCropIds != null && compareCropIds.isNotEmpty) {
        futures.add(getCropComparisonDashboard(
          compareCropIds: compareCropIds,
          farmSegmentId: farmSegmentId,
        ));
      }
      
      // Add performance metrics if specific crop selected
      if (cropId != null && cropId.isNotEmpty) {
        futures.add(getCropPerformanceMetrics(cropId: cropId));
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
          'dashboard_stats': results[0]['data'],
        },
        'message': 'Combined crop analytics retrieved successfully',
      };

      // Add comparison data if available
      if (results.length > 1 && compareCropIds != null && compareCropIds.isNotEmpty) {
        final responseData = response['data'] as Map<String, dynamic>;
        responseData['comparison_data'] = results[1]['data'];
      }
      
      // Add performance metrics if available
      if (results.length > 2 || (results.length > 1 && compareCropIds == null)) {
        final responseData = response['data'] as Map<String, dynamic>;
        final performanceIndex = (compareCropIds != null && compareCropIds.isNotEmpty) ? 2 : 1;
        if (performanceIndex < results.length) {
          responseData['performance_metrics'] = results[performanceIndex]['data'];
        }
      }

      return response;
    } catch (e) {
      print('Error getting combined crop analytics: $e');
      return {
        'success': false,
        'message': 'Failed to get combined crop analytics: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Static method to get all crop dashboard data at once (for initialization)
  static Future<Map<String, dynamic>> getAllCropDashboardData({
    String? cropId,
    String? farmSegmentId,
    List<String>? compareCropIds,
  }) async {
    final CropDashboardService service = CropDashboardService();
    
    try {
      final futures = <Future<Map<String, dynamic>>>[];
      
      // Always get basic dashboard stats
      futures.add(service.getCropDashboardStats(cropId: cropId, farmSegmentId: farmSegmentId));
      futures.add(service.getCropComparisonDashboard(
        compareCropIds: compareCropIds,
        farmSegmentId: farmSegmentId,
      ));
      
      // Add performance metrics if specific crop provided
      if (cropId != null && cropId.isNotEmpty) {
        futures.add(service.getCropPerformanceMetrics(cropId: cropId));
      }

      final results = await Future.wait(futures);

      // Check if any request failed with null safety
      for (var result in results) {
        if (result['success'] != true) {
          return result; // Return first error encountered
        }
      }

      final response = {
        'success': true,
        'data': {
          'dashboard_stats': results[0]['data'],
          'comparison_dashboard': results[1]['data'],
        },
        'message': 'All crop dashboard data retrieved successfully',
      };
      
      // Add performance metrics if available
      if (results.length > 2) {
        final responseData = response['data'] as Map<String, dynamic>;
        responseData['performance_metrics'] = results[2]['data'];
      }

      return response;
    } catch (e) {
      print('Error getting all crop dashboard data: $e');
      return {
        'success': false,
        'message': 'Failed to get crop dashboard data: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Get crop yield trends over time periods
  /// Useful for charts and trend analysis
  Future<Map<String, dynamic>> getCropYieldTrends({
    String? cropId,
    String? farmSegmentId,
    List<String>? compareCropIds,
  }) async {
    try {
      // Use comparison dashboard to get trends across periods
      final comparisonResult = await getCropComparisonDashboard(
        compareCropIds: compareCropIds ?? (cropId != null ? [cropId] : null),
        farmSegmentId: farmSegmentId,
      );
      
      if (comparisonResult['success'] != true) {
        return comparisonResult;
      }

      final comparisonData = comparisonResult['data'] as Map<String, dynamic>?;
      if (comparisonData == null) {
        return {
          'success': false,
          'message': 'Comparison data is null',
        };
      }
      
      // Extract trend data from comparison periods
      final comparisonPeriods = comparisonData['comparison_periods'] as Map<String, dynamic>?;
      final cropMetadata = comparisonData['crop_metadata'] as List<dynamic>?;
      
      // Transform data into trend format
      final Map<String, List<Map<String, dynamic>>> trendData = {};
      
      final periods = ['current_week', 'current_month', 'last_month', 'current_year'];
      
      for (final period in periods) {
        final periodData = comparisonPeriods?[period] as Map<String, dynamic>?;
        final crops = periodData?['crops'] as List<dynamic>?;
        
        if (crops != null) {
          for (final crop in crops) {
            final cropMap = crop as Map<String, dynamic>;
            final cropId = cropMap['crop_id'].toString();
            final cropName = cropMap['crop_name'] as String?;
            
            if (!trendData.containsKey(cropId)) {
              trendData[cropId] = [];
            }
            
            trendData[cropId]!.add({
              'period': period,
              'period_display': periodData?['period'] as String?,
              'crop_name': cropName,
              'total_quantity': cropMap['total_quantity'],
              'yield_count': cropMap['yield_count'],
              'variant_count': cropMap['variant_count'],
              'units': cropMap['units'],
            });
          }
        }
      }
      
      return {
        'success': true,
        'data': {
          'crop_metadata': cropMetadata,
          'trend_data': trendData,
          'periods_analyzed': periods,
        },
        'message': 'Crop yield trends retrieved successfully',
      };
    } catch (e) {
      print('Error getting crop yield trends: $e');
      return {
        'success': false,
        'message': 'Failed to get crop yield trends: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  /// Calculate crop productivity metrics and comparisons
  Future<Map<String, dynamic>> getCropProductivityMetrics({
    String? cropId,
    String? farmSegmentId,
  }) async {
    try {
      final dashboardResult = await getCropDashboardStats(
        cropId: cropId,
        farmSegmentId: farmSegmentId,
      );
      
      if (dashboardResult['success'] != true) {
        return dashboardResult;
      }

      final dashboardData = dashboardResult['data'] as Map<String, dynamic>?;
      if (dashboardData == null) {
        return {
          'success': false,
          'message': 'Dashboard data is null',
        };
      }
      
      final periods = dashboardData['periods'] as Map<String, dynamic>?;
      
      if (periods == null) {
        return {
          'success': false,
          'message': 'Periods data is null',
        };
      }

      // Calculate productivity metrics
      final currentMonth = periods['current_month'] as Map<String, dynamic>?;
      final lastMonth = periods['last_month'] as Map<String, dynamic>?;
      final currentYear = periods['current_year'] as Map<String, dynamic>?;
      
      final currentMonthYields = (currentMonth?['total_yield_records'] as num?)?.toInt() ?? 0;
      final lastMonthYields = (lastMonth?['total_yield_records'] as num?)?.toInt() ?? 0;
      final currentYearYields = (currentYear?['total_yield_records'] as num?)?.toInt() ?? 0;
      
      // Calculate month-over-month change
      double monthlyGrowth = 0.0;
      if (lastMonthYields > 0) {
        monthlyGrowth = ((currentMonthYields - lastMonthYields) / lastMonthYields) * 100;
      } else if (currentMonthYields > 0) {
        monthlyGrowth = 100.0;
      }
      
      return {
        'success': true,
        'data': {
          'current_month_yields': currentMonthYields,
          'last_month_yields': lastMonthYields,
          'current_year_yields': currentYearYields,
          'monthly_growth_percentage': monthlyGrowth,
          'monthly_growth_trend': monthlyGrowth > 0 ? 'up' : monthlyGrowth < 0 ? 'down' : 'stable',
          'productivity_periods': {
            'current_month': currentMonth,
            'last_month': lastMonth,
            'current_year': currentYear,
          }
        },
        'message': 'Crop productivity metrics calculated successfully',
      };
    } catch (e) {
      print('Error calculating crop productivity metrics: $e');
      return {
        'success': false,
        'message': 'Failed to calculate crop productivity metrics: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }
}