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
    bool useDefaultAvatar = false, required Employee employee, Uint8List? imageBytes, required bool useDefaultImage,
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
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
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
    bool? isActive,
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
      
      final response = await http.get(uri, );
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
      };
    }
  }

  /// Get employee details by ID
  static Future<Map<String, dynamic>> getEmployeeDetail(String employeeId) async {
    try {
      final uri = Uri.parse('$baseUrl/get_employee_detail/$employeeId/');
      
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'},);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
      };
    }
  }

  /// Get employee statistics
  static Future<Map<String, dynamic>> getEmployeeStatistics() async {
    try {
      final uri = Uri.parse('$baseUrl/get_employee_statistics/');
      
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'},);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
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
      final uri = Uri.parse('$baseUrl/edit_employee_data/$employeeId/');
      
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
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
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
      
      final uri = Uri.parse('$baseUrl/delete_employee/$employeeId/').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.delete(uri, headers: {'Content-Type': 'application/json'},);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
      };
    }
  }

  /// Restore soft-deleted employee
  static Future<Map<String, dynamic>> restoreEmployee(String employeeId) async {
    try {
      final uri = Uri.parse('$baseUrl/restore_employee/$employeeId/');
      
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'},);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': {'status': 'error', 'message': 'Network error: ${e.toString()}'},
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
      'joining_date': employee.joiningDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'status': employee.status,
      
    };
  }
 
}