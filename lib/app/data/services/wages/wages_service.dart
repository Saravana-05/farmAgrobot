import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/wages/wages_model.dart';

class WageService {
  /// Save wage data for an employee
  static Future<Map<String, dynamic>> saveWage({
    required Map<String, dynamic> wageData,
  }) async {
    try {
      final uri = Uri.parse(addWage);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(wageData),
      ).timeout(Duration(seconds: 30));

      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
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

  /// Get list of wages with filtering, searching, and pagination
  static Future<Map<String, dynamic>> getWageList({
    int page = 1,
    int limit = 10,
    String? search,
    String? employeeId,
    bool? currentOnly,
    double? minAmount,
    double? maxAmount,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employee_id'] = employeeId;
      }

      if (currentOnly != null) {
        queryParams['current_only'] = currentOnly.toString();
      }

      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }

      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }

      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from_date'] = fromDate;
      }

      if (toDate != null && toDate.isNotEmpty) {
        queryParams['to_date'] = toDate;
      }

      final uri = Uri.parse(viewWage).replace(
        queryParameters: queryParams,
      );

      print('Making request to: $uri'); // Debug log

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'status': 'error',
            'message': 'Empty response from server'
          },
        };
      }

      // Try to decode JSON with better error handling
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (jsonError) {
        print('JSON decode error: $jsonError');
        print('Response body that failed to decode: ${response.body}');
        
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {
            'status': 'error',
            'message': 'Invalid response format from server'
          },
        };
      }

      // Check for successful response
      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }

    } on SocketException catch (e) {
      print('Socket exception: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      print('Timeout exception: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } on FormatException catch (e) {
      print('Format exception: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server'
        },
      };
    } catch (e) {
      print('General exception: $e');
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

  /// Get wage details by ID
  static Future<Map<String, dynamic>> getWageDetail(String wageId) async {
    try {
      final uri = Uri.parse(editWageUrl.replaceAll('{id}', wageId));

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
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

  /// Get all wages for a specific employee
  static Future<Map<String, dynamic>> getEmployeeWages(String employeeId) async {
    try {
      final uri = Uri.parse('$baseUrl/get_employee_wages/$employeeId/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
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

  /// Get wage statistics and summary information
  static Future<Map<String, dynamic>> getWageStatistics() async {
    try {
      final uri = Uri.parse('$baseUrl/get_wage_statistics/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
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

  /// Edit wage data
  static Future<Map<String, dynamic>> editWage({
    required String wageId,
    required Map<String, dynamic> wageData,
  }) async {
    try {
      final uri = Uri.parse(updateEmployeeUrl.replaceAll('{id}', wageId));

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(wageData),
      ).timeout(Duration(seconds: 30));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
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

  /// Delete wage record
  static Future<Map<String, dynamic>> deleteWage(String id, {
    String? wageId, // Not needed but keeping for backward compatibility
    bool hardDelete = false, // Default to false as you mentioned
  }) async {
    try {
      // Replace the {id} placeholder with the actual wage ID
      String finalUrl = deleteWageUrl.replaceAll('{id}', id);
      
      // Since you don't need hard_delete parameter, we won't add any query parameters
      // unless hardDelete is explicitly true
      final Map<String, String> queryParams = {};
      if (hardDelete) {
        queryParams['hard_delete'] = 'true';
      }

      final uri = Uri.parse(finalUrl).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      print('DELETE request URL: $uri'); // Debug log

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 30));

      print('DELETE response status: ${response.statusCode}'); // Debug log
      print('DELETE response body: ${response.body}'); // Debug log

      // Handle response body parsing
      Map<String, dynamic> responseData = {};
      
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (jsonError) {
          print('JSON decode error: $jsonError');
          print('Response body that failed to parse: "${response.body}"');
          
          // If JSON parsing fails, create a response based on status code
          responseData = {
            'status': response.statusCode == 200 ? 'success' : 'error',
            'message': response.statusCode == 200 
                ? 'Wage deleted successfully' 
                : 'Failed to delete wage - Invalid server response',
          };
        }
      } else {
        // Handle empty response body (common for DELETE operations)
        responseData = {
          'status': response.statusCode == 200 || response.statusCode == 204 ? 'success' : 'error',
          'message': response.statusCode == 200 || response.statusCode == 204
              ? 'Wage deleted successfully' 
              : 'Failed to delete wage',
        };
      }

      // Return success for both 200 and 204 status codes
      bool isSuccess = response.statusCode == 200 || response.statusCode == 204;

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'data': responseData,
      };
      
    } on SocketException catch (e) {
      print('Socket exception: $e');
      return {
        'success': false,
        'statusCode': 0,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      print('Timeout exception: $e');
      return {
        'success': false,
        'statusCode': 408,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } on FormatException catch (e) {
      print('Format exception (JSON parsing): $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } on HttpException catch (e) {
      print('HTTP exception: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'HTTP error: ${e.message}'
        },
      };
    } catch (e) {
      print('Unexpected exception: $e');
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

  /// End current wage by setting effective_to date
  static Future<Map<String, dynamic>> endCurrentWage({
    required String wageId,
    String? endDate,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/end_current_wage/$wageId/');

      final Map<String, dynamic> requestBody = {};
      if (endDate != null && endDate.isNotEmpty) {
        requestBody['end_date'] = endDate;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Network connection error. Please check your internet connection.'
        },
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
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

  /// Convert API response to Wage model
  static Wage wageFromJson(Map<String, dynamic> json) {
    return Wage.fromJson(json);
  }

  /// Convert Wage model to API request format
  static Map<String, dynamic> wageToJson(Wage wage) {
    return wage.toJson();
  }

  /// Convert Wage model to update API request format
  static Map<String, dynamic> wageToUpdateJson(Wage wage) {
    return wage.toUpdateJson();
  }

  /// Helper method to create wage data map for API calls
  static Map<String, dynamic> createWageData({
    required String employeeId,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    required double amount,
    String? remarks,
  }) {
    final Map<String, dynamic> data = {
      'employee_id': employeeId,
      'effective_from': effectiveFrom.toIso8601String().split('T')[0],
      'amount': amount,
    };

    if (effectiveTo != null) {
      data['effective_to'] = effectiveTo.toIso8601String().split('T')[0];
    }

    if (remarks != null && remarks.isNotEmpty) {
      data['remarks'] = remarks;
    }

    return data;
  }

  /// Helper method to format date for API calls
  static String formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
  }

  /// Helper method to parse date from API response
  static DateTime? parseDateFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString, Error: $e');
      return null;
    }
  }

  /// Helper method to validate wage data before API call
  static List<String> validateWageData(Map<String, dynamic> wageData) {
    final errors = <String>[];

    // Check required fields
    if (wageData['employee_id'] == null || wageData['employee_id'].toString().isEmpty) {
      errors.add('Employee ID is required');
    }

    if (wageData['effective_from'] == null || wageData['effective_from'].toString().isEmpty) {
      errors.add('Effective from date is required');
    }

    if (wageData['amount'] == null) {
      errors.add('Amount is required');
    } else {
      final amount = double.tryParse(wageData['amount'].toString());
      if (amount == null || amount <= 0) {
        errors.add('Amount must be greater than 0');
      }
    }

    // Validate date format and logic
    if (wageData['effective_from'] != null && wageData['effective_to'] != null) {
      try {
        final effectiveFrom = DateTime.parse(wageData['effective_from'].toString());
        final effectiveTo = DateTime.parse(wageData['effective_to'].toString());
        
        if (effectiveTo.isBefore(effectiveFrom)) {
          errors.add('Effective to date must be after effective from date');
        }
      } catch (e) {
        errors.add('Invalid date format. Use YYYY-MM-DD');
      }
    }

    return errors;
  }

  /// Helper method to build query parameters for wage list API
  static Map<String, String> buildWageListQuery({
    int page = 1,
    int limit = 10,
    String? search,
    String? employeeId,
    bool? currentOnly,
    double? minAmount,
    double? maxAmount,
    String? fromDate,
    String? toDate,
  }) {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (employeeId != null && employeeId.isNotEmpty) {
      queryParams['employee_id'] = employeeId;
    }

    if (currentOnly != null) {
      queryParams['current_only'] = currentOnly.toString();
    }

    if (minAmount != null) {
      queryParams['min_amount'] = minAmount.toString();
    }

    if (maxAmount != null) {
      queryParams['max_amount'] = maxAmount.toString();
    }

    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }

    if (toDate != null && toDate.isNotEmpty) {
      queryParams['to_date'] = toDate;
    }

    return queryParams;
  }

  /// Helper method to handle common API response parsing
  static Map<String, dynamic> parseApiResponse(http.Response response) {
    try {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server'
        },
      };
    }
  }

  /// Helper method to check if response indicates success
  static bool isSuccessResponse(Map<String, dynamic> response) {
    return response['success'] == true && 
           response['data'] != null && 
           response['data']['status'] == 'success';
  }

  /// Helper method to extract error message from response
  static String getErrorMessage(Map<String, dynamic> response) {
    if (response['data'] != null && response['data']['message'] != null) {
      return response['data']['message'].toString();
    }
    return 'An unknown error occurred';
  }

  /// Helper method to extract validation errors from response
  static Map<String, dynamic>? getValidationErrors(Map<String, dynamic> response) {
    if (response['data'] != null && response['data']['errors'] != null) {
      return response['data']['errors'];
    }
    return null;
  }
}