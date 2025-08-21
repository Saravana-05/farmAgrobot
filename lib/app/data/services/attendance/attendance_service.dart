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
          print('Response type: ${responseData.runtimeType}');

          // Validate required fields from backend
          if (responseData.containsKey('employees') &&
              responseData.containsKey('week_start_date') &&
              responseData.containsKey('week_end_date')) {
           

            // Print employee details for debugging
            if (responseData['employees'] is List) {
              List employees = responseData['employees'];
              for (int i = 0; i < employees.length && i < 3; i++) {
                print(
                    'Employee $i: ID=${employees[i]['employee_id']}, Name=${employees[i]['employee_name']}, Status=${employees[i]['payment_status']}');
              }
            }

            // Return the data directly since backend doesn't wrap it
            return {
              'success': true,
              'statusCode': response.statusCode,
              'data': responseData, // Direct response data from backend
            };
          } else {
            print('❌ Invalid response structure - missing required fields');
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
        Uri.parse('$baseUrl/api/get-active-employees/'),
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
  static List<EmployeeAttendanceRecord> employeeListFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => EmployeeAttendanceRecord.fromJson(json)).toList();
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
