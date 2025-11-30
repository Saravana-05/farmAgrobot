import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api.dart';
import '../../models/merchant/merchant_model.dart';

class MerchantService {
  /// Save merchant data
  static Future<Map<String, dynamic>> saveMerchant({
    required Map<String, dynamic> merchantData,
  }) async {
    try {
      final uri = Uri.parse(addMerchant);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(merchantData),
      );

      final jsonResponse = json.decode(response.body);
      
      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in saveMerchant: $e');
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
      print('Timeout error in saveMerchant: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in saveMerchant: $e');
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

  /// Get list of all merchants
  static Future<Map<String, dynamic>> getAllMerchants({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      // Add pagination if needed (you can extend your Django view to support this)
      if (page > 1) queryParams['page'] = page.toString();
      if (limit != 10) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(viewMerchant).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in getAllMerchants: $e');
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
      print('Timeout error in getAllMerchants: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getAllMerchants: $e');
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

  /// Get merchant details by ID
  static Future<Map<String, dynamic>> getMerchantById(String merchantId) async {
    try {
      if (merchantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Merchant ID is required'}
        };
      }

      final uri = Uri.parse(editMerchantUrl.replaceFirst('{id}', merchantId));

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      print('getMerchantById API Response: $responseData'); // Debug log

      // Handle Django's nested response structure
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData['data'], // Extract the actual merchant data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      }
    } on SocketException catch (e) {
      print('Network error in getMerchantById: $e');
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
      print('Timeout error in getMerchantById: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in getMerchantById: $e');
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

  /// Update merchant data
  static Future<Map<String, dynamic>> updateMerchant({
    required String merchantId,
    required Map<String, dynamic> merchantData,
  }) async {
    try {
      if (merchantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Merchant ID is required'}
        };
      }

      final uri = Uri.parse(updateMerchantUrl.replaceFirst('{id}', merchantId));

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(merchantData),
      );

      final jsonResponse = json.decode(response.body);
      
      // Handle Django's nested response structure
      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': jsonResponse['data'], // Extract the actual merchant data
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': jsonResponse,
        };
      }
    } on SocketException catch (e) {
      print('Network error in updateMerchant: $e');
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
      print('Timeout error in updateMerchant: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in updateMerchant: $e');
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

  /// Delete merchant
  static Future<Map<String, dynamic>> deleteMerchant({
    required String merchantId,
  }) async {
    try {
      if (merchantId.trim().isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'data': {'status': 'error', 'message': 'Merchant ID is required'}
        };
      }

      final url = deleteMerchantUrl.replaceFirst('{id}', merchantId);
      final uri = Uri.parse(url);

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final jsonResponse = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonResponse,
      };
    } on SocketException catch (e) {
      print('Network error in deleteMerchant: $e');
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
      print('Timeout error in deleteMerchant: $e');
      return {
        'success': false,
        'statusCode': 500,
        'data': {
          'status': 'error',
          'message': 'Request timeout. Please try again.'
        },
      };
    } catch (e) {
      print('Unexpected error in deleteMerchant: $e');
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

  /// Convert API response to Merchant model
  static Merchant merchantFromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      paymentTerms: json['payment_terms'] ?? '',
      contact: json['contact'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert Merchant model to API request format
  static Map<String, dynamic> merchantToJson(Merchant merchant) {
    final Map<String, dynamic> data = {
      'name': merchant.name,
      'address': merchant.address,
      'payment_terms': merchant.paymentTerms,
      'contact': merchant.contact,
    };

    // Only include non-null values
    return data..removeWhere((key, value) => value == null);
  }

  /// Convert list of API responses to list of Merchant models
  /// This method handles Django's nested response structure
  static List<Merchant> merchantListFromJson(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] is List) {
      final List<dynamic> jsonList = response['data'];
      return jsonList.map((json) => merchantFromJson(json)).toList();
    }
    return [];
  }

  /// Helper method to validate merchant data before sending
  static Map<String, String>? validateMerchantData(Map<String, dynamic> merchantData) {
    Map<String, String> errors = {};

    // Validate merchant name
    if (merchantData['name'] == null ||
        (merchantData['name'] as String).trim().isEmpty) {
      errors['name'] = 'Merchant name is required';
    }

    // Validate merchant name length
    if (merchantData['name'] != null &&
        (merchantData['name'] as String).length > 255) {
      errors['name'] = 'Merchant name must be less than 255 characters';
    }

    // Validate address
    if (merchantData['address'] == null ||
        (merchantData['address'] as String).trim().isEmpty) {
      errors['address'] = 'Address is required';
    }

    // Validate contact
    if (merchantData['contact'] == null ||
        (merchantData['contact'] as String).trim().isEmpty) {
      errors['contact'] = 'Contact number is required';
    }

    // Validate contact format (basic validation for mobile number)
    if (merchantData['contact'] != null) {
      final contact = merchantData['contact'] as String;
      if (contact.length < 10 || contact.length > 15) {
        errors['contact'] = 'Contact number must be between 10 and 15 digits';
      }
      
      // Check if contact contains only digits
      if (!RegExp(r'^\d+$').hasMatch(contact.replaceAll('+', ''))) {
        errors['contact'] = 'Contact number must contain only digits';
      }
    }

    // Validate payment terms
    if (merchantData['payment_terms'] == null ||
        (merchantData['payment_terms'] as String).trim().isEmpty) {
      errors['payment_terms'] = 'Payment terms is required';
    }

    // Validate payment terms against allowed choices
    final allowedPaymentTerms = ['Cash', 'Card', 'UPI', 'Online'];
    if (merchantData['payment_terms'] != null &&
        !allowedPaymentTerms.contains(merchantData['payment_terms'])) {
      errors['payment_terms'] = 'Invalid payment terms. Must be one of: ${allowedPaymentTerms.join(', ')}';
    }

    return errors.isEmpty ? null : errors;
  }

  /// Helper method to validate contact number format
  static bool isValidContactNumber(String? contact) {
    if (contact == null || contact.trim().isEmpty) return false;
    
    // Remove any + symbol for validation
    final cleanContact = contact.replaceAll('+', '');
    
    // Check if it's all digits and within valid length
    return RegExp(r'^\d{10,15}$').hasMatch(cleanContact);
  }

  /// Helper method to format contact number for display
  static String formatContactNumber(String contact) {
    // Basic formatting - you can customize this based on your needs
    if (contact.length == 10) {
      return '${contact.substring(0, 5)} ${contact.substring(5)}';
    }
    return contact;
  }

  /// Helper method to get payment terms display name
  static String getPaymentTermsDisplayName(String paymentTerms) {
    switch (paymentTerms.toLowerCase()) {
      case 'cash':
        return 'Cash Payment';
      case 'card':
        return 'Card Payment';
      case 'upi':
        return 'UPI Payment';
      case 'online':
        return 'Online Payment';
      default:
        return paymentTerms;
    }
  }

  /// Helper method to get available payment terms
  static List<String> getAvailablePaymentTerms() {
    return ['Cash', 'Card', 'UPI', 'Online'];
  }

  /// Helper method to check if a merchant name already exists (for client-side validation)
  static Future<bool> checkMerchantNameExists(String name, {String? excludeId}) async {
    try {
      final result = await getAllMerchants();
      if (result['success']) {
        final merchants = merchantListFromJson(result['data']);
        return merchants.any((merchant) => 
            merchant.name.toLowerCase() == name.toLowerCase() && 
            merchant.id != excludeId);
      }
      return false;
    } catch (e) {
      print('Error checking merchant name: $e');
      return false;
    }
  }

  /// Helper method to search merchants by name or contact
  static Future<List<Merchant>> searchMerchants(String query) async {
    try {
      final result = await getAllMerchants(search: query);
      if (result['success']) {
        return merchantListFromJson(result['data']);
      }
      return [];
    } catch (e) {
      print('Error searching merchants: $e');
      return [];
    }
  }
}