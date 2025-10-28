import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../models/attendance/attendance_record_model.dart';

class AttendanceService {
  static const int timeoutDuration = 30;

  /// Get weekly attendance data
  static Future<Map<String, dynamic>> getWeeklyData({
    required DateTime weekStart,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(weekStart);
      final uri = Uri.parse(getAttendanceListUrl)
          .replace(queryParameters: {'week_start': formattedDate});

      print('🔍 Calling API: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // 🔍 DEBUG: Print the response structure
          print('=== API RESPONSE DEBUG ===');
          print('Response keys: ${responseData.keys}');

          // CRITICAL: Print payment-related fields
          if (responseData['employees'] is List) {
            List employees = responseData['employees'];
            print('Total employees in response: ${employees.length}');

            // Print detailed info for first 3 employees
            for (int i = 0; i < employees.length && i < 3; i++) {
              final emp = employees[i];
              print('--- Employee $i Debug ---');
              print('  ID: ${emp['employee_id']}');
              print('  Name: ${emp['employee_name']}');
              print('  Payment Status: ${emp['payment_status']}');
              print('  Partial Payment: ${emp['partial_payment']}');
              print('  Remaining Amount: ${emp['remaining_amount']}');
              print('  Total Wages: ${emp['total_wages']}');
              print('  All Keys: ${emp.keys}');
            }

            // Count employees by payment status
            int paid =
                employees.where((e) => e['payment_status'] == 'paid').length;
            int partial =
                employees.where((e) => e['payment_status'] == 'partial').length;
            int pending =
                employees.where((e) => e['payment_status'] == 'pending').length;

            print('Payment Status Summary:');
            print('  Paid: $paid');
            print('  Partial: $partial');
            print('  Pending: $pending');
          }

          // Validate required fields from backend
          if (responseData.containsKey('employees') &&
              responseData.containsKey('week_start_date') &&
              responseData.containsKey('week_end_date')) {
            print('✅ Response structure valid');
            print('Wages Paid Flag: ${responseData['wages_paid']}');
            print('Payment Type: ${responseData['payment_type']}');

            return {
              'success': true,
              'statusCode': response.statusCode,
              'data': responseData,
            };
          } else {
            print('❌ Invalid response structure - missing required fields');
            print('Available keys: ${responseData.keys}');
            return {
              'success': false,
              'statusCode': response.statusCode,
              'data': {
                'status': 'error',
                'message': 'Invalid response structure from server'
              },
            };
          }
        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError');
          print('Raw response body: ${response.body}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': {
              'status': 'error',
              'message':
                  'Invalid JSON response from server: ${jsonError.toString()}'
            },
          };
        }
      } else {
        // Handle HTTP error responses
        try {
          final errorData = json.decode(response.body);
          print('❌ API Error: ${errorData}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'data': {
              'status': 'error',
              'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}'
            },
          };
        }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
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
      print('⏱️ Timeout error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('💥 Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Verify payment data for debugging
  static Future<Map<String, dynamic>> verifyPaymentData({
    required DateTime weekStart,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(weekStart);
      final uri = Uri.parse('$baseUrl/api/attendance/verify-payment-data/')
          .replace(queryParameters: {'week_start': formattedDate});

      print('🔍 Verifying payment data: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Verification successful');
        print('Data: $data');
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Verification failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Verification error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Mark attendance for multiple employees
  static Future<Map<String, dynamic>> markAttendance({
    required DateTime date,
    required List<EmployeeAttendance> employeeAttendances,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final requestBody = {
        'date': formattedDate,
        'employees': employeeAttendances.map((e) => e.toJson()).toList(),
      };

      final response = await http
          .post(
            Uri.parse(createDailyAttendanceUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Get attendance for a specific date
  static Future<Map<String, dynamic>> getAttendance({
    required DateTime date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(getAttendanceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Update attendance for a specific date
  static Future<Map<String, dynamic>> updateAttendance({
    required DateTime date,
    required List<EmployeeAttendance> employeeAttendances,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final requestBody = {
        'date': formattedDate,
        'employees': employeeAttendances.map((e) => e.toJson()).toList(),
      };

      final response = await http
          .put(
            Uri.parse(updateAttendanceUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Update single employee attendance
  static Future<Map<String, dynamic>> updateSingleAttendance({
    required String employeeId,
    required String employeeName,
    required DateTime date,
    required int status,
  }) async {
    try {
      // Validate parameters
      if (employeeId.trim().isEmpty) {
        return {
          'success': false,
          'data': {'message': 'Employee ID is required'}
        };
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final requestBody = {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'date': formattedDate,
        'status': status,
      };

      final response = await http
          .post(
            Uri.parse(updateSingleAttendanceUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: timeoutDuration));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } on SocketException catch (e) {
      print('Network error in updateSingleAttendance: $e');
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
      print('Timeout error in updateSingleAttendance: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } on FormatException catch (e) {
      print('JSON parsing error in updateSingleAttendance: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      print('Unexpected error in updateSingleAttendance: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Pay wages (individual or all)
  static Future<Map<String, dynamic>> payWages({
    required WagePaymentRequest request,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(payWagesUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Get wage summary for a week
  static Future<Map<String, dynamic>> getWageSummary({
    required DateTime weekStart,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(weekStart);
      final uri = Uri.parse(wageSummaryUrl)
          .replace(queryParameters: {'week_start': formattedDate});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Export attendance data
  static Future<Map<String, dynamic>> exportAttendance({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);

      final uri = Uri.parse(exportAttendanceUrl).replace(
        queryParameters: {
          'from_date': formattedFromDate,
          'to_date': formattedToDate,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Get list of active employees
  static Future<Map<String, dynamic>> getActiveEmployees() async {
    try {
      final response = await http.get(
        Uri.parse(getActiveEmployeesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Get attendance statistics
  static Future<Map<String, dynamic>> getAttendanceStatistics({
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

      final uri = Uri.parse('$baseUrl/api/attendance-statistics/').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: timeoutDuration));

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
          'message':
              'Network connection error. Please check your internet connection.'
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
    } on FormatException catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Invalid response format from server.'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'An unexpected error occurred: ${e.toString()}'
        },
      };
    }
  }

  /// Generate weekly wage PDF
  static Future<Map<String, dynamic>> generateWeeklyWagePdf({
    required DateTime weekStart,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(weekStart);
      final uri = Uri.parse(pdfExport)
          .replace(queryParameters: {'week_start': formattedDate});

      print('Calling PDF generation API: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/pdf, application/json', // Accept both types
        },
      ).timeout(Duration(seconds: AttendanceService.timeoutDuration));

      print('PDF API Response status: ${response.statusCode}');
      print(
          'PDF API Response content-type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        // Check if response is PDF or JSON based on content-type
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf')) {
          // PDF data received as bytes
          final pdfBytes = response.bodyBytes;

          return {
            'success': true,
            'data': pdfBytes,
            'message': 'PDF generated successfully',
          };
        } else {
          // Handle unexpected successful JSON response
          return {
            'success': false,
            'data': null,
            'message': 'Unexpected response format: $contentType',
          };
        }
      } else {
        // Handle error response
        String errorMessage = 'Failed to generate PDF';

        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          // If response is not JSON, use the body as error message
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        return {
          'success': false,
          'data': null,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      print('Network error in PDF generation: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': null,
        'message':
            'Network connection error. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('Timeout error in PDF generation: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': null,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('PDF generation error: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': null,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Convert API response to WeeklyData model
  static WeeklyData weeklyDataFromJson(Map<String, dynamic> json) {
    return WeeklyData.fromJson(json);
  }

  /// Convert API response to AttendanceRecord model
  static AttendanceRecord attendanceRecordFromJson(Map<String, dynamic> json) {
    return AttendanceRecord.fromJson(json);
  }

  /// Convert API response to WageSummary model
  static WageSummary wageSummaryFromJson(Map<String, dynamic> json) {
    return WageSummary.fromJson(json);
  }

  /// Convert API response to AttendanceExport model
  static AttendanceExport attendanceExportFromJson(Map<String, dynamic> json) {
    return AttendanceExport.fromJson(json);
  }

  /// Convert API response to Employee list
  static List<EmployeeAttendanceRecord> employeeListFromJson(
      List<dynamic> jsonList) {
    return jsonList
        .map((json) => EmployeeAttendanceRecord.fromJson(json))
        .toList();
  }

  /// Convert EmployeeAttendance to JSON for API requests
  static Map<String, dynamic> employeeAttendanceToJson(
      EmployeeAttendance attendance) {
    return attendance.toJson();
  }

  /// Convert WagePaymentRequest to JSON for API requests
  static Map<String, dynamic> wagePaymentRequestToJson(
      WagePaymentRequest request) {
    return request.toJson();
  }

  /// Get comprehensive employee report
  static Future<Map<String, dynamic>> getEmployeeReport({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Format dates for API
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Build query parameters
      final queryParams = {
        'start_date': startDateStr,
        'end_date': endDateStr,
      };

      final uri = Uri.parse(empReport).replace(queryParameters: queryParams);

      print('Calling API: ${uri.toString()}'); // Debug log

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer YOUR_TOKEN',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Find the specific employee data from the comprehensive report
        final employeesReport = data['employees_detailed_report'] as List?;

        if (employeesReport != null) {
          // Find the employee by ID
          final employeeData = employeesReport.firstWhere(
            (emp) => emp['employee_id'].toString() == employeeId,
            orElse: () => null,
          );

          if (employeeData != null) {
            return {
              'success': true,
              'data': employeeData,
            };
          } else {
            return {
              'success': false,
              'data': null,
              'message': 'Employee not found in report',
            };
          }
        } else {
          return {
            'success': false,
            'data': null,
            'message': 'No employee data found in response',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'data': null,
          'message': 'Employee report endpoint not found',
        };
      } else {
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'data': null,
            'message': errorData['error'] ?? 'API request failed',
          };
        } catch (e) {
          return {
            'success': false,
            'data': null,
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print('Exception in getEmployeeReport: $e'); // Debug log
      return {
        'success': false,
        'data': null,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getSingleEmployeeReport({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Format dates for API
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Build the endpoint URL using the API config constant
      final String endpoint =
          singleEmployeeReportUrl.replaceAll('{id}', employeeId);
      // Build query parameters
      final queryParams = {
        'start_date': startDateStr,
        'end_date': endDateStr,
      };

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);

      print('Calling single employee API: ${uri.toString()}'); // Debug log

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Ensure the response has the expected structure
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Success',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'data': null,
          'error': 'Employee not found',
        };
      } else {
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'data': null,
            'error': errorData['error'] ??
                errorData['message'] ??
                'API request failed',
          };
        } catch (e) {
          return {
            'success': false,
            'data': null,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print('Exception in getSingleEmployeeReport: $e'); // Debug log
      return {
        'success': false,
        'data': null,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

// Extension to help with date formatting (keeping the existing extension)
extension DateTimeFormatting on DateTime {
  String toDateString() => DateFormat('yyyy-MM-dd').format(this);
  String toDisplayString() => DateFormat('dd/MM/yyyy').format(this);

  DateTime get mondayOfWeek {
    return subtract(Duration(days: weekday - 1));
  }

  List<DateTime> get weekDates {
    final monday = mondayOfWeek;
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  static AttendanceStatistics attendanceStatisticsFromJson(
      Map<String, dynamic> json) {
    return AttendanceStatistics.fromJson(json);
  }
}
