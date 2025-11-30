import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/merchant/merchant_model.dart';
import '../../../data/services/merchant/merchant_service.dart';

class MerchantEditController extends GetxController {
  // Form key and controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController paymentTermsController = TextEditingController();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isEditMode = false.obs;
  final RxInt selectedIndex = 0.obs; // For bottom navigation

  // Merchant data
  final Rx<Merchant?> currentMerchant = Rx<Merchant?>(null);
  String merchantId = '';

  // Payment terms dropdown
  final RxString selectedPaymentTerms = 'Cash'.obs;
  final List<String> paymentTermsOptions = MerchantService.getAvailablePaymentTerms();

  @override
  void onInit() {
    super.onInit();
    print('MerchantEditController onInit started');

    final arguments = Get.arguments;
    print('🔍 Arguments received: $arguments');

    if (arguments != null && arguments is Map<String, dynamic>) {
      // Determine if this is edit mode
      if (arguments['mode'] == 'edit') {
        isEditMode.value = true;
      }

      // Handle merchant ID passed as argument
      if (arguments.containsKey('merchantId')) {
        final merchantIdArg = arguments['merchantId'] as String?;
        if (merchantIdArg != null && merchantIdArg.isNotEmpty) {
          print('🔍 Found merchantId: $merchantIdArg');
          merchantId = merchantIdArg;
          isEditMode.value = true;
          _loadMerchantById(merchantIdArg);
        } else {
          print('❌ Invalid merchantId');
          _handleError('Invalid merchant ID');
        }
      }
      // Handle merchant object passed as argument
      else if (arguments.containsKey('merchant')) {
        final merchantData = arguments['merchant'];

        if (merchantData is Merchant) {
          print('🔍 Merchant object received: ${merchantData.toString()}');

          // Validate merchant data
          if (merchantData.id.isEmpty) {
            print('❌ Merchant ID is empty, cannot edit');
            _handleError('Invalid merchant data - missing ID');
            return;
          }

          merchantId = merchantData.id;
          isEditMode.value = true;

          // Always fetch fresh data from server for editing
          print('🔍 Fetching fresh data for merchant ID: ${merchantData.id}');
          _loadMerchantById(merchantData.id);
        } else {
          print('❌ Invalid merchant object type');
          _handleError('Invalid merchant data format');
        }
      } else {
        print('🔍 No existing merchant data, creating new merchant');
        isEditMode.value = false;
        _setDefaultValues();
      }
    } else {
      print('🔍 No arguments provided, creating new merchant');
      isEditMode.value = false;
      _setDefaultValues();
    }

    print('🔍 onInit completed. Mode: ${isEditMode.value ? "Edit" : "Create"}');
  }

  // Method to set default values for new merchant
  void _setDefaultValues() {
    selectedPaymentTerms.value = paymentTermsOptions.first;
  }

  // Method to load merchant by ID
  Future<void> _loadMerchantById(String id) async {
    try {
      isLoading.value = true;
      print('🔍 Loading merchant with ID: $id');

      final result = await MerchantService.getMerchantById(id);
      print('🔍 API Result: $result');

      if (result['success'] == true) {
        final merchantData = result['data'];
        print('🔍 Merchant data received: $merchantData');

        if (merchantData != null && merchantData is Map<String, dynamic>) {
          final merchant = MerchantService.merchantFromJson(merchantData);
          _populateForm(merchant);
          print('✅ Merchant loaded successfully: ${merchant.name}');
        } else {
          print('❌ Invalid merchant data format from API');
          _handleError('Invalid merchant data received from server');
        }
      } else {
        final errorMessage = result['data']?['message'] ??
            result['data']?['error'] ??
            'Failed to load merchant data';
        print('❌ Failed to load merchant: $errorMessage');
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error loading merchant: $e');
      _handleError('Error loading merchant data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with merchant data
  void _populateForm(Merchant merchant) {
    currentMerchant.value = merchant;
    merchantId = merchant.id;

    // Populate form fields
    nameController.text = merchant.name;
    addressController.text = merchant.address;
    contactController.text = merchant.contact;
    
    // Set payment terms
    if (paymentTermsOptions.contains(merchant.paymentTerms)) {
      selectedPaymentTerms.value = merchant.paymentTerms;
    } else {
      selectedPaymentTerms.value = paymentTermsOptions.first;
    }

    print('🔍 Form populated successfully');
    print('🔍 Merchant Name: ${merchant.name}');
    print('🔍 Address: ${merchant.address}');
    print('🔍 Contact: ${merchant.contact}');
    print('🔍 Payment Terms: ${merchant.paymentTerms}');
  }

  // Method to handle errors
  void _handleError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // Navigate back after showing error
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.currentRoute.contains('edit')) {
        Get.back();
      }
    });
  }

