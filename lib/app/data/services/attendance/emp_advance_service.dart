import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../models/attendance/emp_advance_model.dart';

class EmployeeAdvanceService {
  static const int timeoutDuration = 30;

  /// Create a new employee advance
  static Future<Map<String, dynamic>> createAdvance({
    required CreateAdvanceRequest request,
  }) async {
    try {
      print('📤 Creating employee advance: ${request.toJson()}');

      final response = await http
          .post(
            Uri.parse(empAdvanceCreateUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(Duration(seconds: timeoutDuration));

      print('📡 Create advance response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Advance created successfully');

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        // Handle error response
        try {
          final errorData = json.decode(response.body);
          print('❌ Create advance failed: ${errorData}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': errorData,
            'message': errorData['message'] ?? 'Failed to create advance',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Network connection error. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('💥 Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Get list of employee advances with filtering and pagination
  static Future<Map<String, dynamic>> getAdvances({
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? paymentMode,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employee_id'] = employeeId;
      }

      if (fromDate != null) {
        queryParams['from_date'] = DateFormat('yyyy-MM-dd').format(fromDate);
      }

      if (toDate != null) {
        queryParams['to_date'] = DateFormat('yyyy-MM-dd').format(toDate);
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (paymentMode != null && paymentMode.isNotEmpty) {
        queryParams['payment_mode'] = paymentMode;
      }

      final uri =
          Uri.parse(getEmpAdvancesUrl).replace(queryParameters: queryParams);

      print('🔍 Fetching advances: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

      print('📡 Get advances response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Advances fetched successfully');

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ Fetch advances failed: ${errorData}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': errorData,
            'message': errorData['message'] ?? 'Failed to fetch advances',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Network connection error. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('💥 Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Get detailed information for a specific advance
  static Future<Map<String, dynamic>> getAdvanceDetail({
    required String advanceId,
  }) async {
    try {
      final uri = Uri.parse(getAdvanceDetailUrl + advanceId);

      print('🔍 Fetching advance detail: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

      print('📡 Get advance detail response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Advance detail fetched successfully');

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Advance record not found',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ Fetch advance detail failed: ${errorData}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': errorData['message'] ?? 'Failed to fetch advance detail',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Network connection error. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('💥 Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Get advance summary for a specific employee
  static Future<Map<String, dynamic>> getEmployeeAdvanceSummary({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (fromDate != null) {
        queryParams['from_date'] = DateFormat('yyyy-MM-dd').format(fromDate);
      }

      if (toDate != null) {
        queryParams['to_date'] = DateFormat('yyyy-MM-dd').format(toDate);
      }

      final uri = Uri.parse(getAdvanceSummaryUrl + employeeId).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('🔍 Fetching employee advance summary: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

      print('📡 Get summary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Summary fetched successfully');

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Employee not found',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ Fetch summary failed: ${errorData}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': errorData['message'] ?? 'Failed to fetch summary',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Network connection error. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('💥 Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Delete an employee advance
  static Future<Map<String, dynamic>> deleteAdvance({
    required String advanceId,
    bool hardDelete = false,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (hardDelete) {
        queryParams['hard_delete'] = 'true';
      }

      final uri = Uri.parse(deleteAdvanceUrl + advanceId).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('🗑️ Deleting advance: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

      print('📡 Delete advance response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Advance deleted successfully');

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Advance record not found',
        };
      } else if (response.statusCode == 400) {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': errorData['message'] ??
                'Cannot delete advance that has been adjusted',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'Cannot delete this advance',
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ Delete advance failed: ${errorData}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': errorData['message'] ?? 'Failed to delete advance',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Network connection error. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('💥 Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Convert API response to EmployeeAdvance model
  static EmployeeAdvance advanceFromJson(Map<String, dynamic> json) {
    return EmployeeAdvance.fromJson(json);
  }

  /// Convert API response to EmployeeAdvancesResponse model
  static EmployeeAdvancesResponse advancesListFromJson(
      Map<String, dynamic> json) {
    return EmployeeAdvancesResponse.fromJson(json);
  }

  /// Convert API response to EmployeeAdvanceSummaryData model
  static EmployeeAdvanceSummaryData summaryFromJson(Map<String, dynamic> json) {
    return EmployeeAdvanceSummaryData.fromJson(json);
  }

  /// Convert API response to AdvanceDetailResponse model
  static AdvanceDetailResponse detailFromJson(Map<String, dynamic> json) {
    return AdvanceDetailResponse.fromJson(json);
  }

  /// Helper method to get advances for a specific employee (convenience method)
  static Future<Map<String, dynamic>> getEmployeeAdvances({
    required String employeeId,
    int page = 1,
    int limit = 20,
  }) async {
    return getAdvances(
      employeeId: employeeId,
      page: page,
      limit: limit,
    );
  }

  /// Helper method to get recent advances for an employee
  static Future<Map<String, dynamic>> getRecentAdvances({
    required String employeeId,
    int limit = 5,
  }) async {
    return getAdvances(
      employeeId: employeeId,
      page: 1,
      limit: limit,
    );
  }

  /// Helper method to get advances by status
  static Future<Map<String, dynamic>> getAdvancesByStatus({
    required String status,
    int page = 1,
    int limit = 20,
  }) async {
    return getAdvances(
      status: status,
      page: page,
      limit: limit,
    );
  }

  /// Helper method to get advances by date range
  static Future<Map<String, dynamic>> getAdvancesByDateRange({
    required DateTime fromDate,
    required DateTime toDate,
    String? employeeId,
    int page = 1,
    int limit = 20,
  }) async {
    return getAdvances(
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
      page: page,
      limit: limit,
    );
  }

  /// Validate advance creation request
  static String? validateAdvanceRequest(CreateAdvanceRequest request) {
    if (request.employeeId.trim().isEmpty) {
      return 'Employee ID is required';
    }

    if (request.amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (request.paymentMode.trim().isEmpty) {
      return 'Payment mode is required';
    }

    return null; // No validation errors
  }
}
