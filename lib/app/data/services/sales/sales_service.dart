import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';

class SalesService {
  /// Save sale data with variants and images
  static Future<Map<String, dynamic>> saveSale({
    required Map<String, dynamic> saleData,
    List<File>? saleImages,
  }) async {
    try {
      final uri = Uri.parse(saveSaleUrl);
      http.Response response;

      // Validate sale data
      final validationErrors = _validateSaleData(saleData);
      if (validationErrors != null) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'Validation failed',
            'errors': validationErrors,
          }
        };
      }

      // Check if we have images to upload
      if (saleImages != null && saleImages.isNotEmpty) {
        // Validate images
        final imageErrors = _validateImageFiles(saleImages);
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

        // FIXED: Use multipart request for multiple images
        var request = http.MultipartRequest('POST', uri);

        // FIXED: Store variants separately before processing other fields
        final variants = saleData['variants'];

        // Add all non-array fields as regular form fields
        saleData.forEach((key, value) {
          if (value != null && key != 'variants') {
            request.fields[key] = value.toString();
          }
        });

        // FIXED: Send variants as JSON list for Django serializer
        if (variants != null && variants is List && variants.isNotEmpty) {
          print('Original variants data: $variants');
          final variantsJson = json.encode(variants);
          request.fields['variants'] = variantsJson;
          print('Encoded variants JSON: $variantsJson');
        } else {
          print('WARNING: Variants data is null or empty! Variants: $variants');
        }

        // FIXED: Add multiple image files with the same field name
        print('Adding ${saleImages.length} images to multipart request...');

        // Create image metadata for each image
        List<Map<String, dynamic>> imageMetadata = [];

        for (int i = 0; i < saleImages.length; i++) {
          final file = saleImages[i];
          if (await file.exists()) {
            try {
              // FIXED: Use the same field name 'images' for all files
              // This allows Django to receive them as request.FILES.getlist('images')
              final multipartFile = await http.MultipartFile.fromPath(
                'images', // Same field name for all images
                file.path,
                filename:
                    'sale_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              );
              request.files.add(multipartFile);

              // Create metadata for this image
              imageMetadata.add({
                'name': 'Sale Image ${i + 1}',
                'description': '',
                'is_primary': i == 0, // First image is primary
              });

              print(
                  'Added sale image ${i + 1}/${saleImages.length}: ${file.path}');
            } catch (e) {
              print('Error adding file ${file.path}: $e');
              continue;
            }
          }
        }

        // FIXED: Add image metadata as JSON string
        if (imageMetadata.isNotEmpty) {
          request.fields['image_metadata'] = json.encode(imageMetadata);
          print('Added image metadata: ${request.fields['image_metadata']}');
        }

        print('Sending multipart request with ${request.files.length} files');
        print('All request fields: ${request.fields.keys.toList()}');

        final streamedResponse = await request.send().timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            throw TimeoutException(
                'Sale creation timed out', const Duration(minutes: 5));
          },
        );

        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Send as JSON when no images
        print('Sending JSON request (no images)');

        final jsonData = Map<String, dynamic>.from(saleData);
        print('Sale data being sent: ${json.encode(jsonData)}');

        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(jsonData),
        );
      }

      print('Save sale response status: ${response.statusCode}');
      print('Save sale response body: ${response.body}');

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 201 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'saveSale');
    }
  }

  /// Get all sales with filtering options
  static Future<Map<String, dynamic>> getAllSales({
    String? merchantId,
    String? yieldId,
    String? paymentMode,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? minAmount,
    String? maxAmount,
    String? sortBy,
    int? page,
    int? pageSize,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (merchantId?.isNotEmpty == true)
        queryParams['merchant_id'] = merchantId!;
      if (yieldId?.isNotEmpty == true) queryParams['yield_id'] = yieldId!;
      if (paymentMode?.isNotEmpty == true)
        queryParams['payment_mode'] = paymentMode!;
      if (status?.isNotEmpty == true) queryParams['status'] = status!;
      if (paymentStatus?.isNotEmpty == true)
        queryParams['payment_status'] = paymentStatus!;
      if (startDate?.isNotEmpty == true) queryParams['start_date'] = startDate!;
      if (endDate?.isNotEmpty == true) queryParams['end_date'] = endDate!;
      if (minAmount?.isNotEmpty == true) queryParams['min_amount'] = minAmount!;
      if (maxAmount?.isNotEmpty == true) queryParams['max_amount'] = maxAmount!;
      if (sortBy?.isNotEmpty == true) queryParams['sort_by'] = sortBy!;
      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();

      final uri = Uri.parse(getAllSalesUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getAllSales');
    }
  }

  /// Get sale by ID
  static Future<Map<String, dynamic>> getSaleById(String saleId) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      final uri = Uri.parse('$getSaleByIdUrl$saleId/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getSaleById');
    }
  }

  /// Update sale data
  static Future<Map<String, dynamic>> updateSale({
    required String saleId,
    required Map<String, dynamic> saleData,
    List<File>? saleImages,
  }) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      final uri = Uri.parse('$updateSaleUrl$saleId/update/');
      http.Response response;

      // Check if we have images to upload
      if (saleImages != null && saleImages.isNotEmpty) {
        // Validate images
        final imageErrors = _validateImageFiles(saleImages);
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
        var request = http.MultipartRequest('PUT', uri);

        // Store variants separately
        final variants = saleData['variants'];

        // Add form fields from saleData
        saleData.forEach((key, value) {
          if (value != null && key != 'variants') {
            request.fields[key] = value.toString();
          }
        });

        // Add variants as JSON
        if (variants != null && variants is List && variants.isNotEmpty) {
          request.fields['variants'] = json.encode(variants);
        }

        // FIXED: Add multiple image files with same field name
        List<Map<String, dynamic>> imageMetadata = [];

        for (int i = 0; i < saleImages.length; i++) {
          final file = saleImages[i];
          if (await file.exists()) {
            try {
              final multipartFile = await http.MultipartFile.fromPath(
                'images', // Same field name for all images
                file.path,
                filename:
                    'sale_update_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              );
              request.files.add(multipartFile);

              // Create metadata
              imageMetadata.add({
                'name': 'Updated Image ${i + 1}',
                'description': '',
                'is_primary': i == 0,
              });
            } catch (e) {
              print('Error adding file ${file.path}: $e');
              continue;
            }
          }
        }

        // Add image metadata
        if (imageMetadata.isNotEmpty) {
          request.fields['image_metadata'] = json.encode(imageMetadata);
        }

        print('Updating sale with ${request.files.length} new images...');

        final streamedResponse = await request.send().timeout(
              const Duration(minutes: 5),
            );

        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Send JSON request without files
        response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(saleData),
        );
      }

      print('Update sale response: ${response.statusCode} - ${response.body}');
      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'updateSale');
    }
  }

  /// Delete sale
  static Future<Map<String, dynamic>> deleteSale(String saleId) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      final uri = Uri.parse('$deleteSaleUrl$saleId/');

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'deleteSale');
    }
  }

  /// Update sale status
  static Future<Map<String, dynamic>> updateSaleStatus({
    required String saleId,
    required String status,
  }) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      if (status.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Status is required'}
        };
      }

      final uri = Uri.parse('$updateSaleStatusUrl$saleId/status/');

      final response = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'updateSaleStatus');
    }
  }

  // PAYMENT MANAGEMENT METHODS

  /// Add payment to sale
  static Future<Map<String, dynamic>> addPayment({
    required String saleId,
    required double paymentAmount,
    required String paymentMethod,
    String? paymentReference,
    String? notes,
    String? createdBy,
  }) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      if (paymentAmount <= 0) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'Payment amount must be greater than 0'
          }
        };
      }

      final uri = Uri.parse('$addPaymentUrl$saleId/payment/add/');

      final requestData = {
        'payment_amount': paymentAmount,
        'payment_method': paymentMethod,
        if (paymentReference?.isNotEmpty == true)
          'payment_reference': paymentReference,
        if (notes?.isNotEmpty == true) 'notes': notes,
        if (createdBy?.isNotEmpty == true) 'created_by': createdBy,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'addPayment');
    }
  }

  /// Get payment history for sale
  static Future<Map<String, dynamic>> getPaymentHistory(String saleId) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      final uri = Uri.parse('$paymentHistoryUrl$saleId/payment/history/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getPaymentHistory');
    }
  }

  // IMAGE MANAGEMENT METHODS

  /// Add images to existing sale
  static Future<Map<String, dynamic>> addSaleImages({
    required String saleId,
    required List<File> images,
    List<String>? imageNames,
    List<String>? imageDescriptions,
    List<bool>? isPrimaryFlags,
  }) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      if (images.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {
            'status': 'error',
            'message': 'At least one image is required'
          }
        };
      }

      // Validate images
      final imageErrors = _validateImageFiles(images);
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

      final uri = Uri.parse('$addSaleImagesUrl$saleId/images/add/');
      var request = http.MultipartRequest('POST', uri);

      print('Adding ${images.length} images to existing sale...');

      // FIXED: Add all images with the same field name 'images'
      List<Map<String, dynamic>> imageMetadata = [];

      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        if (await file.exists()) {
          try {
            // Use the same field name 'images' for all files
            final multipartFile = await http.MultipartFile.fromPath(
              'images', // Same field name for all images
              file.path,
              filename:
                  'sale_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            );
            request.files.add(multipartFile);

            // Create metadata for this image
            imageMetadata.add({
              'name': (imageNames != null &&
                      i < imageNames.length &&
                      imageNames[i].isNotEmpty)
                  ? imageNames[i]
                  : 'Image ${i + 1}',
              'description':
                  (imageDescriptions != null && i < imageDescriptions.length)
                      ? imageDescriptions[i]
                      : '',
              'is_primary':
                  (isPrimaryFlags != null && i < isPrimaryFlags.length)
                      ? isPrimaryFlags[i]
                      : (i == 0),
            });

            print('Added image ${i + 1}: ${file.path}');
          } catch (e) {
            print('Error adding file ${file.path}: $e');
            continue;
          }
        }
      }

      // Add image metadata as JSON string
      if (imageMetadata.isNotEmpty) {
        request.fields['image_metadata'] = json.encode(imageMetadata);
        print('Added image metadata: ${request.fields['image_metadata']}');
      }

      print('Sending request with ${request.files.length} image files...');

      final streamedResponse = await request.send().timeout(
            const Duration(minutes: 3),
          );

      final response = await http.Response.fromStream(streamedResponse);
      print('Add images response: ${response.statusCode} - ${response.body}');

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 201 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'addSaleImages');
    }
  }

  /// Update sale image
  static Future<Map<String, dynamic>> updateSaleImage({
    required String saleId,
    required String imageId,
    File? newImage,
    String? imageName,
    String? description,
    bool? isPrimary,
  }) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      if (imageId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Image ID is required'}
        };
      }

      final uri =
          Uri.parse('$updateSaleImageUrl$saleId/images/$imageId/update/');

      if (newImage != null) {
        // Update with new image file
        var request = http.MultipartRequest('PUT', uri);

        if (await newImage.exists()) {
          final multipartFile = await http.MultipartFile.fromPath(
            'image',
            newImage.path,
            filename: 'sale_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          request.files.add(multipartFile);
        }

        // Add metadata
        if (imageName?.isNotEmpty == true)
          request.fields['image_name'] = imageName!;
        if (description?.isNotEmpty == true)
          request.fields['description'] = description!;
        if (isPrimary != null)
          request.fields['is_primary'] = isPrimary.toString();

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final jsonResponse = _parseResponse(response);

        return {
          'success':
              response.statusCode == 200 && jsonResponse['status'] == 'success',
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      } else {
        // Update only metadata
        final requestData = <String, dynamic>{};
        if (imageName?.isNotEmpty == true)
          requestData['image_name'] = imageName;
        if (description?.isNotEmpty == true)
          requestData['description'] = description;
        if (isPrimary != null) requestData['is_primary'] = isPrimary;

        final response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        final jsonResponse = _parseResponse(response);

        return {
          'success':
              response.statusCode == 200 && jsonResponse['status'] == 'success',
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } catch (e) {
      return _handleError(e, 'updateSaleImage');
    }
  }

  /// Delete sale image
  static Future<Map<String, dynamic>> deleteSaleImage({
    required String saleId,
    required String imageId,
  }) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      if (imageId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Image ID is required'}
        };
      }

      final uri =
          Uri.parse('$deleteSaleImageUrl$saleId/images/$imageId/delete/');

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'deleteSaleImage');
    }
  }

  /// Get sale images
  static Future<Map<String, dynamic>> getSaleImages(String saleId) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      final uri = Uri.parse('$saleImagesUrl$saleId/images/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getSaleImages');
    }
  }

  // UTILITY METHODS

  /// Get sales by merchant
  static Future<Map<String, dynamic>> getSalesByMerchant(
      String merchantId) async {
    try {
      if (merchantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Merchant ID is required'}
        };
      }

      final uri = Uri.parse('$salesByMerchantUrl$merchantId/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getSalesByMerchant');
    }
  }

  /// Get available yields for sale
  static Future<Map<String, dynamic>> getAvailableYields() async {
    try {
      final uri = Uri.parse(availableYieldsUrl);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout: Server took too long to respond');
        },
      );

      final jsonResponse = _parseResponse(response);

      // Check if the API returned success status
      final bool isSuccess =
          response.statusCode == 200 && jsonResponse['status'] == 'success';

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'message': jsonResponse['message'] ?? '',
        'data': isSuccess ? jsonResponse['data'] : null,
        'count': isSuccess ? jsonResponse['count'] : 0,
        'error': isSuccess ? null : jsonResponse['message'],
      };
    } catch (e) {
      return _handleError(e, 'getAvailableYields');
    }
  }

  /// Get yield variants for a specific yield record
  static Future<Map<String, dynamic>> getYieldVariants(String yieldId) async {
    try {
      if (yieldId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Yield ID is required'}
        };
      }

      // Replace the placeholder in the URL with the actual yield ID
      final url = yieldVariantsByYieldUrl.replaceAll('{yield_id}', yieldId);
      final uri = Uri.parse(url);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Get yield variants response status: ${response.statusCode}');
      print('Get yield variants response body: ${response.body}');

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getYieldVariants');
    }
  }

  /// Get payment modes from backend
  static Future<Map<String, dynamic>> getPaymentModes() async {
    try {
      final uri = Uri.parse(getPaymentModesUrl);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getPaymentModes');
    }
  }

  /// Alias for existing getAvailableYields method
  static Future<Map<String, dynamic>> getAvailableYieldsExcludingSold() async {
    return getAvailableYields(); // Use the existing method from your backend
  }

  /// Get sales summary
  static Future<Map<String, dynamic>> getSalesSummary({
    String? merchantId,
    String? startDate,
    String? endDate,
    String? status,
    String? paymentStatus,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (merchantId?.isNotEmpty == true)
        queryParams['merchant_id'] = merchantId!;
      if (startDate?.isNotEmpty == true) queryParams['start_date'] = startDate!;
      if (endDate?.isNotEmpty == true) queryParams['end_date'] = endDate!;
      if (status?.isNotEmpty == true) queryParams['status'] = status!;
      if (paymentStatus?.isNotEmpty == true)
        queryParams['payment_status'] = paymentStatus!;

      final uri = Uri.parse(salesSummaryUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getSalesSummary');
    }
  }

  /// Get sales analytics
  static Future<Map<String, dynamic>> getSalesAnalytics({
    int? days,
    String? merchantId,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (days != null) queryParams['days'] = days.toString();
      if (merchantId?.isNotEmpty == true)
        queryParams['merchant_id'] = merchantId!;

      final uri = Uri.parse(salesAnalyticsUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getSalesAnalytics');
    }
  }

  /// Advanced sales search
  static Future<Map<String, dynamic>> advancedSalesSearch({
    String? merchantId,
    String? merchantName,
    String? yieldId,
    String? cropName,
    String? paymentMode,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? dateRange,
    String? minAmount,
    String? maxAmount,
    String? sortBy,
    int? page,
    int? pageSize,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (merchantId?.isNotEmpty == true)
        queryParams['merchant_id'] = merchantId!;
      if (merchantName?.isNotEmpty == true)
        queryParams['merchant_name'] = merchantName!;
      if (yieldId?.isNotEmpty == true) queryParams['yield_id'] = yieldId!;
      if (cropName?.isNotEmpty == true) queryParams['crop_name'] = cropName!;
      if (paymentMode?.isNotEmpty == true)
        queryParams['payment_mode'] = paymentMode!;
      if (status?.isNotEmpty == true) queryParams['status'] = status!;
      if (paymentStatus?.isNotEmpty == true)
        queryParams['payment_status'] = paymentStatus!;
      if (startDate?.isNotEmpty == true) queryParams['start_date'] = startDate!;
      if (endDate?.isNotEmpty == true) queryParams['end_date'] = endDate!;
      if (dateRange?.isNotEmpty == true) queryParams['date_range'] = dateRange!;
      if (minAmount?.isNotEmpty == true) queryParams['min_amount'] = minAmount!;
      if (maxAmount?.isNotEmpty == true) queryParams['max_amount'] = maxAmount!;
      if (sortBy?.isNotEmpty == true) queryParams['sort_by'] = sortBy!;
      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();

      final uri = Uri.parse(advancedSearchUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'advancedSalesSearch');
    }
  }

  /// Get search suggestions
  static Future<Map<String, dynamic>> getSearchSuggestions({
    required String type, // 'merchant', 'crop', 'yield'
    String? query,
  }) async {
    try {
      if (type.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Search type is required'}
        };
      }

      final Map<String, String> queryParams = {'type': type};
      if (query?.isNotEmpty == true) queryParams['query'] = query!;

      final uri = Uri.parse(searchSuggestionsUrl).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonResponse = _parseResponse(response);

      return {
        'success':
            response.statusCode == 200 && jsonResponse['status'] == 'success',
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } catch (e) {
      return _handleError(e, 'getSearchSuggestions');
    }
  }

  // REPORT GENERATION METHODS

  /// Generate Excel report
  static Future<Map<String, dynamic>> generateExcelReport({
    String? merchantId,
    String? merchantName,
    String? yieldId,
    String? cropName,
    String? paymentMode,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? dateRange,
    String? minAmount,
    String? maxAmount,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (merchantId?.isNotEmpty == true)
        queryParams['merchant_id'] = merchantId!;
      if (merchantName?.isNotEmpty == true)
        queryParams['merchant_name'] = merchantName!;
      if (yieldId?.isNotEmpty == true) queryParams['yield_id'] = yieldId!;
      if (cropName?.isNotEmpty == true) queryParams['crop_name'] = cropName!;
      if (paymentMode?.isNotEmpty == true)
        queryParams['payment_mode'] = paymentMode!;
      if (status?.isNotEmpty == true) queryParams['status'] = status!;
      if (paymentStatus?.isNotEmpty == true)
        queryParams['payment_status'] = paymentStatus!;
      if (startDate?.isNotEmpty == true) queryParams['start_date'] = startDate!;
      if (endDate?.isNotEmpty == true) queryParams['end_date'] = endDate!;
      if (dateRange?.isNotEmpty == true) queryParams['date_range'] = dateRange!;
      if (minAmount?.isNotEmpty == true) queryParams['min_amount'] = minAmount!;
      if (maxAmount?.isNotEmpty == true) queryParams['max_amount'] = maxAmount!;

      final uri = Uri.parse(excelReportUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(minutes: 5));

      // Excel reports return file data, so handle differently
      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': {
            'status': 'success',
            'message': 'Excel report generated successfully',
            'file_data': response.bodyBytes,
            'content_type': response.headers['content-type'],
            'filename':
                _extractFilename(response.headers['content-disposition']),
          },
        };
      } else {
        final jsonResponse = _parseResponse(response);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } catch (e) {
      return _handleError(e, 'generateExcelReport');
    }
  }

  /// Generate PDF bill for specific sale
  static Future<Map<String, dynamic>> generatePdfBill(String saleId) async {
    try {
      if (saleId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Sale ID is required'}
        };
      }

      final uri = Uri.parse('$pdfBillUrl$saleId/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(minutes: 3));

      // PDF reports return file data
      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': {
            'status': 'success',
            'message': 'PDF bill generated successfully',
            'file_data': response.bodyBytes,
            'content_type': response.headers['content-type'],
            'filename':
                _extractFilename(response.headers['content-disposition']),
          },
        };
      } else {
        final jsonResponse = _parseResponse(response);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } catch (e) {
      return _handleError(e, 'generatePdfBill');
    }
  }

  /// Generate bulk PDF report
  static Future<Map<String, dynamic>> generateBulkPdfReport({
    String? merchantId,
    String? merchantName,
    String? yieldId,
    String? cropName,
    String? paymentMode,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    String? dateRange,
    String? minAmount,
    String? maxAmount,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (merchantId?.isNotEmpty == true)
        queryParams['merchant_id'] = merchantId!;
      if (merchantName?.isNotEmpty == true)
        queryParams['merchant_name'] = merchantName!;
      if (yieldId?.isNotEmpty == true) queryParams['yield_id'] = yieldId!;
      if (cropName?.isNotEmpty == true) queryParams['crop_name'] = cropName!;
      if (paymentMode?.isNotEmpty == true)
        queryParams['payment_mode'] = paymentMode!;
      if (status?.isNotEmpty == true) queryParams['status'] = status!;
      if (paymentStatus?.isNotEmpty == true)
        queryParams['payment_status'] = paymentStatus!;
      if (startDate?.isNotEmpty == true) queryParams['start_date'] = startDate!;
      if (endDate?.isNotEmpty == true) queryParams['end_date'] = endDate!;
      if (dateRange?.isNotEmpty == true) queryParams['date_range'] = dateRange!;
      if (minAmount?.isNotEmpty == true) queryParams['min_amount'] = minAmount!;
      if (maxAmount?.isNotEmpty == true) queryParams['max_amount'] = maxAmount!;

      final uri = Uri.parse(bulkPdfReportUrl).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(minutes: 5));

      // PDF reports return file data
      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': {
            'status': 'success',
            'message': 'Bulk PDF report generated successfully',
            'file_data': response.bodyBytes,
            'content_type': response.headers['content-type'],
            'filename':
                _extractFilename(response.headers['content-disposition']),
          },
        };
      } else {
        final jsonResponse = _parseResponse(response);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } catch (e) {
      return _handleError(e, 'generateBulkPdfReport');
    }
  }

  // VALIDATION AND UTILITY HELPER METHODS

  /// Validate sale data before sending to API
  static Map<String, String>? _validateSaleData(Map<String, dynamic> saleData) {
    Map<String, String> errors = {};

    // Validate merchant ID
    if (saleData['merchant'] == null ||
        saleData['merchant'].toString().trim().isEmpty) {
      errors['merchant'] = 'Merchant is required';
    }

    // Validate yield record ID
    if (saleData['yield_record'] == null ||
        saleData['yield_record'].toString().trim().isEmpty) {
      errors['yield_record'] = 'Yield record is required';
    }

    // Validate payment mode
    if (saleData['payment_mode'] == null ||
        saleData['payment_mode'].toString().trim().isEmpty) {
      errors['payment_mode'] = 'Payment mode is required';
    }

    // Validate harvest date
    if (saleData['harvest_date'] == null) {
      errors['harvest_date'] = 'Harvest date is required';
    }

    // Validate financial fields
    if (saleData['total_calculated_amount'] == null ||
        double.tryParse(saleData['total_calculated_amount'].toString()) ==
            null) {
      errors['total_calculated_amount'] =
          'Valid total calculated amount is required';
    } else {
      final totalAmount =
          double.parse(saleData['total_calculated_amount'].toString());
      if (totalAmount <= 0) {
        errors['total_calculated_amount'] =
            'Total calculated amount must be greater than 0';
      }
    }

    // FIXED: Validate variants (not sale_variants)
    if (saleData['variants'] == null ||
        (saleData['variants'] as List).isEmpty) {
      errors['variants'] = 'At least one variant must be specified';
    } else {
      final variants = saleData['variants'] as List;
      for (int i = 0; i < variants.length; i++) {
        final variant = variants[i];
        if (variant['crop_variant_id'] == null) {
          errors['variant_${i}_crop_variant_id'] =
              'Crop variant ID is required';
        }
        if (variant['quantity'] == null ||
            double.tryParse(variant['quantity'].toString()) == null ||
            double.parse(variant['quantity'].toString()) <= 0) {
          errors['variant_${i}_quantity'] = 'Valid quantity is required';
        }
        if (variant['amount'] == null ||
            double.tryParse(variant['amount'].toString()) == null ||
            double.parse(variant['amount'].toString()) <= 0) {
          errors['variant_${i}_amount'] = 'Valid amount per unit is required';
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
  static Map<String, String>? _validateImageFiles(List<File> files) {
    Map<String, String> errors = {};

    if (files.length > 10) {
      errors['sale_images'] = 'Maximum 10 images are allowed';
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

  /// Parse HTTP response
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {
          'status': response.statusCode == 200 ? 'success' : 'error',
          'message': response.statusCode == 200
              ? 'Operation completed successfully'
              : 'Empty response from server'
        };
      }
      return json.decode(response.body);
    } catch (e) {
      print('Error parsing response JSON: $e');
      return {
        'status': 'error',
        'message': 'Invalid response format from server',
        'raw_response': response.body
      };
    }
  }

  /// Handle errors consistently
  static Map<String, dynamic> _handleError(dynamic error, String methodName) {
    print('Error in $methodName: $error');

    if (error is SocketException) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message':
              'Network connection error. Please check your internet connection.'
        },
      };
    } else if (error is TimeoutException) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } else {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network error: ${error.toString()}'
        },
      };
    }
  }

  /// Extract filename from Content-Disposition header
  static String _extractFilename(String? contentDisposition) {
    if (contentDisposition == null) return 'download.pdf';

    // Works for: filename="file.pdf" OR filename=file.pdf
    final regex = RegExp(r'filename="?([^\";]+)"?');
    final match = regex.firstMatch(contentDisposition);

    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }

    return 'download.pdf';
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

  /// Save file to device storage (for downloaded reports)
  static Future<String?> saveFileToStorage(
      List<int> fileData, String filename) async {
    try {
      // You'll need to implement this based on your app's file storage strategy
      // This is a placeholder - you might use path_provider package
      final directory =
          Directory('/storage/emulated/0/Download'); // Android Downloads
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(fileData);
      return file.path;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }
}
