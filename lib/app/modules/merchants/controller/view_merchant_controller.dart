import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/merchant/merchant_model.dart';
import '../../../data/services/merchant/merchant_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';
import '../views/merchant_screen.dart';

class MerchantsViewController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var filteredMerchants = <Merchant>[].obs;
  var allMerchants = <Merchant>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  // Form controllers for add/edit merchant
  final merchantNameController = TextEditingController();
  final merchantAddressController = TextEditingController();
  final merchantContactController = TextEditingController();
  final merchantPaymentTermsController = TextEditingController();
  final searchController = TextEditingController();

  // Payment terms options
  final List<String> paymentTermsOptions = ['Cash', 'Card', 'UPI', 'Online'];
  var selectedPaymentTerms = 'Cash'.obs;

  @override
  void onInit() {
    super.onInit();
    loadMerchants();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.MERCHANT) {
      refreshMerchants();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Don't call loadMerchants again here since onInit already does it
  }

  void onResume() {
    refreshMerchants();
  }

  @override
  void onClose() {
    merchantNameController.dispose();
    merchantAddressController.dispose();
    merchantContactController.dispose();
    merchantPaymentTermsController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Load merchants from API with pagination
  Future<void> loadMerchants() async {
    try {
      isLoading.value = true;

      print(
          'Loading merchants - Page: ${currentPage.value}, Search: ${searchKeyword.value}');

      final response = await MerchantService.getAllMerchants(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
      );

      print('API Response: ${response}'); // Debug log

      if (response['success'] == true) {
        final data = response['data'];
        print('Response data: $data'); // Debug log

        if (data != null) {
          List<dynamic> merchantsData = [];

          // Handle different API response structures
          if (data is List) {
            // Data is directly a list of merchants
            merchantsData = data;
            totalCount.value = merchantsData.length;
            print('Data is List with ${merchantsData.length} items');
          } else if (data is Map) {
            // Data contains pagination info or nested structure
            if (data.containsKey('merchants')) {
              merchantsData = data['merchants'] ?? [];
            } else if (data.containsKey('results')) {
              merchantsData = data['results'] ?? [];
            } else if (data.containsKey('data')) {
              merchantsData = data['data'] ?? [];
            } else {
              // Fallback - try to use the map data directly if it looks like merchant data
              if (data.containsKey('name') || data.containsKey('id')) {
                merchantsData = [data];
              }
            }

            totalCount.value =
                data['total'] ?? data['count'] ?? merchantsData.length;
            hasNext.value = data['has_next'] ?? false;
            hasPrevious.value = data['has_previous'] ?? false;
            totalPages.value = data['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());

            print(
                'Data is Map - merchants count: ${merchantsData.length}, total: ${totalCount.value}');
          }

          // Convert to Merchant objects
          List<Merchant> merchants = [];
          for (var merchantData in merchantsData) {
            try {
              if (merchantData is Map<String, dynamic>) {
                final merchant = MerchantService.merchantFromJson(merchantData);
                merchants.add(merchant);
                print('Parsed merchant: ${merchant.name}');
              } else {
                print('Invalid merchant data format: ${merchantData}');
              }
            } catch (e) {
              print('Error parsing merchant: $e');
              print('Merchant data: $merchantData');
            }
          }

          filteredMerchants.value = merchants;
          allMerchants.value = merchants;

          print('Final merchants list count: ${filteredMerchants.length}');

          // Update pagination info if not already set
          if (totalPages.value <= 1) {
            totalPages.value = (totalCount.value / itemsPerPage).ceil();
          }
          hasPrevious.value = currentPage.value > 1;
          hasNext.value = currentPage.value < totalPages.value;
        } else {
          print('Response data is null');
          filteredMerchants.value = [];
          allMerchants.value = [];
          totalCount.value = 0;
        }
      } else {
        print('API response not successful: ${response}');
        CustomSnackbar.showError(
          title: 'Error',
          message: response['data']?['message'] ?? 'Failed to load merchants',
        );
        filteredMerchants.value = [];
        allMerchants.value = [];
        totalCount.value = 0;
      }
    } catch (e) {
      print('Error loading merchants: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading merchants: ${e.toString()}',
      );
      filteredMerchants.value = [];
      allMerchants.value = [];
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Search merchants
  void runFilter(String keyword) {
    print('Running filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1;
    loadMerchants();
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadMerchants();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadMerchants();
    }
  }

  List<Merchant> getPaginatedMerchants() {
    return filteredMerchants;
  }

  // Add new merchant
  Future<void> addMerchant() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare merchant data
      Map<String, dynamic> merchantData = {
        'name': merchantNameController.text.trim(),
        'address': merchantAddressController.text.trim(),
        'contact': merchantContactController.text.trim(),
        'payment_terms': selectedPaymentTerms.value,
      };

      // Validate merchant data
      final validationErrors = MerchantService.validateMerchantData(merchantData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Save merchant
      final response = await MerchantService.saveMerchant(
        merchantData: merchantData,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Merchant added successfully');

        // Clear form and refresh list
        clearForm();
        refreshMerchants();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to add merchant';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  // Update existing merchant
  Future<void> updateMerchant(String merchantId) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare merchant data
      Map<String, dynamic> merchantData = {
        'name': merchantNameController.text.trim(),
        'address': merchantAddressController.text.trim(),
        'contact': merchantContactController.text.trim(),
        'payment_terms': selectedPaymentTerms.value,
      };

      // Validate merchant data
      final validationErrors = MerchantService.validateMerchantData(merchantData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Update merchant
      final response = await MerchantService.updateMerchant(
        merchantId: merchantId,
        merchantData: merchantData,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Merchant updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshMerchants();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to update merchant';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  // Delete merchant
  Future<void> deleteMerchant(String merchantId) async {
    if (isDeleting.value) return;

    try {
      isDeleting.value = true;

      final response = await MerchantService.deleteMerchant(merchantId: merchantId);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Merchant deleted successfully');
        refreshMerchants();
      } else {
        String errorMessage = 'Failed to delete merchant';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isDeleting.value = false;
    }
  }

  // View merchant details
  void viewMerchant(Merchant merchant) {
    Get.dialog(
      AlertDialog(
        title: Text(merchant.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${merchant.id}'),
              SizedBox(height: 8),
              Text('Name: ${merchant.name}'),
              SizedBox(height: 8),
              Text('Address: ${merchant.address}'),
              SizedBox(height: 8),
              Text('Contact: ${merchant.contact}'),
              SizedBox(height: 8),
              Text('Payment Terms: ${merchant.paymentTerms}'),
              SizedBox(height: 8),
              
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Edit merchant - populate form with existing data
  Future<void> editMerchant(Merchant merchant) async {
    final result = await Get.to(() => MerchantScreen(), arguments: merchant);

    if (result != null && result['success'] == true) {
      // Refresh the merchants list
      refreshMerchants();
    }
  }

  Future<void> handleEditMerchant(Merchant merchant) async {
    print('🔍 DEBUG: handleEditMerchant called');
    print('🔍 DEBUG: Merchant ID: "${merchant.id}"');
    print('🔍 DEBUG: Merchant Name: "${merchant.name}"');
    print('🔍 DEBUG: Full merchant object: $merchant');
    try {
      isLoading.value = true;

      // First, fetch the latest merchant details from API
      final merchantDetails = await getMerchantDetails(merchant.id.toString());

      if (merchantDetails != null) {
        // Populate the form with existing data
        populateFormWithMerchantData(merchantDetails);

        // Navigate to edit screen with the merchant data
        final result = await Get.toNamed(Routes.EDIT_MERCHANT,
            arguments: {'merchant': merchantDetails, 'mode': 'edit'});

        // If edit was successful, refresh the list
        if (result != null && result['success'] == true) {
          refreshMerchants();
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to load merchant details: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with existing merchant data
  void populateFormWithMerchantData(Merchant merchant) {
    merchantNameController.text = merchant.name;
    merchantAddressController.text = merchant.address;
    merchantContactController.text = merchant.contact;
    selectedPaymentTerms.value = merchant.paymentTerms;
  }

  // Enhanced getMerchantDetails method with better error handling
  Future<Merchant?> getMerchantDetails(String merchantId) async {
    try {
      print('Fetching merchant details for ID: $merchantId');

      final response = await MerchantService.getMerchantById(merchantId);

      print('Get merchant details response: $response');

      if (response['success'] == true && response['data'] != null) {
        return MerchantService.merchantFromJson(response['data']);
      } else {
        String errorMessage = 'Failed to get merchant details';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error fetching merchant details: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error fetching merchant details: ${e.toString()}');
    }
    return null;
  }

  // Method to handle update from edit screen
  Future<void> handleUpdateMerchant(
      String merchantId, Map<String, dynamic> updatedData) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;
      print('Updating merchant $merchantId with data: $updatedData');

      // Validate merchant data
      final validationErrors = MerchantService.validateMerchantData(updatedData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Call the update API
      final response = await MerchantService.updateMerchant(
        merchantId: merchantId,
        merchantData: updatedData,
      );

      print('Update merchant response: $response');

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Merchant updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshMerchants();
        Get.back(result: {'success': true});
      } else {
        String errorMessage = 'Failed to update merchant';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error updating merchant: $e');
      CustomSnackbar.showError(
          title: 'Error', message: 'Error updating merchant: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  // Clear form
  void clearForm() {
    merchantNameController.clear();
    merchantAddressController.clear();
    merchantContactController.clear();
    merchantPaymentTermsController.clear();
    selectedPaymentTerms.value = 'Cash';
  }

  // Refresh merchants list
  Future<void> refreshMerchants() async {
    print('Refreshing merchants...');
    currentPage.value = 1;
    await loadMerchants();
  }

  // Clear search filter
  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    currentPage.value = 1;
    loadMerchants();
  }

  // Get summary text
  String getSummaryText() {
    return 'Total: ${totalCount.value} merchants';
  }

  // Format timestamp
  String formatTimestamp(dynamic date) {
    if (date == null) {
      return 'No Date';
    }

    DateTime? dateTime;

    try {
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        if (date.isEmpty) {
          return 'No Date';
        }
        dateTime = DateTime.parse(date);
      } else if (date is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return 'Invalid Date';
      }

      if (dateTime == null) {
        return 'No Date';
      }

      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error parsing date: $date, Error: $e');
      return 'Invalid Date';
    }
  }

  // Get payment terms display name
  String getPaymentTermsDisplayName(String paymentTerms) {
    return MerchantService.getPaymentTermsDisplayName(paymentTerms);
  }

  // Format contact number for display
  String formatContactNumber(String contact) {
    return MerchantService.formatContactNumber(contact);
  }
}