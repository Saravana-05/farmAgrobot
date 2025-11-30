import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/crops/crop_model.dart';

class CropService {
  /// Save crop data with optional image upload
  static Future<Map<String, dynamic>> saveCrop({
    required Map<String, dynamic> cropData,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      final uri = Uri.parse(addCrop);

      if (imageFile != null) {
        // Use multipart request for file upload
        var request = http.MultipartRequest('POST', uri);

        // Add crop data fields
        cropData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add image file if provided
        if (imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'crop_image', // Field name should match Django model field
            imageFile.path,
          ));
        }

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        return {
          'success': response.statusCode == 201,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      } else {
        // Regular JSON request without file
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(cropData),
        );

        final jsonResponse = json.decode(response.body);
        
        return {
          'success': response.statusCode == 201,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } on SocketException catch (e) {
      print('Network error in saveCrop: $e');
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
      print('Timeout error in saveCrop: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in saveCrop: $e');
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

  /// Get list of all crops
  static Future<Map<String, dynamic>> getAllCrops({
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

      final uri = Uri.parse(viewCrop).replace(
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

  /// Get crop details by ID
  static Future<Map<String, dynamic>> getCropById(String cropId) async {
    try {
      if (cropId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop ID is required'}
        };
      }

      final uri = Uri.parse(editCropUrl.replaceFirst('{id}', cropId));

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      print('getCropById API Response: $responseData'); // Debug log

      // Handle Django's nested response structure
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'], // Extract the actual crop data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException catch (e) {
      print('Network error in getCropById: $e');
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
      print('Timeout error in getCropById: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getCropById: $e');
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

  /// Update crop data with optional image upload
  static Future<Map<String, dynamic>> updateCrop({
    required String cropId,
    required Map<String, dynamic> cropData,
    File? imageFile,
    Uint8List? imageBytes,
    bool removeImage = false,
  }) async {
    try {
      if (cropId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop ID is required'}
        };
      }

      final uri = Uri.parse(updateCropUrl.replaceFirst('{id}', cropId));

      if (imageFile != null || removeImage) {
        // Use multipart request for file operations
        var request = http.MultipartRequest('PUT', uri);

        // Add crop data fields
        cropData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add image file if provided
        if (imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'crop_image', // Field name should match Django model field
            imageFile.path,
          ));
        }

        // Add remove image flag if needed
        if (removeImage) {
          request.fields['remove_image'] = 'true';
        }

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        // Handle Django's nested response structure
        if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': jsonResponse['data'], // Extract the actual crop data
          };
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': jsonResponse,
          };
        }
      } else {
        // Regular JSON request without file operations
        final response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(cropData),
        );

        final jsonResponse = json.decode(response.body);
        
        // Handle Django's nested response structure
        if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
          return {
            'success': true,
            'statusCode': response.statusCode,
            'data': jsonResponse['data'], // Extract the actual crop data
          };
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': jsonResponse,
          };
        }
      }
    } on SocketException catch (e) {
      print('Network error in updateCrop: $e');
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
      print('Timeout error in updateCrop: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in updateCrop: $e');
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

  /// Delete crop
  static Future<Map<String, dynamic>> deleteCrop({
    required String cropId,
  }) async {
    try {
      if (cropId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Crop ID is required'}
        };
      }

      final url = deleteCropUrl.replaceFirst('{id}', cropId);
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
      print('Network error in deleteCrop: $e');
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
      print('Timeout error in deleteCrop: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in deleteCrop: $e');
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

  /// Convert API response to Crop model
  static Crop cropFromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id']?.toString() ?? '',
      cropName: json['crop_name'] ?? '',
      cropImage: json['crop_image'],
      imageUrl: json['crop_image_url'] ??
          json['image_url'] ?? 
          json['crop_image'], // Handle multiple possible field names
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert Crop model to API request format
  static Map<String, dynamic> cropToJson(Crop crop) {
    final Map<String, dynamic> data = {
      'crop_name': crop.cropName,
    };

    // Only include non-null values
    return data..removeWhere((key, value) => value == null);
  }

  /// Convert list of API responses to list of Crop models
  /// This method handles Django's nested response structure
  static List<Crop> cropListFromJson(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] is List) {
      final List<dynamic> jsonList = response['data'];
      return jsonList.map((json) => cropFromJson(json)).toList();
    }
    return [];
  }

  /// Helper method to validate crop data before sending
  static Map<String, String>? validateCropData(Map<String, dynamic> cropData) {
    Map<String, String> errors = {};

    // Validate crop name
    if (cropData['crop_name'] == null ||
        (cropData['crop_name'] as String).trim().isEmpty) {
      errors['crop_name'] = 'Crop name is required';
    }

    // Validate crop name length
    if (cropData['crop_name'] != null &&
        (cropData['crop_name'] as String).length > 255) {
      errors['crop_name'] = 'Crop name must be less than 255 characters';
    }

    return errors.isEmpty ? null : errors;
  }

  /// Helper method to check if image file is valid
  static bool isValidImageFile(File? imageFile) {
    if (imageFile == null) return true; // null is valid (optional)

    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final filePath = imageFile.path.toLowerCase();

    return allowedExtensions.any((ext) => filePath.endsWith(ext));
  }

  /// Helper method to get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Helper method to validate image file size (max 10MB)
  static bool isValidImageSize(File? imageFile, {double maxSizeMB = 10.0}) {
    if (imageFile == null) return true;
    return getFileSizeInMB(imageFile) <= maxSizeMB;
  }
}