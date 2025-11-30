import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/expense/expense_model.dart';

class ExpenseService extends GetxService {
  // Add Expenses Start
  Future<Map<String, dynamic>> saveExpense({
    required ExpenseModel expense,
    File? imageFile,
    Uint8List? imageBytes,
    bool useDefaultImage = false,
  }) async {
    try {
      var uri = Uri.parse(addExpense);
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Connection': 'keep-alive',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Add expense data as form fields
      request.fields.addAll({
        'expense_name': expense.expenseName,
        'date': expense.expenseDate,
        'category': expense.expenseCategory,
        'description': expense.description,
        'amount': expense.amount.toString(),
        'spent_by': expense.spentBy,
        'mode_of_payment': expense.modeOfPayment,
      });

      // Handle image upload with priority: imageFile > imageBytes > defaultImage
      bool imageAdded = false;

      if (imageFile != null && await imageFile.exists()) {
        try {
          // Verify file size
          final fileSize = await imageFile.length();

          if (fileSize > 0) {
            // Get file extension
            String fileName = imageFile.path.split('/').last;
            String extension = fileName.split('.').last.toLowerCase();

            // Validate file extension
            List<String> allowedExtensions = [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp'
            ];
            if (!allowedExtensions.contains(extension)) {
              extension = 'jpg'; // Default to jpg if unknown
              fileName = 'expense_image.$extension';
            }

            var multipartFile = await http.MultipartFile.fromPath(
              'file',
              imageFile.path,
              filename: fileName,
            );

            request.files.add(multipartFile);
            imageAdded = true;
          }
        } catch (e) {
          // Silent error handling for production
        }
      }

      // If imageFile failed or is null, try imageBytes
      if (!imageAdded && imageBytes != null && imageBytes.isNotEmpty) {
        try {
          var multipartFile = http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'expense_image.jpg',
          );

          request.files.add(multipartFile);
          imageAdded = true;
        } catch (e) {
          // Silent error handling for production
        }
      }

      // If no image was added, use default
      if (!imageAdded) {
        if (useDefaultImage) {
          request.fields['default_exp_image'] = 'true';
        }
      }

      // Send the request with timeout
      var response = await request.send().timeout(
        Duration(seconds: 60), // Increased timeout for image uploads
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 60));
        },
      );

      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          var jsonResponse = json.decode(responseBody);
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Expense saved successfully',
            'data': jsonResponse['data'],
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Expense saved successfully',
            'data': null,
          };
        }
      } else {
        try {
          var errorResponse = json.decode(responseBody);
          return {
            'success': false,
            'message': errorResponse['message'] ?? 'Failed to save expense',
            'errors': errorResponse['errors'],
            'status_code': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
            'status_code': response.statusCode,
          };
        }
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  Future<Map<String, dynamic>> getExpenses() async {
    try {
      var response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'data': jsonResponse,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch expenses (Status: ${response.statusCode})',
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }
  // Add Expenses End

  // Get all expenses with optional parameters
  static Future<Map<String, dynamic>> getAllExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
    String? modeOfPayment,
    String? dateFrom,
    String? dateTo,
    String? spentBy,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (modeOfPayment != null && modeOfPayment.isNotEmpty) {
        queryParams['mode_of_payment'] = modeOfPayment;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = dateTo;
      }
      if (spentBy != null && spentBy.isNotEmpty) {
        queryParams['spent_by'] = spentBy;
      }
      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }

      // Build URI with query parameters
      Uri uri = Uri.parse(viewExpense).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get expense by ID
  Future<Map<String, dynamic>> getExpenseById(String id) async {
    if (id.isEmpty) {
      return {
        'success': false,
        'message': 'Expense ID is required',
      };
    }

    try {
      final String url = editExpenseUrl.replaceAll('{id}', id);

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Check if response has the expected structure
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          // Extract the actual expense data from the nested structure
          final expenseData = jsonResponse['data'] as Map<String, dynamic>;

          return {
            'success': true,
            'data':
                expenseData, // Return the actual expense data, not the whole response
            'message': jsonResponse['message'],
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Invalid response format',
          };
        }
      } else {
        String errorMessage;
        try {
          final errorResponse = json.decode(response.body);
          errorMessage =
              errorResponse['message'] ?? 'Failed to load expense data';
        } catch (e) {
          errorMessage =
              'Failed to load expense data (Status: ${response.statusCode})';
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  // Update expense
  Future<Map<String, dynamic>> updateExpense({
    required String id,
    required ExpenseModel expense,
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    if (id.isEmpty) {
      return {
        'success': false,
        'message': 'Expense ID is required',
      };
    }

    try {
      final String url = updateExpenseUrl.replaceAll('{id}', id);

      var uri = Uri.parse(url);
      var request = http.MultipartRequest('PUT', uri);

      // Add expense data as form fields using the model with null safety
      final expenseData = expense.toJson();
      request.fields.addAll(expenseData
          .map((key, value) => MapEntry(key, (value ?? '').toString())));

      // Handle image upload if new image is selected
      if (imageBytes != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'expense_image.jpg',
        );
        request.files.add(multipartFile);
      } else if (imageFile != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'expense_image.jpg',
        );
        request.files.add(multipartFile);
      }

      // Send the request with timeout
      var response = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 30));
        },
      );

      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Expense updated successfully',
          'data': jsonResponse['data'],
        };
      } else {
        String errorMessage;
        try {
          var errorResponse = json.decode(responseBody);
          errorMessage = errorResponse['message'] ?? 'Failed to update expense';
        } catch (e) {
          errorMessage =
              'Failed to update expense (Status: ${response.statusCode})';
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  // Load image from URL
  Future<Uint8List?> loadImageFromUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return null;

    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Image load timed out', Duration(seconds: 15));
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Delete expense
  static Future<bool> deleteExpense(String id) async {
    try {
      // Build the correct URL with the expense ID
      final String url = deleteExpenseUrl.replaceAll('{id}', id);

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }
}