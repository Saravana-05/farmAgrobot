import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../models/employee/emp_model.dart';

class EmployeeService {
  /// Common response handler with better logging
  static Map<String, dynamic> handleResponse(http.Response response) {
    print("➡️ API Response [${response.statusCode}] ${response.request?.url}");
    print("Body: ${response.body}");

    try {
      final decoded = json.decode(response.body);
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'data': decoded,
      };
    } on FormatException catch (e) {
      print("❌ JSON decode error: $e");
      return {
        'success': false,
        'statusCode': response.statusCode,
        'data': {
          'status': 'error',
          'message': 'Invalid JSON response from server',
          'raw': response.body,
        },
      };
    }
  }

  /// Common error handler
  static Map<String, dynamic> handleError(dynamic e, [String action = ""]) {
    print("❌ Error in $action: $e");
    return {
      'success': false,
      'statusCode': 500,
      'data': {
        'status': 'error',
        'message': 'Unexpected error: ${e.toString()}',
      },
    };
  }

  /// Save employee data with optional image upload
  static Future<Map<String, dynamic>> saveEmployee({
    required Map<String, dynamic> employeeData,
    File? imageFile,
    bool useDefaultAvatar = false,
    required Employee employee,
    Uint8List? imageBytes,
    required bool useDefaultImage,
  }) async {
    try {
      final uri = Uri.parse(addEmployee);

      if (imageFile != null || useDefaultAvatar) {
        // Use multipart request for file upload
        var request = http.MultipartRequest('POST', uri);

        // Add employee data fields
        employeeData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add image file if provided
        if (imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
          ));
        }

        // Add default avatar flag if requested
        if (useDefaultAvatar) {
          request.fields['default_avatar'] = 'true';
        }

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        return {
          'success': response.statusCode == 201,
          'statusCode': response.statusCode,
          'data': json.decode(responseData),
        };
      } else {
        // Regular JSON request without file
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(employeeData),
        );

        return {
          'success': response.statusCode == 201,
          'statusCode': response.statusCode,
          'data': json.decode(response.body),
        };
      }
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

  /// Get list of employees
  static Future<Map<String, dynamic>> getEmployeeList({
    int page = 1,
    int limit = 10,
    String? search,
    String? empType,
    String? gender,
    bool? isActive,
    bool? active,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search?.isNotEmpty == true) queryParams['search'] = search!;
      if (empType?.isNotEmpty == true) queryParams['emp_type'] = empType!;
      if (gender?.isNotEmpty == true) queryParams['gender'] = gender!;
      if (isActive != null) queryParams['is_active'] = isActive.toString();

      final uri = Uri.parse(viewEmployee).replace(queryParameters: queryParams);
      final response = await http.get(uri);
      return handleResponse(response);
    } catch (e) {
      return handleError(e, "getEmployeeList");
    }
  }

  /// Get employee details by ID
  /// Get employee detail with optional date parameter for historical wage lookup
static Future<Map<String, dynamic>> getEmployeeDetail(
  String employeeId, {
  DateTime? targetDate,
}) async {
  try {
    // Build the URL with optional date parameter
    String url = editEmployeeUrl.replaceFirst('{id}', employeeId);
    
    // Add date query parameter if provided
    if (targetDate != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
      final uri = Uri.parse(url);
      url = uri.replace(queryParameters: {'date': dateStr}).toString();
    }
    
    final uri = Uri.parse(url);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return {
      'success': response.statusCode == 200,
      'statusCode': response.statusCode,
      'data': json.decode(response.body),
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
  /// Get employee statistics
  static Future<Map<String, dynamic>> getEmployeeStatistics() async {
    try {
      final uri = Uri.parse('$baseUrl/get_employee_statistics/');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
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

  /// Edit employee data with optional image upload
  static Future<Map<String, dynamic>> editEmployee({
    required String employeeId,
    required Map<String, dynamic> employeeData,
    File? imageFile,
    bool useDefaultAvatar = false,
    bool removeImage = false,
  }) async {
    try {
      final uri = Uri.parse(updateEmployeeUrl.replaceFirst('{id}', employeeId));

      if (imageFile != null || useDefaultAvatar || removeImage) {
        // Use multipart request for file operations
        var request = http.MultipartRequest('PUT', uri);

        // Add employee data fields
        employeeData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add image file if provided
        if (imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
          ));
        }

        // Add flags
        if (useDefaultAvatar) {
          request.fields['default_avatar'] = 'true';
        }

        if (removeImage) {
          request.fields['remove_image'] = 'true';
        }

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        return {
          'success': response.statusCode == 200,
          'statusCode': response.statusCode,
          'data': json.decode(responseData),
        };
      } else {
        // Regular JSON request without file operations
        final response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(employeeData),
        );

        return {
          'success': response.statusCode == 200,
          'statusCode': response.statusCode,
          'data': json.decode(response.body),
        };
      }
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

  /// Delete employee (soft delete by default, hard delete if specified)
  static Future<Map<String, dynamic>> deleteEmployee({
    required String employeeId,
    bool hardDelete = false,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (hardDelete) {
        queryParams['hard_delete'] = 'true';
      }
      final url = deleteEmployeeUrl.replaceFirst('{id}', employeeId);
      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
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

  /// Restore soft-deleted employee
  static Future<Map<String, dynamic>> restoreEmployee(String employeeId) async {
    try {
      final uri = Uri.parse('$baseUrl/restore_employee/$employeeId/');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
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

  /// Convert API response to Employee model
  static Employee employeeFromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      tamilName: json['tamil_name'] ?? '',
      empType: json['emp_type'] ?? '',
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      joiningDate: json['joining_date'] != null
          ? DateTime.parse(json['joining_date'])
          : DateTime.now(),
      status: json['status'] ?? true,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert Employee model to API request format
  static Map<String, dynamic> employeeToJson(Employee employee) {
    return {
      'name': employee.name,
      'tamil_name': employee.tamilName,
      'emp_type': employee.empType,
      'gender': employee.gender,
      'contact': employee.contact,
      'joining_date': employee.joiningDate
          .toIso8601String()
          .split('T')[0], // YYYY-MM-DD format
      'status': employee.status,
    };
  }

  static Future<Map<String, dynamic>> updateEmployeeStatus({
    required String employeeId,
    required bool isActive,
    bool useAction = false,
  }) async {
    try {
      if (employeeId.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Employee ID is required',
        };
      }

      final url = statusEmployeeUrl.replaceAll('{id}', employeeId);

      // Prepare body
      final requestBody = useAction
          ? {'action': isActive ? 'activate' : 'deactivate'}
          : {'status': isActive};

      print("Calling API: $url");
      print("Request Body: ${jsonEncode(requestBody)}");

      final response = await http
          .patch(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      // Parse JSON safely
      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid JSON response from server',
        };
      }

      // ---------- SUCCESS CASE ----------
      if (response.statusCode == 200) {
        final apiStatus = json['status'];

        return {
          'success': apiStatus == 'success' || apiStatus == 'warning',
          'message': json['message'] ?? '',
          'data': json['data'],
        };
      }

      // ---------- ERROR CASES ----------
      return {
        'success': false,
        'message': json['message'] ?? 'Server error occurred',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }
}
