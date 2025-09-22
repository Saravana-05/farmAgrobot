import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/yield/yield_model.dart';

class YieldService {
  /// Save yield data with variants, farm segments, and optional file uploads
  static Future<Map<String, dynamic>> saveYield({
    required Map<String, dynamic> yieldData,
    List<File>? billImages,
  }) async {
    try {
      final uri = Uri.parse(addYield);
      http.Response response;

      // Check if we have files to upload
      if (billImages != null && billImages.isNotEmpty) {
        // Validate images first
        final imageErrors = validateImageFiles(billImages);
        if (imageErrors != null) {
          return {
            'success': false,
            'statusCode': 400,
            'data': {
              'status': 'error',
              'message': 'Image validation failed',
              'errors': imageErrors,
            }
          };
        }

        // Create multipart request for file uploads
        var request = http.MultipartRequest('POST', uri);

        // Add form fields from yieldData
        yieldData.forEach((key, value) {
          if (value != null) {
            if (key == 'farm_segments' && value is List) {
              // Convert list to JSON string for multipart
              request.fields[key] = json.encode(value);
            } else if (key == 'variants' && value is List) {
              // Convert variants list to JSON string for multipart
              request.fields[key] = json.encode(value);
            } else {
              // Convert all other values to string
              request.fields[key] = value.toString();
            }
          }
        });

        // ✅ FIXED: Add bill image files with UNIQUE field names
        for (int i = 0; i < billImages.length; i++) {
          final file = billImages[i];
          if (await file.exists()) {
            try {
              final multipartFile = await http.MultipartFile.fromPath(
                'bill_image_$i', // ✅ UNIQUE FIELD NAME for each image
                file.path,
                filename:
                    'yield_bill_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              );
              request.files.add(multipartFile);
              print(
                  'Added file ${i + 1}/${billImages.length}: ${file.path} with field name: bill_image_$i');
            } catch (e) {
              print('Error adding file ${file.path}: $e');
              continue;
            }
          }
        }

        print('Sending multipart request with ${request.files.length} files');
        print('Request fields: ${request.fields}');
        print(
            'File field names: ${request.files.map((f) => f.field).toList()}');

        // Send multipart request with timeout
        final streamedResponse = await request.send().timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            throw TimeoutException(
                'File upload timed out', const Duration(minutes: 5));
          },
        );

        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Send JSON request without files
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(yieldData),
        );
      }

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(response.body);
      } catch (e) {
        print('Error parsing response JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'status': 'error',
            'message': 'Invalid response format from server'
          },
        };
      }

      return {
        'success':
            response.statusCode == 201 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in saveYield: $e');
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
      print('Timeout error in saveYield: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in saveYield: $e');
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

  /// Get list of all yields with optional filters
  static Future<Map<String, dynamic>> getAllYields({
    String? cropId,
    String? farmSegmentId,
    String? startDate,
    String? endDate,
    bool? hasBills,
    int? pageSize,
    int? page,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (cropId != null && cropId.isNotEmpty) {
        queryParams['crop_id'] = cropId;
      }
      if (farmSegmentId != null && farmSegmentId.isNotEmpty) {
        queryParams['farm_segment_id'] = farmSegmentId;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (hasBills != null) {
        queryParams['has_bills'] = hasBills.toString();
      }
      if (pageSize != null) {
        queryParams['page_size'] = pageSize.toString();
      }
      if (page != null) {
        queryParams['page'] = page.toString();
      }

      final uri = Uri.parse(viewYields).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getAllYields: $e');
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
      print('Timeout error in getAllYields: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getAllYields: $e');
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

  /// Get yield details by ID
  static Future<Map<String, dynamic>> getYieldById(String yieldId) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      final uri = Uri.parse('$getYieldByIdUrl/$yieldId/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getYieldById: $e');
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
      print('Timeout error in getYieldById: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getYieldById: $e');
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

  /// ✅ NEW: Update yield data WITH support for multiple image uploads
  static Future<Map<String, dynamic>> updateYieldWithImages({
    required String yieldId,
    required Map<String, dynamic> yieldData,
    List<File>? billImages,
    String imageUpdateMode = 'add', // 'add', 'replace', 'keep'
  }) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      // Validate image update mode
      const validModes = ['add', 'replace', 'keep'];
      if (!validModes.contains(imageUpdateMode.toLowerCase())) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message':
                'Invalid image update mode. Must be: ${validModes.join(", ")}'
          }
        };
      }

      final uri = Uri.parse('$updateYieldUrl/$yieldId/');
      http.Response response;

      // Check if we need to handle file uploads
      bool hasFiles = billImages != null &&
          billImages.isNotEmpty &&
          imageUpdateMode != 'keep';

      if (hasFiles) {
        // Validate images first
        final imageErrors = validateImageFiles(billImages!);
        if (imageErrors != null) {
          return {
            'success': false,
            'statusCode': 400,
            'data': {
              'status': 'error',
              'message': 'Image validation failed',
              'errors': imageErrors,
            }
          };
        }

        print('=== UPDATE WITH FILES DEBUG ===');
        print('Update mode: $imageUpdateMode');
        print('Files to upload: ${billImages!.length}');

        // Create multipart request for file uploads
        var request = http.MultipartRequest('PUT', uri);

        // Add image update mode to form data
        request.fields['image_update_mode'] = imageUpdateMode.toLowerCase();

        // Add form fields from yieldData
        yieldData.forEach((key, value) {
          if (value != null) {
            if (key == 'farm_segments' && value is List) {
              request.fields[key] = json.encode(value);
            } else if (key == 'variants' && value is List) {
              request.fields[key] = json.encode(value);
            } else {
              request.fields[key] = value.toString();
            }
          }
        });

        // Add bill image files with UNIQUE field names
        for (int i = 0; i < billImages!.length; i++) {
          final file = billImages![i];
          if (await file.exists()) {
            try {
              final multipartFile = await http.MultipartFile.fromPath(
                'bill_image_$i', // ✅ UNIQUE FIELD NAME for each image
                file.path,
                filename:
                    'yield_update_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              );
              request.files.add(multipartFile);
              print(
                  'Added update file ${i + 1}/${billImages!.length}: ${file.path} with field name: bill_image_$i');
            } catch (e) {
              print('Error adding update file ${file.path}: $e');
              continue;
            }
          }
        }

        print('Sending multipart UPDATE with ${request.files.length} files');
        print('Request fields: ${request.fields}');
        print(
            'File field names: ${request.files.map((f) => f.field).toList()}');

        // Send multipart request with timeout
        final streamedResponse = await request.send().timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            throw TimeoutException(
                'Update with files timed out', const Duration(minutes: 5));
          },
        );

        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Send JSON request without files (original behavior)
        response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(yieldData),
        );
      }

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      // Parse response
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(response.body);
      } catch (e) {
        print('Error parsing update response JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'status': 'error',
            'message': 'Invalid response format from server'
          },
        };
      }

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in updateYieldWithImages: $e');
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
      print('Timeout error in updateYieldWithImages: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in updateYieldWithImages: $e');
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

  /// Update yield data
  static Future<Map<String, dynamic>> updateYield({
    required String yieldId,
    required Map<String, dynamic> yieldData,
  }) async {
    // Call the new method without images (keep mode)
    return updateYieldWithImages(
      yieldId: yieldId,
      yieldData: yieldData,
      imageUpdateMode: 'keep',
    );
  }

  /// Add bill images to an existing yield record
  static Future<Map<String, dynamic>> addBillImages({
    required String yieldId,
    required List<File> imageFiles,
  }) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      if (imageFiles.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'At least one image file is required'
          }
        };
      }

      // Validate images
      final imageErrors = validateImageFiles(imageFiles);
      if (imageErrors != null) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'Image validation failed',
            'errors': imageErrors,
          }
        };
      }

      final uri = Uri.parse('$addBillUrl/$yieldId/');

      var request = http.MultipartRequest('POST', uri);

      // Add image files
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        if (await file.exists()) {
          try {
            final multipartFile = await http.MultipartFile.fromPath(
              'bill_images',
              file.path,
              filename:
                  'yield_bill_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            );
            request.files.add(multipartFile);
          } catch (e) {
            print('Error adding file ${file.path}: $e');
            continue;
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in addBillImages: $e');
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
      print('Timeout error in addBillImages: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in addBillImages: $e');
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

  static Future<Map<String, dynamic>> updateYieldAndAddImages({
    required String yieldId,
    required Map<String, dynamic> yieldData,
    required List<File> billImages,
  }) async {
    return updateYieldWithImages(
      yieldId: yieldId,
      yieldData: yieldData,
      billImages: billImages,
      imageUpdateMode: 'add',
    );
  }

  /// Remove a specific bill image from a yield record
  static Future<Map<String, dynamic>> removeBillImage({
    required String yieldId,
    required String imageId,
  }) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      if (imageId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Image ID is required'}
        };
      }

      final uri = Uri.parse('$baseUrl/$yieldId/remove-bill-image/$imageId/');

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in removeBillImage: $e');
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
      print('Timeout error in removeBillImage: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in removeBillImage: $e');
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

  /// Replace all bill images for a yield with new ones
  static Future<Map<String, dynamic>> replaceBillImages({
    required String yieldId,
    required List<File> imageFiles,
  }) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      if (imageFiles.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'At least one image file is required'
          }
        };
      }

      // Validate images
      final imageErrors = validateImageFiles(imageFiles);
      if (imageErrors != null) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'Image validation failed',
            'errors': imageErrors,
          }
        };
      }

      final uri = Uri.parse('$baseUrl/$yieldId/replace-bill-images/');

      var request = http.MultipartRequest('POST', uri);

      // Add image files
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        if (await file.exists()) {
          try {
            final multipartFile = await http.MultipartFile.fromPath(
              'bill_images',
              file.path,
              filename:
                  'yield_bill_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            );
            request.files.add(multipartFile);
          } catch (e) {
            print('Error adding file ${file.path}: $e');
            continue;
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in replaceBillImages: $e');
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
      print('Timeout error in replaceBillImages: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in replaceBillImages: $e');
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

  static Future<Map<String, dynamic>> updateYieldAndReplaceImages({
    required String yieldId,
    required Map<String, dynamic> yieldData,
    required List<File> billImages,
  }) async {
    return updateYieldWithImages(
      yieldId: yieldId,
      yieldData: yieldData,
      billImages: billImages,
      imageUpdateMode: 'replace',
    );
  }

  /// Get all bill images for a specific yield
  static Future<Map<String, dynamic>> getBillImages(String yieldId) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      final uri = Uri.parse('$baseUrl/$yieldId/bill-images/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getBillImages: $e');
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
      print('Timeout error in getBillImages: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getBillImages: $e');
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

  /// Delete a yield record and all associated data
  static Future<Map<String, dynamic>> deleteYield(String yieldId) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      final uri = Uri.parse('$deleteYieldUrl$yieldId/');
      print('DELETE request URL: $uri');

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Request timeout', const Duration(seconds: 30));
        },
      );

      print('DELETE response status: ${response.statusCode}');
      print('DELETE response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        if (response.body.isEmpty) {
          // Handle empty body
          jsonResponse = {
            'status': response.statusCode == 200 ? 'success' : 'error',
            'message': response.statusCode == 200
                ? 'Yield deleted successfully'
                : 'Unexpected empty response'
          };
        } else {
          // Try parsing JSON
          jsonResponse = json.decode(response.body);
        }
      } catch (e) {
        print('Error parsing delete response: $e');
        // Fallback: wrap plain text into JSON
        jsonResponse = {
          'status': response.statusCode == 200 ? 'success' : 'error',
          'message': response.body.isNotEmpty
              ? response.body
              : 'Invalid response format from server'
        };
      }

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in deleteYield: $e');
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
      print('Timeout error in deleteYield: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in deleteYield: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Unexpected error: ${e.toString()}'
        },
      };
    }
  }

  /// Bulk delete multiple yields
  static Future<Map<String, dynamic>> bulkDeleteYields(
      List<String> yieldIds) async {
    try {
      if (yieldIds.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield IDs are required'}
        };
      }

      final uri = Uri.parse('$baseUrl/bulk-delete/');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'yield_ids': yieldIds}),
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in bulkDeleteYields: $e');
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
      print('Timeout error in bulkDeleteYields: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in bulkDeleteYields: $e');
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

  /// Get yield summary statistics
  static Future<Map<String, dynamic>> getYieldSummary({
    String? cropId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (cropId != null && cropId.isNotEmpty) {
        queryParams['crop_id'] = cropId;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse('$baseUrl/summary/').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getYieldSummary: $e');
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
      print('Timeout error in getYieldSummary: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getYieldSummary: $e');
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

  // Helper and utility methods

  /// Convert API response to Yield model
  static YieldModel yieldFromJson(Map<String, dynamic> json) {
    return YieldModel.fromJson(json);
  }

  /// Convert Yield model to API request format
  static Map<String, dynamic> yieldToJson(YieldModel yield) {
    return yield.toCreateJson();
  }

  /// Convert list of API responses to list of Yield models
  static List<YieldModel> yieldListFromJson(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] is List) {
      final List<dynamic> jsonList = response['data'];
      return jsonList.map((json) => yieldFromJson(json)).toList();
    }
    return [];
  }

  /// Convert API summary response to YieldSummary model
  static YieldSummary? summaryFromJson(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      return YieldSummary.fromJson(response['data']);
    }
    return null;
  }

  /// Validate yield data before sending to API
  static Map<String, String>? validateYieldData(
      Map<String, dynamic> yieldData) {
    Map<String, String> errors = {};

    // Validate crop ID
    if (yieldData['crop'] == null ||
        yieldData['crop'].toString().trim().isEmpty) {
      errors['crop'] = 'Crop is required';
    }

    // Validate harvest date
    if (yieldData['harvest_date'] == null) {
      errors['harvest_date'] = 'Harvest date is required';
    }

    // Validate farm segments
    if (yieldData['farm_segments'] == null ||
        (yieldData['farm_segments'] as List).isEmpty) {
      errors['farm_segments'] = 'At least one farm segment must be selected';
    }

    // Validate variants
    if (yieldData['variants'] == null ||
        (yieldData['variants'] as List).isEmpty) {
      errors['variants'] = 'At least one variant must be specified';
    } else {
      final variants = yieldData['variants'] as List;
      for (int i = 0; i < variants.length; i++) {
        final variant = variants[i];
        if (variant['crop_variant_id'] == null) {
          errors['variant_${i}_id'] = 'Variant ID is required';
        }
        if (variant['quantity'] == null || variant['quantity'] <= 0) {
          errors['variant_${i}_quantity'] = 'Valid quantity is required';
        }
        if (variant['unit'] == null ||
            variant['unit'].toString().trim().isEmpty) {
          errors['variant_${i}_unit'] = 'Unit is required';
        }
      }
    }

    return errors.isEmpty ? null : errors;
  }

  /// Validate image files before upload
  static Map<String, String>? validateImageFiles(List<File> files) {
    Map<String, String> errors = {};

    if (files.length > 10) {
      errors['bill_images'] = 'Maximum 10 images are allowed';
      return errors;
    }

    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    const maxFileSize = 5 * 1024 * 1024; // 5MB

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      // Check if file exists
      if (!file.existsSync()) {
        errors['file_$i'] = 'File does not exist';
        continue;
      }

      // Check file extension
      final fileName = file.path.toLowerCase();
      final hasValidExtension =
          allowedExtensions.any((ext) => fileName.endsWith(ext));

      if (!hasValidExtension) {
        errors['file_$i'] =
            'Invalid file type. Allowed: ${allowedExtensions.join(', ')}';
      }

      // Check file size
      try {
        final fileSize = file.lengthSync();
        if (fileSize > maxFileSize) {
          errors['file_$i'] = 'File size exceeds 5MB limit';
        }
      } catch (e) {
        errors['file_$i'] = 'Unable to read file size';
      }
    }

    return errors.isEmpty ? null : errors;
  }

  /// Format date for API requests
  static String formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T').first; // YYYY-MM-DD format
  }

  /// Parse date from API response
  static DateTime? parseDateFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString, Error: $e');
      return null;
    }
  }

  /// Validate image file
  static Future<bool> validateImageFile(File file) async {
    try {
      if (!await file.exists()) return false;

      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5MB

      if (fileSize > maxSize) {
        print('File size $fileSize exceeds maximum allowed size $maxSize');
        return false;
      }

      final extension = _getFileExtension(file.path);
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];

      if (!allowedExtensions.contains(extension)) {
        print('File extension $extension is not allowed');
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating image file: $e');
      return false;
    }
  }

  /// Get file extension from file path
  static String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot != -1 && lastDot < filePath.length - 1) {
      return filePath.substring(lastDot).toLowerCase();
    }
    return '';
  }

  /// Get MIME type from file extension
  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }
}
