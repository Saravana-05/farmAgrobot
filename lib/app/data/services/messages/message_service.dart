import 'package:get/get.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';

class MessageService extends GetxService {
  static MessageService get to => Get.find();

  // Track recent messages to prevent duplicates
  final Map<String, DateTime> _recentMessages = {};
  static const Duration _throttleDuration = Duration(seconds: 2);

  // Message constants
  static const _messages = {
    // Employee validation messages
    'validation_name_empty': 'Please enter employee name',
    'validation_tamil_name_empty': 'Please enter Tamil name',
    'validation_employee_type_empty': 'Please select employee type',
    'validation_gender_empty': 'Please select gender',
    'validation_contact_empty': 'Please enter contact number',
    'validation_contact_invalid': 'Contact number must be at least 10 digits',
    'validation_joining_date_empty': 'Please select joining date',
    'validation_date_range': 'Invalid date range',
    'validation_amount_range': 'Invalid amount range',
    'validation_id_empty': 'Invalid ID',
    
    // Wage validation messages
    'validation_employee_empty': 'Please select an employee',
    'validation_amount_empty': 'Please enter wage amount',
    'validation_amount_invalid': 'Please enter a valid amount greater than 0',
    'validation_effective_from_empty': 'Please select effective from date',
    'validation_date_range_invalid': 'Effective to date must be after effective from date',
    'validation_date_format_invalid': 'Invalid date format',
    
    // Success messages
    'success_image_selected': 'Image selected successfully',
    'success_employee_saved': 'Employee saved successfully',
    'success_wage_saved': 'Wage record saved successfully',
    'success_data_loaded': 'Data loaded successfully',
    'success_form_cleared': 'Form cleared successfully',
    'success_wage_deleted': 'Wage deleted successfully',
    
    // Error messages
    'error_image_selection': 'Failed to select image',
    'error_employee_save': 'Failed to save employee',
    'error_wage_save': 'Failed to save wage record',
    'error_loading_employees': 'Failed to load employees',
    'error_wage_delete': 'Failed to delete wage',
    'error_network': 'Network error occurred',
    'error_general': 'An error occurred',
    'error_validation': 'Please check all required fields',
    
    // Info messages
    'info_no_image': 'No image selected',
    'info_processing': 'Processing your request...',
  };

  bool _shouldShowMessage(String messageKey, String message) {
    final messageId = '$messageKey:$message';
    final now = DateTime.now();
    
    if (_recentMessages.containsKey(messageId)) {
      final lastShown = _recentMessages[messageId]!;
      if (now.difference(lastShown) < _throttleDuration) {
        return false; // Don't show duplicate message within throttle period
      }
    }
    
    _recentMessages[messageId] = now;
    
    // Clean up old entries to prevent memory leaks
    _recentMessages.removeWhere((key, time) => 
        now.difference(time) > Duration(minutes: 5));
    
    return true;
  }

  void showSuccess(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Success';
    
    if (!_shouldShowMessage(messageKey, message)) return;
    
    CustomSnackbar.showSuccess(
      title: 'Success',
      message: message,
    );
  }

  void showError(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Error occurred';
    
    if (!_shouldShowMessage(messageKey, message)) return;
    
    CustomSnackbar.showError(
      title: 'Error',
      message: message,
    );
  }

  void showWarning(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Warning';
    
    if (!_shouldShowMessage(messageKey, message)) return;
    
    CustomSnackbar.showWarning(
      title: 'Warning',
      message: message,
    );
  }

  void showInfo(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Info';
    
    if (!_shouldShowMessage(messageKey, message)) return;
    
    CustomSnackbar.showInfo(
      title: 'Info',
      message: message,
    );
  }

  // Convenience methods for common scenarios
  void showValidationError(String field) {
    String messageKey = 'validation_${field}_empty';
    showWarning(messageKey);
  }

  void showNetworkError([String? customMessage]) {
    showError('error_network', customMessage);
  }

  void showGeneralError([String? customMessage]) {
    showError('error_general', customMessage);
  }

  // Specific validation methods for better code organization
  void showEmployeeValidationError() {
    showWarning('validation_employee_empty');
  }

  void showAmountValidationError() {
    showWarning('validation_amount_empty');
  }

  void showAmountInvalidError() {
    showWarning('validation_amount_invalid');
  }

  void showEffectiveFromValidationError() {
    showWarning('validation_effective_from_empty');
  }

  void showDateRangeValidationError() {
    showWarning('validation_date_range_invalid');
  }

  void showDateFormatError() {
    showError('validation_date_format_invalid');
  }

  // Force show message (bypasses throttling)
  void forceShowError(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Error occurred';
    CustomSnackbar.showError(
      title: 'Error',
      message: message,
    );
  }

  void forceShowSuccess(String messageKey, [String? customMessage]) {
    String message = customMessage ?? _messages[messageKey] ?? 'Success';
    CustomSnackbar.showSuccess(
      title: 'Success',
      message: message,
    );
  }

  // Clear message history (useful for testing or reset scenarios)
  void clearMessageHistory() {
    _recentMessages.clear();
  }
}