import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';

class YieldAnalyticsService {
  static Future<Map<String, dynamic>> getCropDashboard({
    String? cropId,
    String? farmSegmentId,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (cropId != null && cropId.isNotEmpty) {
        queryParams['crop_id'] = cropId;
      }
      if (farmSegmentId != null && farmSegmentId.isNotEmpty) {
        queryParams['farm_segment_id'] = farmSegmentId;
      }

      final uri = Uri.parse(yieldDashboardUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getCropDashboard: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message':
              'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      print('Timeout error in getCropDashboard: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getCropDashboard: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network error: ${e.toString()}'
        },
      };
    }
  }

  /// Get crop comparison dashboard
  ///
  /// Query parameters:
  /// - compare_crops: Comma-separated list of crop IDs to compare
  /// - farm_segment_id: Filter by farm segment
  static Future<Map<String, dynamic>> getCropComparisonDashboard({
    List<String>? compareCrops,
    String? farmSegmentId,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (compareCrops != null && compareCrops.isNotEmpty) {
        queryParams['compare_crops'] = compareCrops.join(',');
      }
      if (farmSegmentId != null && farmSegmentId.isNotEmpty) {
        queryParams['farm_segment_id'] = farmSegmentId;
      }

      final uri = Uri.parse(cropComparisonDashboardUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getCropComparisonDashboard: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message':
              'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      print('Timeout error in getCropComparisonDashboard: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getCropComparisonDashboard: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network error: ${e.toString()}'
        },
      };
    }
  }

  /// Get crop performance metrics
  ///
  /// Query parameters:
  /// - crop_id: Required - Specific crop to analyze
  /// - months_back: Number of months to analyze (default: 6)
  static Future<Map<String, dynamic>> getCropPerformanceMetrics({
    required String cropId,
    int monthsBack = 6,
  }) async {
    try {
      if (cropId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop ID is required'}
        };
      }

      final Map<String, String> queryParams = {
        'crop_id': cropId,
        'months_back': monthsBack.toString(),
      };

      final uri = Uri.parse(cropComparisonDashboardUrl).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getCropPerformanceMetrics: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message':
              'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      print('Timeout error in getCropPerformanceMetrics: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getCropPerformanceMetrics: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network error: ${e.toString()}'
        },
      };
    }
  }

  /// Parse dashboard response data
  static DashboardData? parseDashboardData(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      return DashboardData.fromJson(response['data']);
    }
    return null;
  }

  /// Parse comparison dashboard response data
  static ComparisonDashboardData? parseComparisonData(
      Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      return ComparisonDashboardData.fromJson(response['data']);
    }
    return null;
  }

  /// Parse performance metrics response data
  static PerformanceMetrics? parsePerformanceMetrics(
      Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      return PerformanceMetrics.fromJson(response['data']);
    }
    return null;
  }
}

// ===== Data Models for Analytics =====

class DashboardData {
  final Map<String, dynamic> overallStats;
  final Map<String, PeriodData> periods;
  final List<CropMetadata> cropMetadata;

  DashboardData({
    required this.overallStats,
    required this.periods,
    required this.cropMetadata,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final periodsJson = json['periods'] as Map<String, dynamic>? ?? {};
    final periods = periodsJson.map(
      (key, value) => MapEntry(key, PeriodData.fromJson(value)),
    );

    final metadataJson = json['crop_metadata'] as List? ?? [];
    final metadata =
        metadataJson.map((item) => CropMetadata.fromJson(item)).toList();

    return DashboardData(
      overallStats: json['overall_stats'] ?? {},
      periods: periods,
      cropMetadata: metadata,
    );
  }
}

class PeriodData {
  final String period;
  final int totalYieldRecords;
  final List<CropData> crops;

  PeriodData({
    required this.period,
    required this.totalYieldRecords,
    required this.crops,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    final cropsJson = json['crops'] as List? ?? [];
    final crops = cropsJson.map((item) => CropData.fromJson(item)).toList();

    return PeriodData(
      period: json['period'] ?? '',
      totalYieldRecords: json['total_yield_records'] ?? 0,
      crops: crops,
    );
  }
}

class CropData {
  final String cropId;
  final String cropName;
  final List<VariantData> variants;
  final int totalYieldRecords;
  final List<String> uniqueUnits;
  final List<UnitTotal> unitWiseTotals;
  final double totalQuantity;
  final int variantCount;

  CropData({
    required this.cropId,
    required this.cropName,
    required this.variants,
    required this.totalYieldRecords,
    required this.uniqueUnits,
    required this.unitWiseTotals,
    required this.totalQuantity,
    required this.variantCount,
  });

  factory CropData.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List? ?? [];
    final variants =
        variantsJson.map((item) => VariantData.fromJson(item)).toList();

    final unitsJson = json['unique_units'] as List? ?? [];
    final uniqueUnits = unitsJson.map((item) => item.toString()).toList();

    final unitTotalsJson = json['unit_wise_totals'] as List? ?? [];
    final unitTotals =
        unitTotalsJson.map((item) => UnitTotal.fromJson(item)).toList();

    return CropData(
      cropId: json['crop_id']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      variants: variants,
      totalYieldRecords: json['total_yield_records'] ?? 0,
      uniqueUnits: uniqueUnits,
      unitWiseTotals: unitTotals,
      totalQuantity: (json['total_quantity'] ?? 0).toDouble(),
      variantCount: json['variant_count'] ?? 0,
    );
  }
}

class VariantData {
  final String variantName;
  final String unit;
  final double totalQuantity;
  final int yieldCount;

  VariantData({
    required this.variantName,
    required this.unit,
    required this.totalQuantity,
    required this.yieldCount,
  });