  // Navigation methods
  void navigateToViewMerchants() {
    // Navigate to view merchants screen
    Get.toNamed('/view-merchants'); // Adjust route name as needed
  }

  void navigateToTab(int index) {
    selectedIndex.value = index;
    // Handle bottom navigation logic here
    // Navigate to different screens based on index
    switch (index) {
      case 0:
        Get.offNamed('/home'); // Adjust route name as needed
        break;
      case 1:
        Get.offNamed('/merchants'); // Adjust route name as needed
        break;
      case 2:
        Get.offNamed('/profile'); // Adjust route name as needed
        break;
      // Add more cases as needed
    }
  }

  // Method to update payment terms
  void updatePaymentTerms(String? value) {
    if (value != null && paymentTermsOptions.contains(value)) {
      selectedPaymentTerms.value = value;
      print('🔍 Payment terms updated: $value');
    }
  }

  // Method to format contact number as user types
  void formatContactNumber(String value) {
    // Remove any non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    contactController.text = cleaned;
    contactController.selection = TextSelection.fromPosition(
      TextPosition(offset: cleaned.length),
    );
  }

  // Save merchant method
  Future<void> saveMerchant() async {
    try {
      // Validate form
      if (!formKey.currentState!.validate()) {
        return;
      }

      // Additional custom validations
      if (!_validateForm()) {
        return;
      }

      isSaving.value = true;

      // Prepare merchant data
      final merchantData = {
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'payment_terms': selectedPaymentTerms.value,
      };

      // Validate merchant data using service
      final validationErrors = MerchantService.validateMerchantData(merchantData);
      if (validationErrors != null) {
        _showValidationErrors(validationErrors);
        return;
      }

      Map<String, dynamic> result;

      if (isEditMode.value && merchantId.isNotEmpty) {
        // Update existing merchant
        result = await MerchantService.updateMerchant(
          merchantId: merchantId,
          merchantData: merchantData,
        );
      } else {
        // Create new merchant
        result = await MerchantService.saveMerchant(
          merchantData: merchantData,
        );
      }

      if (result['success'] == true) {
        final responseData = result['data'];
        String message = responseData['message'] ??
            (isEditMode.value
                ? 'Merchant updated successfully'
                : 'Merchant added successfully');

        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate back
        Get.back(result: true);
      } else {
        final errorMessage = result['data']?['message'] ??
            result['data']?['error'] ??
            'Failed to save merchant';
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error saving merchant: $e');
      _handleError('Error saving merchant: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  // Form validation
  bool _validateForm() {
    // Check for duplicate merchant name (excluding current merchant in edit mode)
    return _validateDuplicateName();
  }

  // Check for duplicate merchant name
  bool _validateDuplicateName() {
    final name = nameController.text.trim();
    if (name.isEmpty) return true;

    // This is a simplified check - you might want to implement server-side validation
    // For now, we'll assume the server handles duplicate checks
    return true;
  }

  void _showValidationErrors(Map<String, String> errors) {
    final errorMessage = errors.values.join('\n');
    Get.snackbar(
      'Validation Errors',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // Method to check if merchant name exists (for real-time validation)
  Future<void> checkMerchantNameExists() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final exists = await MerchantService.checkMerchantNameExists(
        name,
        excludeId: isEditMode.value ? merchantId : null,
      );

      if (exists) {
        Get.snackbar(
          'Warning',
          'A merchant with this name already exists',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error checking merchant name: $e');
    }
  }

  // Method to test API connection
  Future<void> testApiConnection() async {
    try {
      print('🔍 Testing API connection...');

      // Test by fetching all merchants
      final result = await MerchantService.getAllMerchants();

      print('✅ API Test Result: $result');

      if (result['success'] == true) {
        Get.snackbar(
          'API Test',
          'API connection successful',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'API Test',
          'API returned error: ${result['data']?['message'] ?? 'Unknown error'}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ API Test Error: $e');
      Get.snackbar(
        'API Test',
        'API call failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Getters for UI
  String get formattedContact => MerchantService.formatContactNumber(contactController.text);
  String get paymentTermsDisplayName => MerchantService.getPaymentTermsDisplayName(selectedPaymentTerms.value);

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    paymentTermsController.dispose();
    super.onClose();
  }
}