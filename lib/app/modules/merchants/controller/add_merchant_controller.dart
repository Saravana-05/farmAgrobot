import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/merchant/merchant_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class AddMerchantController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var selectedIndex = 0.obs;
  var selectedPaymentTerms = Rxn<String>();

  // Text controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  // Static data for payment terms (matching the Django model choices)
  final List<String> paymentTerms = ['Cash', 'Card', 'UPI', 'Online'];

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    super.onClose();
  }

  bool _validateForm() {
    // Validate merchant name
    if (nameController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter merchant name');
      return false;
    }

    if (nameController.text.trim().length > 255) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Merchant name must be less than 255 characters');
      return false;
    }

    // Validate address
    if (addressController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter merchant address');
      return false;
    }

    // Validate contact
    if (contactController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter contact number');
      return false;
    }

    // Validate contact format
    if (!MerchantService.isValidContactNumber(contactController.text.trim())) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter a valid contact number (10-15 digits)');
      return false;
    }

    // Validate payment terms
    if (selectedPaymentTerms.value == null ||
        selectedPaymentTerms.value!.isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please select payment terms');
      return false;
    }

    return true;
  }

  void saveMerchant() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Create merchant data map
      Map<String, dynamic> merchantData = {
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'payment_terms': selectedPaymentTerms.value!,
      };

      // Validate merchant data using service validation
      final validationErrors = MerchantService.validateMerchantData(merchantData);
      if (validationErrors != null) {
        CustomSnackbar.showError(
          title: 'Validation Error',
          message: validationErrors.values.first,
        );
        return;
      }

      // Save merchant to API
      Map<String, dynamic> result = await MerchantService.saveMerchant(
        merchantData: merchantData,
      );

      if (result['success']) {
        String message = result['data']['message'] ?? 'Merchant added successfully';
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: message,
        );

        // Clear form
        _clearForm();
        // Wait for snackbar to show
        await Future.delayed(Duration(milliseconds: 1000));
        // Navigate back with success result
        Get.offAllNamed(Routes.MERCHANT, arguments: true);
      } else {
        String errorMessage = 'Failed to add merchant';
        
        // Handle specific error messages from API
        if (result['data'] != null) {
          if (result['data']['message'] != null) {
            errorMessage = result['data']['message'];
          } else if (result['data']['errors'] != null) {
            // Handle validation errors from Django serializer
            final errors = result['data']['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first.toString();
            if (errorMessage.contains('[') && errorMessage.contains(']')) {
              errorMessage = errorMessage.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
            }
          }
        }
        
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error saving merchant: $e');
      CustomSnackbar.showError(title: 'Error', message: 'An unexpected error occurred');
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    nameController.clear();
    addressController.clear();
    contactController.clear();
    selectedPaymentTerms.value = null;
  }

  void navigateToViewMerchants() {
    Get.toNamed(Routes.MERCHANT);
  }

  void navigateToTab(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.offAllNamed('/home');
        break;
      case 1:
        Get.offAllNamed('/dashboard');
        break;
      case 2:
        Get.offAllNamed('/settings');
        break;
    }
  }

  // Helper method to format contact number for display
  String getFormattedContact(String contact) {
    return MerchantService.formatContactNumber(contact);
  }

  // Helper method to get payment terms display name
  String getPaymentTermsDisplayName(String paymentTerms) {
    return MerchantService.getPaymentTermsDisplayName(paymentTerms);
  }
}