  factory VariantData.fromJson(Map<String, dynamic> json) {
    return VariantData(
      variantName: json['variant_name'] ?? '',
      unit: json['unit'] ?? '',
      totalQuantity: (json['total_quantity'] ?? 0).toDouble(),
      yieldCount: json['yield_count'] ?? 0,
    );
  }
}

class UnitTotal {
  final String unit;
  final double totalQuantity;

  UnitTotal({
    required this.unit,
    required this.totalQuantity,
  });

  factory UnitTotal.fromJson(Map<String, dynamic> json) {
    return UnitTotal(
      unit: json['unit'] ?? '',
      totalQuantity: (json['total_quantity'] ?? 0).toDouble(),
    );
  }
}

class CropMetadata {
  final String cropId;
  final String cropName;
  final String? imageUrl;

  CropMetadata({
    required this.cropId,
    required this.cropName,
    this.imageUrl,
  });

  factory CropMetadata.fromJson(Map<String, dynamic> json) {
    return CropMetadata(
      cropId: json['crop_id']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      imageUrl: json['image_url'] ?? json['crop_image'],
    );
  }
}

class ComparisonDashboardData {
  final List<CropMetadata> cropMetadata;
  final Map<String, PeriodData> comparisonPeriods;
  final Map<String, dynamic> filtersApplied;

  ComparisonDashboardData({
    required this.cropMetadata,
    required this.comparisonPeriods,
    required this.filtersApplied,
  });

  factory ComparisonDashboardData.fromJson(Map<String, dynamic> json) {
    final metadataJson = json['crop_metadata'] as List? ?? [];
    final metadata =
        metadataJson.map((item) => CropMetadata.fromJson(item)).toList();

    final periodsJson =
        json['comparison_periods'] as Map<String, dynamic>? ?? {};
    final periods = periodsJson.map(
      (key, value) => MapEntry(key, PeriodData.fromJson(value)),
    );

    return ComparisonDashboardData(
      cropMetadata: metadata,
      comparisonPeriods: periods,
      filtersApplied: json['filters_applied'] ?? {},
    );
  }
}

class PerformanceMetrics {
  final CropInfo cropInfo;
  final Map<String, dynamic> overallStats;
  final List<MonthlyPerformance> monthlyPerformance;
  final List<VariantPerformance> variantPerformance;
  final List<VariantPerformance> topPerformingVariants;
  final GrowthTrend growthTrend;
  final Map<String, dynamic> analysisPeriod;

  PerformanceMetrics({
    required this.cropInfo,
    required this.overallStats,
    required this.monthlyPerformance,
    required this.variantPerformance,
    required this.topPerformingVariants,
    required this.growthTrend,
    required this.analysisPeriod,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    final monthlyJson = json['monthly_performance'] as List? ?? [];
    final monthly =
        monthlyJson.map((item) => MonthlyPerformance.fromJson(item)).toList();

    final variantJson = json['variant_performance'] as List? ?? [];
    final variants =
        variantJson.map((item) => VariantPerformance.fromJson(item)).toList();

    final topJson = json['top_performing_variants'] as List? ?? [];
    final top =
        topJson.map((item) => VariantPerformance.fromJson(item)).toList();

    return PerformanceMetrics(
      cropInfo: CropInfo.fromJson(json['crop_info'] ?? {}),
      overallStats: json['overall_stats'] ?? {},
      monthlyPerformance: monthly,
      variantPerformance: variants,
      topPerformingVariants: top,
      growthTrend: GrowthTrend.fromJson(json['growth_trend'] ?? {}),
      analysisPeriod: json['analysis_period'] ?? {},
    );
  }
}

class CropInfo {
  final String id;
  final String name;

  CropInfo({required this.id, required this.name});

  factory CropInfo.fromJson(Map<String, dynamic> json) {
    return CropInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class MonthlyPerformance {
  final String month;
  final int yieldCount;
  final int totalVariants;

  MonthlyPerformance({
    required this.month,
    required this.yieldCount,
    required this.totalVariants,
  });

  factory MonthlyPerformance.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformance(
      month: json['month'] ?? '',
      yieldCount: json['yield_count'] ?? 0,
      totalVariants: json['total_variants'] ?? 0,
    );
  }
}

class VariantPerformance {
  final String variantName;
  final String unit;
  final double totalQuantity;
  final double avgQuantity;
  final double minQuantity;
  final double maxQuantity;
  final int yieldCount;

  VariantPerformance({
    required this.variantName,
    required this.unit,
    required this.totalQuantity,
    required this.avgQuantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.yieldCount,
  });

  factory VariantPerformance.fromJson(Map<String, dynamic> json) {
    return VariantPerformance(
      variantName: json['crop_variant__crop_variant'] ?? '',
      unit: json['unit'] ?? '',
      totalQuantity: (json['total_quantity'] ?? 0).toDouble(),
      avgQuantity: (json['avg_quantity'] ?? 0).toDouble(),
      minQuantity: (json['min_quantity'] ?? 0).toDouble(),
      maxQuantity: (json['max_quantity'] ?? 0).toDouble(),
      yieldCount: json['yield_count'] ?? 0,
    );
  }
}

class GrowthTrend {
  final int recentMonth;
  final int previousMonth;
  final double growthPercentage;

  GrowthTrend({
    required this.recentMonth,
    required this.previousMonth,
    required this.growthPercentage,
  });

  factory GrowthTrend.fromJson(Map<String, dynamic> json) {
    return GrowthTrend(
      recentMonth: json['recent_month'] ?? 0,
      previousMonth: json['previous_month'] ?? 0,
      growthPercentage: (json['growth_percentage'] ?? 0).toDouble(),
    );
  }
}
