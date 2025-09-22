import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/farm_segments/farm_seg_models.dart';

class FarmSegmentService {
  /// Save farm segment data
  static Future<Map<String, dynamic>> saveFarmSegment({
    required Map<String, dynamic> farmSegmentData,
  }) async {
    try {
      final uri = Uri.parse(addFarmSegment);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(farmSegmentData),
      );

      final jsonResponse = json.decode(response.body);
      
      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in saveFarmSegment: $e');
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
      print('Timeout error in saveFarmSegment: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in saveFarmSegment: $e');
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

  /// Get list of all farm segments
  static Future<Map<String, dynamic>> getAllFarmSegments({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      // Add pagination if needed (you can extend your Django view to support this)
      if (page > 1) queryParams['page'] = page.toString();
      if (limit != 10) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(viewFarmSegment).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getAllFarmSegments: $e');
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
      print('Timeout error in getAllFarmSegments: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getAllFarmSegments: $e');
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

  /// Get farm segment details by ID
  static Future<Map<String, dynamic>> getFarmSegmentById(String farmSegmentId) async {
    try {
      if (farmSegmentId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Farm Segment ID is required'}
        };
      }

      final uri = Uri.parse(editFarmSegmentUrl.replaceFirst('{id}', farmSegmentId));

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      print('getFarmSegmentById API Response: $responseData'); // Debug log

      // Handle Django's nested response structure
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'], // Extract the actual farm segment data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException catch (e) {
      print('Network error in getFarmSegmentById: $e');
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
      print('Timeout error in getFarmSegmentById: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getFarmSegmentById: $e');
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

  /// Update farm segment data
  static Future<Map<String, dynamic>> updateFarmSegment({
    required String farmSegmentId,
    required Map<String, dynamic> farmSegmentData,
  }) async {
    try {
      if (farmSegmentId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Farm Segment ID is required'}
        };
      }

      final uri = Uri.parse(updateFarmSegmentUrl.replaceFirst('{id}', farmSegmentId));

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(farmSegmentData),
      );

      final jsonResponse = json.decode(response.body);
      
      // Handle Django's nested response structure
      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': jsonResponse['data'], // Extract the actual farm segment data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } on SocketException catch (e) {
      print('Network error in updateFarmSegment: $e');
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
      print('Timeout error in updateFarmSegment: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in updateFarmSegment: $e');
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

  /// Delete farm segment
  static Future<Map<String, dynamic>> deleteFarmSegment({
    required String farmSegmentId,
  }) async {
    try {
      if (farmSegmentId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Farm Segment ID is required'}
        };
      }

      final url = deleteFarmSegmentUrl.replaceFirst('{id}', farmSegmentId);
      final uri = Uri.parse(url);

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in deleteFarmSegment: $e');
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
      print('Timeout error in deleteFarmSegment: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in deleteFarmSegment: $e');
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

  /// Convert API response to FarmSegment model
  static FarmSegment farmSegmentFromJson(Map<String, dynamic> json) {
    return FarmSegment(
      id: json['id']?.toString() ?? '',
      farmName: json['farm_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert FarmSegment model to API request format
  static Map<String, dynamic> farmSegmentToJson(FarmSegment farmSegment) {
    final Map<String, dynamic> data = {
      'farm_name': farmSegment.farmName,
    };

    // Only include non-null values
    return data..removeWhere((key, value) => value == null);
  }

  /// Convert list of API responses to list of FarmSegment models
  /// This method handles Django's nested response structure
  static List<FarmSegment> farmSegmentListFromJson(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] is List) {
      final List<dynamic> jsonList = response['data'];
      return jsonList.map((json) => farmSegmentFromJson(json)).toList();
    }
    return [];
  }

  /// Helper method to validate farm segment data before sending
  static Map<String, String>? validateFarmSegmentData(Map<String, dynamic> farmSegmentData) {
    Map<String, String> errors = {};

    // Validate farm name
    if (farmSegmentData['farm_name'] == null ||
        (farmSegmentData['farm_name'] as String).trim().isEmpty) {
      errors['farm_name'] = 'Farm name is required';
    }

    // Validate farm name length
    if (farmSegmentData['farm_name'] != null &&
        (farmSegmentData['farm_name'] as String).length > 255) {
      errors['farm_name'] = 'Farm name must be less than 255 characters';
    }

    return errors.isEmpty ? null : errors;
  }
}