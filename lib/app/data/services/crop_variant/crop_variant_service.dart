import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/crop_variant/crop_variant_model.dart';

class CropVariantService {
  static Future<Map<String, dynamic>> getAllCrops() async {
    try {
      // Assuming you have a crops endpoint in your api.dart
      // If not, you'll need to add: const String viewCrops = '$baseUrl/crops/';
      final uri =
          Uri.parse(viewCrop); // Make sure this is defined in your api.dart

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);
      print('getAllCrops API Response: $jsonResponse'); // Debug log

      // Handle Django's nested response structure
      if (response.statusCode == 200) {
        // Handle different response structures
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse['status'] == 'success') {
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': jsonResponse['data'], // Extract the actual crops data
          };
        } else if (jsonResponse is List) {
          // Direct list response
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': jsonResponse,
          };
        } else if (jsonResponse is Map<String, dynamic>) {
          // Other map structures
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': jsonResponse,
          };
        }
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getAllCrops: $e');
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
      print('Timeout error in getAllCrops: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getAllCrops: $e');
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

  /// Save crop variant data
  static Future<Map<String, dynamic>> saveCropVariant({
    required Map<String, dynamic> cropVariantData,
  }) async {
    try {
      final uri = Uri.parse(addCropVariant);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cropVariantData),
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in saveCropVariant: $e');
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
      print('Timeout error in saveCropVariant: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in saveCropVariant: $e');
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

  /// Get list of all crop variants
  static Future<Map<String, dynamic>> getAllCropVariants({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      // Add pagination if needed
      if (page > 1) queryParams['page'] = page.toString();
      if (limit != 10) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(viewCropVariants).replace(
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
      print('Network error in getAllCropVariants: $e');
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
      print('Timeout error in getAllCropVariants: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getAllCropVariants: $e');
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

  /// Get crop variant details by ID
  static Future<Map<String, dynamic>> getCropVariantById(
      String variantId) async {
    try {
      if (variantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop variant ID is required'}
        };
      }

      final uri = Uri.parse(editCropVariantUrl.replaceFirst('{id}', variantId));

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      print('getCropVariantById API Response: $responseData'); // Debug log

      // Handle Django's nested response structure
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'], // Extract the actual crop variant data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException catch (e) {
      print('Network error in getCropVariantById: $e');
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
      print('Timeout error in getCropVariantById: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getCropVariantById: $e');
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

  /// Get all variants for a specific crop
  static Future<Map<String, dynamic>> getCropVariantsByCrop(
      String cropId) async {
    try {
      if (cropId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop ID is required'}
        };
      }

      final uri =
          Uri.parse(cropVariantsByCropUrl.replaceFirst('{crop_id}', cropId));

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      print('getCropVariantsByCrop API Response: $responseData'); // Debug log

      // Handle Django's nested response structure
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'], // Extract the actual crop variants data
          'count': responseData['count'],
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException catch (e) {
      print('Network error in getCropVariantsByCrop: $e');
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
      print('Timeout error in getCropVariantsByCrop: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getCropVariantsByCrop: $e');
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

  /// Update crop variant data
  static Future<Map<String, dynamic>> updateCropVariant({
    required String variantId,
    required Map<String, dynamic> cropVariantData,
  }) async {
    try {
      if (variantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop variant ID is required'}
        };
      }

      final uri =
          Uri.parse(updateCropVariantUrl.replaceFirst('{id}', variantId));

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cropVariantData),
      );

      final jsonResponse = json.decode(response.body);

      // Handle Django's nested response structure
      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': jsonResponse['data'], // Extract the actual crop variant data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } on SocketException catch (e) {
      print('Network error in updateCropVariant: $e');
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
      print('Timeout error in updateCropVariant: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in updateCropVariant: $e');
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

  /// Delete crop variant
  static Future<Map<String, dynamic>> deleteCropVariant({
    required String variantId,
  }) async {
    try {
      if (variantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop variant ID is required'}
        };
      }

      final url = deleteCropVariantUrl.replaceFirst('{id}', variantId);
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
      print('Network error in deleteCropVariant: $e');
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
      print('Timeout error in deleteCropVariant: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in deleteCropVariant: $e');
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

  /// Convert API response to CropVariant model
  static CropVariant cropVariantFromJson(Map<String, dynamic> json) {
    return CropVariant(
      id: json['id']?.toString() ?? '',
      cropId: json['crop']?.toString() ?? json['crop_id']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      cropVariant: json['crop_variant'] ?? '',
      unit: json['unit'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert CropVariant model to API request format
  static Map<String, dynamic> cropVariantToJson(CropVariant cropVariant) {
    final Map<String, dynamic> data = {
      'crop': cropVariant.cropId,
      'crop_variant': cropVariant.cropVariant,
      'unit': cropVariant.unit,
    };

    // Only include non-null values
    return data..removeWhere((key, value) => value == null || value == '');
  }

  /// Convert list of API responses to list of CropVariant models
  /// This method handles Django's nested response structure
  static List<CropVariant> cropVariantListFromJson(
      Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] is List) {
      final List<dynamic> jsonList = response['data'];
      return jsonList.map((json) => cropVariantFromJson(json)).toList();
    }
    return [];
  }

  /// Helper method to validate crop variant data before sending
  static Map<String, String>? validateCropVariantData(
      Map<String, dynamic> cropVariantData) {
    Map<String, String> errors = {};

    // Validate crop ID
    if (cropVariantData['crop'] == null ||
        (cropVariantData['crop'] as String).trim().isEmpty) {
      errors['crop'] = 'Crop is required';
    }

    // Validate crop variant name
    if (cropVariantData['crop_variant'] == null ||
        (cropVariantData['crop_variant'] as String).trim().isEmpty) {
      errors['crop_variant'] = 'Crop variant name is required';
    }

    // Validate crop variant name length
    if (cropVariantData['crop_variant'] != null &&
        (cropVariantData['crop_variant'] as String).length > 100) {
      errors['crop_variant'] =
          'Crop variant name must be less than 100 characters';
    }

    // Validate unit
    if (cropVariantData['unit'] == null ||
        (cropVariantData['unit'] as String).trim().isEmpty) {
      errors['unit'] = 'Unit is required';
    }

    // Validate unit choice
    const List<String> validUnits = ['Pieces', 'Bunch', 'Pack'];
    if (cropVariantData['unit'] != null &&
        !validUnits.contains(cropVariantData['unit'])) {
      errors['unit'] = 'Invalid unit. Must be one of: ${validUnits.join(', ')}';
    }

    return errors.isEmpty ? null : errors;
  }

  /// Helper method to get available unit choices
  static List<String> getAvailableUnits() {
    return ['Pieces', 'Bunch', 'Pack'];
  }

  /// Helper method to get unit display name
  static String getUnitDisplayName(String unit) {
    switch (unit) {
      case 'Pieces':
        return 'Pieces';
      case 'Bunch':
        return 'Bunch';
      case 'Pack':
        return 'Pack';
      default:
        return unit;
    }
  }
}
