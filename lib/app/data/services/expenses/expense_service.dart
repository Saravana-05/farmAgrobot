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

      print('Form fields added: ${request.fields}');

      // Handle image upload with priority: imageFile > imageBytes > defaultImage
      bool imageAdded = false;

      if (imageFile != null && await imageFile.exists()) {
        try {
          // Verify file size
          final fileSize = await imageFile.length();
          print('Image file size: $fileSize bytes');

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
            print(
                'Image file added successfully: $fileName (${fileSize} bytes)');
          } else {
            print('Warning: Image file is empty');
          }
        } catch (e) {
          print('Error adding image file: $e');
        }
      }

      // If imageFile failed or is null, try imageBytes
      if (!imageAdded && imageBytes != null && imageBytes.isNotEmpty) {
        try {
          print('Using image bytes, length: ${imageBytes.length}');

          var multipartFile = http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'expense_image.jpg',
          );

          request.files.add(multipartFile);
          imageAdded = true;
          print('Image bytes added successfully: ${imageBytes.length} bytes');
        } catch (e) {
          print('Error adding image bytes: $e');
        }
      }

      // If no image was added, use default
      if (!imageAdded) {
        if (useDefaultImage) {
          request.fields['default_exp_image'] = 'true';
          print('Using default image');
        } else {
          print('No image will be sent');
        }
      }

      print('Final request fields: ${request.fields}');
      print('Final request files: ${request.files.length} files');

      if (request.files.isNotEmpty) {
        for (var file in request.files) {
          print(
              'File: ${file.field}, filename: ${file.filename}, length: ${file.length}');
        }
      }

      // Send the request with timeout
      print('Sending request...');
      var response = await request.send().timeout(
        Duration(seconds: 60), // Increased timeout for image uploads
        onTimeout: () {
          throw TimeoutException('Request timed out', Duration(seconds: 60));
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      var responseBody = await response.stream.bytesToString();
      print('Response body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          var jsonResponse = json.decode(responseBody);
          print('Success response: $jsonResponse');
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Expense saved successfully',
            'data': jsonResponse['data'],
          };
        } catch (e) {
          print('Error parsing success response: $e');
          return {
            'success': true,
            'message': 'Expense saved successfully',
            'data': null,
          };
        }
      } else {
        print('Server error response: ${response.statusCode} - $responseBody');

        try {
          var errorResponse = json.decode(responseBody);
          return {
            'success': false,
            'message': errorResponse['message'] ?? 'Failed to save expense',
            'errors': errorResponse['errors'],
            'status_code': response.statusCode,
          };
        } catch (e) {
          print('Error parsing error response: $e');
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
            'status_code': response.statusCode,
          };
        }
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
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
      print('Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': 'general_error',
      };
    }
  }

  Future<Map<String, dynamic>> getExpenses() async {
    try {
      print('Attempting to fetch from: $baseUrl'); // Debug log

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
        print(
            'Server response: ${response.statusCode} - ${response.body}'); // Debug log
        return {
          'success': false,
          'message':
              'Failed to fetch expenses (Status: ${response.statusCode})',
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}'); // Debug log
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
        'error_type': 'connection_error',
      };
    } on TimeoutException catch (e) {
      print('TimeoutException: ${e.toString()}'); // Debug log
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
        'error_type': 'timeout_error',
      };
    } on HttpException catch (e) {
      print('HttpException: ${e.toString()}'); // Debug log
      return {
        'success': false,
        'message': 'HTTP error occurred: ${e.message}',
        'error_type': 'http_error',
      };
    } catch (e) {
      print('General Exception: ${e.toString()}'); // Debug log
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
      print('Attempting to fetch expense from: $url'); // Debug log

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
        print('Raw API response: $jsonResponse'); // Debug log

        // Check if response has the expected structure
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          // Extract the actual expense data from the nested structure
          final expenseData = jsonResponse['data'] as Map<String, dynamic>;
          print('Extracted expense data: $expenseData'); // Debug log

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
        print('Server response: ${response.statusCode} - ${response.body}');

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
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
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
      print('Attempting to update expense at: $url'); // Debug log

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
      print(
          'Update response: ${response.statusCode} - $responseBody'); // Debug log

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
      print('SocketException: ${e.toString()}');
      return {
        'success': false,
        'message':
            'Connection failed. Please check your internet connection and server status.',
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
        print('Failed to load image: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading image from URL: $e');
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
        print('Delete failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }
}
