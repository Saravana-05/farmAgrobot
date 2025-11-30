import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../config/api.dart';

class EmployeeWeeklyStatusService {
  static const int timeoutDuration = 30;

  /// Update employee weekly status (activate/deactivate for a specific week)
  static Future<Map<String, dynamic>> updateEmployeeWeeklyStatus({
    required String employeeId,
    required int year,
    required int weekNumber,
    required bool isActive,
    String? reason,
  }) async {
    try {
      final requestBody = {
        'employee_id': employeeId,
        'year': year,
        'week_number': weekNumber,
        'is_active': isActive,
        'reason': reason ?? '',
      };

      print('🔄 Updating employee weekly status: $requestBody');

      final response = await http
          .post(
            Uri.parse(updateEmployeeWeeklyStatusUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: timeoutDuration));

      print('📡 Response status: ${response.statusCode}');
      print('🔄 Updating employee weekly status: $requestBody');
    print('🌐 Full URL: $updateEmployeeWeeklyStatusUrl'); 

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Status updated successfully');

        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      } else {
        // Handle error responses
        try {
          final errorData = json.decode(response.body);
          print('❌ API Error: $errorData');
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

  /// Get week number and year from a date
  static Map<String, int> getWeekInfo(DateTime date) {
    final iso = date.isocalendar();
    return {
      'year': iso.year,
      'week': iso.week,
    };
  }

  /// Get week start (Monday) and end (Sunday) dates
  static Map<String, DateTime> getWeekRange(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(Duration(days: 6));
    
    return {
      'start': DateTime(monday.year, monday.month, monday.day),
      'end': DateTime(sunday.year, sunday.month, sunday.day),
    };
  }
}

// Extension for ISO calendar
extension DateTimeIsoCalendar on DateTime {
  IsoCalendar isocalendar() {
    // ISO 8601 week date calculation
    final dayOfYear = int.parse(DateFormat('D').format(this));
    final weekday = this.weekday;
    
    final week = ((dayOfYear - weekday + 10) / 7).floor();
    
    if (week < 1) {
      return DateTime(year - 1, 12, 28).isocalendar();
    }
    
    if (week > 52) {
      final dec28 = DateTime(year, 12, 28);
      final dec28Week = ((int.parse(DateFormat('D').format(dec28)) - dec28.weekday + 10) / 7).floor();
      
      if (dec28Week == week) {
        return IsoCalendar(year, week);
      } else {
        return IsoCalendar(year + 1, 1);
      }
    }
    
    return IsoCalendar(year, week);
  }
}

class IsoCalendar {
  final int year;
  final int week;
  
  IsoCalendar(this.year, this.week);
}