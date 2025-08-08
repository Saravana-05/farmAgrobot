import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/employee/emp_model.dart';

class EmployeeService {
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

  /// Get list of employees with filtering and pagination
  static Future<Map<String, dynamic>> getEmployeeList({
    int page = 1,
    int limit = 10,
    String? search,
    String? empType,
    String? gender,
    bool? isActive,  bool? active,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (empType != null && empType.isNotEmpty) {
        queryParams['emp_type'] = empType;
      }

      if (gender != null && gender.isNotEmpty) {
        queryParams['gender'] = gender;
      }

      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final uri = Uri.parse(viewEmployee).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
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

  /// Get employee details by ID
  static Future<Map<String, dynamic>> getEmployeeDetail(
      String employeeId) async {
    try {
      final uri = Uri.parse(editEmployeeUrl.replaceFirst('{id}', employeeId));

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
      // Validate parameters
      if (employeeId.trim().isEmpty) {
        return {
          'success': false,
          'data': {'message': 'Employee ID is required'}
        };
      }

      // ✅ FIX: Replace {id} placeholder with actual employeeId
      final url = statusEmployeeUrl.replaceAll('{id}', employeeId);

      // Prepare the request body based on API specification
      Map<String, dynamic> requestBody;

      if (useAction) {
        // Use action format: "activate" or "deactivate"
        requestBody = {'action': isActive ? 'activate' : 'deactivate'};
      } else {
        // ✅ FIX: Use boolean status format (true for active, false for inactive)
        requestBody = {
          'status': isActive // Send as boolean, NOT integer
        };
      }

      // Make the API call using PATCH method with the corrected URL
      final response = await http
          .patch(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      print('Calling API: $url');
      print(
          'Request body: ${jsonEncode(requestBody)}'); // ✅ Debug: Show what we're sending
      print('Status update response status: ${response.statusCode}');
      print('Status update response body: ${response.body}');

      // Parse the response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('JSON decode error: $e');
        return {
          'success': false,
          'data': {'message': 'Invalid JSON response from server'}
        };
      }

      // Handle different response status codes
      if (response.statusCode == 200) {
        // Check the response status field from Django API
        if (responseData['status'] == 'success') {
          // ✅ FIX: Django returns boolean status, no need to convert
          return {
            'success': true,
            'data': responseData,
          };
        } else if (responseData['status'] == 'warning') {
          // Employee already has the requested status
          // ✅ FIX: Django returns boolean status, no need to convert
          return {
            'success': true,
            'data': responseData,
          };
        } else {
          // API returned error status
          return {
            'success': false,
            'data': {
              'message': responseData['message'] ?? 'Unknown error occurred',
            }
          };
        }
      } else if (response.statusCode == 400) {
        // Bad request - validation error
        return {
          'success': false,
          'data': {
            'message': responseData['message'] ?? 'Invalid request data',
            'status_code': response.statusCode,
          }
        };
      } else if (response.statusCode == 404) {
        // Employee not found
        return {
          'success': false,
          'data': {
            'message': responseData['message'] ?? 'Employee not found',
            'status_code': response.statusCode,
          }
        };
      } else if (response.statusCode == 500) {
        // Internal server error
        return {
          'success': false,
          'data': {
            'message': responseData['message'] ?? 'Internal server error',
            'status_code': response.statusCode,
          }
        };
      } else {
        // Other HTTP errors
        return {
          'success': false,
          'data': {
            'message': responseData['message'] ?? 'Server error occurred',
            'status_code': response.statusCode,
          }
        };
      }
    } on SocketException catch (e) {
      print('Network error in updateEmployeeStatus: $e');
      return {
        'success': false,
        'data': {
          'message':
              'Network connection error. Please check your internet connection.'
        }
      };
    } on TimeoutException catch (e) {
      print('Timeout error in updateEmployeeStatus: $e');
      return {
        'success': false,
        'data': {'message': 'Request timeout. Please try again.'}
      };
    } on FormatException catch (e) {
      print('JSON parsing error in updateEmployeeStatus: $e');
      return {
        'success': false,
        'data': {'message': 'Invalid response format from server.'}
      };
    } catch (e) {
      print('Unexpected error in updateEmployeeStatus: $e');
      return {
        'success': false,
        'data': {'message': 'An unexpected error occurred: ${e.toString()}'}
      };
    }
  }
}
