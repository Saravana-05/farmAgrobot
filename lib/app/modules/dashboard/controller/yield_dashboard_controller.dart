import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/dashboard/crop_dashboard_service.dart';

class CropYieldController extends GetxController {
  // Service instance
  final CropDashboardService _cropDashboardService = CropDashboardService();

  // Observable variables
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Selected period for crop display
  var selectedCropPeriod = 'current_week'.obs;

  // Crop and Yield data
  var cropYieldData = <Map<String, dynamic>>[].obs;
  var cropMetadata = <Map<String, dynamic>>[].obs;
  
  // Period-wise data storage
  var currentWeekData = <String, dynamic>{}.obs;
  var currentMonthData = <String, dynamic>{}.obs;
  var lastMonthData = <String, dynamic>{}.obs;
  var currentYearData = <String, dynamic>{}.obs;
  var overallStats = <String, dynamic>{}.obs;

  // Filters
  var selectedCropId = Rxn<String>();
  var selectedFarmSegmentId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadCropDashboardData();
  }

  /// Main method to load all crop dashboard data
  Future<void> loadCropDashboardData() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      print('Loading crop dashboard data...');
      
      final result = await _cropDashboardService.getCropDashboardStats(
        cropId: selectedCropId.value,
        farmSegmentId: selectedFarmSegmentId.value,
      );

      print('Crop dashboard result: ${result['success']}');

      if (result['success'] == true) {
        final data = result['data'];
        print('Crop dashboard data received: ${data?.toString()}');

        if (data != null) {
          _processCropDashboardData(data);
        } else {
          hasError.value = true;
          errorMessage.value = 'No crop data available';
        }
      } else {
        hasError.value = true;
        errorMessage.value = result['message'] ?? 'Failed to load crop data';
        print('Crop dashboard error: ${result['message']}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load crop data: ${e.toString()}';
      print('Error loading crop dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Process crop dashboard data from API response
  void _processCropDashboardData(Map<String, dynamic> data) {
    try {
      print('Processing crop dashboard data...');
      
      // Extract overall stats
      if (data['overall_stats'] != null) {
        final stats = data['overall_stats'];
        if (stats is Map) {
          overallStats.value = Map<String, dynamic>.from(stats);
        }
        print('Overall stats: ${overallStats.value}');
      }

      // Extract periods data
      final periods = data['periods'];
      
      if (periods != null && periods is Map) {
        print('Periods keys: ${periods.keys.toList()}');
        
        // Process each period
        if (periods['current_week'] != null) {
          final week = periods['current_week'];
          if (week is Map) {
            currentWeekData.value = Map<String, dynamic>.from(week);
            print('✅ Current week data loaded');
          }
        }
        
        if (periods['current_month'] != null) {
          final month = periods['current_month'];
          if (month is Map) {
            currentMonthData.value = Map<String, dynamic>.from(month);
            print('✅ Current month data loaded');
          }
        }
        
        if (periods['last_month'] != null) {
          final lastMonth = periods['last_month'];
          if (lastMonth is Map) {
            lastMonthData.value = Map<String, dynamic>.from(lastMonth);
            print('✅ Last month data loaded');
          }
        }
        
        if (periods['current_year'] != null) {
          final year = periods['current_year'];
          if (year is Map) {
            currentYearData.value = Map<String, dynamic>.from(year);
            print('✅ Current year data loaded');
          }
        }
      }

      // Extract crop metadata if available
      if (data['crop_metadata'] != null) {
        final metadata = data['crop_metadata'];
        if (metadata is List) {
          cropMetadata.value = metadata.map((e) {
            if (e is Map) {
              return Map<String, dynamic>.from(e);
            }
            return <String, dynamic>{};
          }).toList();
          print('Crop metadata: ${cropMetadata.length} crops');
        }
      }

      // Build crop yield data structure for display
      _buildCropYieldDisplayData();
      
      print('Crop dashboard data processed successfully');
    } catch (e) {
      print('Error processing crop dashboard data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Build crop yield data for display from period data
  void _buildCropYieldDisplayData() {
    try {
      final currentPeriodData = _getCurrentPeriodData();
      
      if (currentPeriodData.isEmpty) {
        cropYieldData.value = [];
        return;
      }

      // Extract crops from current period
      final crops = currentPeriodData['crops'];
      
      if (crops == null || (crops is! List) || crops.isEmpty) {
        print('No crops found in current period');
        cropYieldData.value = [];
        return;
      }

      // Build display data for each crop
      List<Map<String, dynamic>> displayData = [];
      
      for (var crop in crops) {
        if (crop is! Map) continue;
        print('🔍 total_quantity value: ${crop['total_quantity']}');
        print('🔍 total_quantity type: ${crop['total_quantity'].runtimeType}');
        final cropMap = Map<String, dynamic>.from(crop);
        
        // Get crop metadata for image
        final cropId = cropMap['crop_id']?.toString();
        final metadata = _getCropMetadata(cropId);
        
        displayData.add({
          'crop_id': cropId,
          'crop_name': cropMap['crop_name'] ?? 'Unknown Crop',
          'crop_image': metadata?['image_url'] ?? metadata?['crop_image'],
          'total_quantity': _convertToDouble(cropMap['total_quantity']),
          'yield_count': cropMap['yield_count'] ?? 0,
          'variant_count': cropMap['variant_count'] ?? 0,
          'units': cropMap['units'] ?? {},
          'yields': _buildYieldsForAllPeriods(cropId),
        });
      }
      
      cropYieldData.value = displayData;
      print('Built crop yield display data: ${displayData.length} crops');
      
    } catch (e) {
      print('Error building crop yield display data: $e');
    }
  }

  /// Get crop metadata by crop ID
  Map<String, dynamic>? _getCropMetadata(String? cropId) {
    if (cropId == null || cropMetadata.isEmpty) return null;
    
    try {
      return cropMetadata.firstWhere(
        (meta) => meta['crop_id']?.toString() == cropId,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Build yields data for all periods for a specific crop
  Map<String, dynamic> _buildYieldsForAllPeriods(String? cropId) {
    if (cropId == null) return {};
    
    return {
      'current_week': _getCropQuantityForPeriod(cropId, currentWeekData.value),
      'current_month': _getCropQuantityForPeriod(cropId, currentMonthData.value),
      'last_month': _getCropQuantityForPeriod(cropId, lastMonthData.value),
      'current_year': _getCropQuantityForPeriod(cropId, currentYearData.value),
    };
  }

  /// Get crop quantity for a specific period
  double _getCropQuantityForPeriod(String cropId, Map<String, dynamic> periodData) {
    try {
      final crops = periodData['crops'];
      
      if (crops == null || crops is! List) return 0.0;
      
      final crop = crops.firstWhere(
        (c) {
          if (c is! Map) return false;
          return c['crop_id']?.toString() == cropId;
        },
        orElse: () => null,
      );
      
      if (crop == null || crop is! Map) return 0.0;
      
      return _convertToDouble(crop['total_quantity']);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get current period data based on selected period
  Map<String, dynamic> _getCurrentPeriodData() {
    switch (selectedCropPeriod.value) {
      case 'current_week':
        return currentWeekData.value;
      case 'current_month':
        return currentMonthData.value;
      case 'last_month':
        return lastMonthData.value;
      case 'current_year':
        return currentYearData.value;
      default:
        return currentWeekData.value;
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
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Change crop period
  void changeCropPeriod(String? period) {
    if (period != null && period != selectedCropPeriod.value) {
      selectedCropPeriod.value = period;
      _buildCropYieldDisplayData();
    }
  }

  /// Get current yield for a crop in selected period
  double getCurrentYieldForPeriod(Map<String, dynamic> yields, String period) {
    final value = yields[period];
    return _convertToDouble(value);
  }

  /// Get crop period label for display
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
      default:
        return 'This Week';
    }
  }

  /// Get total yield for current period across all crops
  double getTotalYieldForPeriod() {
    double total = 0.0;
    for (var crop in cropYieldData) {
      final yields = crop['yields'];
      if (yields != null && yields is Map) {
        final value = yields[selectedCropPeriod.value];
        total += _convertToDouble(value);
      }
    }
    return total;
  }

  /// Get total crop count for current period
  int getTotalCropCount() {
    return cropYieldData.length;
  }

  /// Get total yield records for current period
  int getTotalYieldRecords() {
    final currentData = _getCurrentPeriodData();
    final records = currentData['total_yield_records'];
    if (records == null) return 0;
    if (records is int) return records;
    if (records is num) return records.toInt();
    return 0;
  }

  /// Get crops with images for display
  List<Map<String, dynamic>> getCropsWithImages() {
    return cropYieldData.where((crop) {
      final image = crop['crop_image'];
      return image != null && image.toString().isNotEmpty;
    }).toList();
  }

  /// Get top performing crops by quantity
  List<Map<String, dynamic>> getTopPerformingCrops({int limit = 5}) {
    final sortedCrops = List<Map<String, dynamic>>.from(cropYieldData);
    
    sortedCrops.sort((a, b) {
      final aYields = a['yields'];
      final bYields = b['yields'];
      
      double aQuantity = 0.0;
      double bQuantity = 0.0;
      
      if (aYields != null && aYields is Map) {
        aQuantity = _convertToDouble(aYields[selectedCropPeriod.value]);
      }
      
      if (bYields != null && bYields is Map) {
        bQuantity = _convertToDouble(bYields[selectedCropPeriod.value]);
      }
      
      return bQuantity.compareTo(aQuantity);
    });
    
    return sortedCrops.take(limit).toList();
  }

  /// Apply filters and reload data
  Future<void> applyFilters({
    String? cropId,
    String? farmSegmentId,
  }) async {
    selectedCropId.value = cropId;
    selectedFarmSegmentId.value = farmSegmentId;
    await loadCropDashboardData();
  }

  /// Clear filters and reload
  Future<void> clearFilters() async {
    selectedCropId.value = null;
    selectedFarmSegmentId.value = null;
    await loadCropDashboardData();
  }

  /// Refresh crop dashboard
  Future<void> refreshCropDashboard() async {
    await loadCropDashboardData();
  }

  /// Format quantity with unit
  String formatQuantityWithUnit(double quantity, Map<String, dynamic>? units) {
    if (units == null || units.isEmpty) {
      return '${quantity.toStringAsFixed(1)} kg';
    }

    // Get the primary unit (first unit with highest quantity)
    final entries = units.entries.toList();
    if (entries.isEmpty) {
      return '${quantity.toStringAsFixed(1)} kg';
    }

    // Find unit with highest quantity
    var primaryEntry = entries[0];
    for (var entry in entries) {
      if (_convertToDouble(entry.value) > _convertToDouble(primaryEntry.value)) {
        primaryEntry = entry;
      }
    }

    final unitName = primaryEntry.key;
    final unitQuantity = _convertToDouble(primaryEntry.value);

    return '${unitQuantity.toStringAsFixed(1)} $unitName';
  }

  /// Get summary statistics
  Map<String, dynamic> getCropSummary() {
    final currentData = _getCurrentPeriodData();
    final records = currentData['total_yield_records'];
    int totalRecords = 0;
    
    if (records != null) {
      if (records is int) {
        totalRecords = records;
      } else if (records is num) {
        totalRecords = records.toInt();
      }
    }
    
    return {
      'total_crops': cropYieldData.length,
      'total_yield_records': totalRecords,
      'total_quantity': getTotalYieldForPeriod(),
      'period': getCropPeriodLabel(),
      'period_key': selectedCropPeriod.value,
      'has_data': cropYieldData.isNotEmpty,
    };
  }

  

  /// Get crop comparison data
  Future<Map<String, dynamic>> getCropComparison(List<String> cropIds) async {
    try {
      final result = await _cropDashboardService.getCropComparisonDashboard(
        compareCropIds: cropIds,
        farmSegmentId: selectedFarmSegmentId.value,
      );

      return result;
    } catch (e) {
      print('Error getting crop comparison: $e');
      return {
        'success': false,
        'message': 'Failed to get crop comparison: ${e.toString()}',
      };
    }
  }

  /// Get productivity metrics
  Future<Map<String, dynamic>> getProductivityMetrics() async {
    try {
      final result = await _cropDashboardService.getCropProductivityMetrics(
        cropId: selectedCropId.value,
        farmSegmentId: selectedFarmSegmentId.value,
      );

      return result;
    } catch (e) {
      print('Error getting productivity metrics: $e');
      return {
        'success': false,
        'message': 'Failed to get productivity metrics: ${e.toString()}',
      };
    }
  }

  /// Check if crop has yield in current period
  bool cropHasYieldInPeriod(Map<String, dynamic> crop) {
    final yields = crop['yields'];
    if (yields == null || yields is! Map) return false;
    
    final value = yields[selectedCropPeriod.value];
    final quantity = _convertToDouble(value);
    return quantity > 0.0;
  }

  /// Get crop display color (can be customized based on crop type)
  Color getCropDisplayColor(String cropName) {
    // Simple color mapping based on crop name hash
    final hash = cropName.hashCode.abs();
    final colors = [
      Color(0xFF4CAF50), // Green
      Color(0xFF2196F3), // Blue
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFFE91E63), // Pink
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF795548), // Brown
    ];
    
    return colors[hash % colors.length];
  }
}