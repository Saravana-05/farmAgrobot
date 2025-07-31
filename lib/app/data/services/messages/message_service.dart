import 'package:get/get.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';

class MessageService extends GetxService {
  static MessageService get to => Get.find();

  // Message constants
  static const _messages = {
    // Validation messages
    'validation_name_empty': 'Please enter employee name',
    'validation_tamil_name_empty': 'Please enter Tamil name',
    'validation_employee_type_empty': 'Please select employee type',
    'validation_gender_empty': 'Please select gender',
    'validation_contact_empty': 'Please enter contact number',
    'validation_contact_invalid': 'Contact number must be at least 10 digits',
    'validation_joining_date_empty': 'Please select joining date',
    
    // Success messages
    'success_image_selected': 'Image selected successfully',
    'success_employee_saved': 'Employee saved successfully',
    'success_data_loaded': 'Data loaded successfully',
    'success_form_cleared': 'Form cleared successfully',
    
    // Error messages
    'error_image_selection': 'Failed to select image',
    'error_employee_save': 'Failed to save employee',
    'error_network': 'Network error occurred',
    'error_general': 'An error occurred',
    'error_validation': 'Please check all required fields',
    
    // Info messages
    'info_no_image': 'No image selected',
    'info_processing': 'Processing your request...',
  };

  void showSuccess(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Success';
    CustomSnackbar.showSuccess(
      title: 'Success',
      message: message,
    );
  }

  void showError(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Error occurred';
    CustomSnackbar.showError(
      title: 'Error',
      message: message,
    );
  }

  void showWarning(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Warning';
    CustomSnackbar.showWarning(
      title: 'Warning',
      message: message,
    );
  }

  void showInfo(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Info';
    CustomSnackbar.showInfo(
      title: 'Info',
      message: message,
    );
  }

  // Convenience methods for common scenarios
  void showValidationError(String field) {
    showWarning('validation_${field}_empty');
  }

  void showNetworkError([String? customMessage]) {
    showError('error_network', customMessage);
  }

  void showGeneralError([String? customMessage]) {
    showError('error_general', customMessage);
  }
}
