import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/crop_variant/crop_variant_model.dart';
import '../../../data/services/crop_variant/crop_variant_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class CropVariantViewController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var filteredCropVariants = <CropVariant>[].obs;
  var allCropVariants = <CropVariant>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  // Form controllers for add/edit crop variant
  final cropVariantNameController = TextEditingController();
  final searchController = TextEditingController();
  final cropIdController = TextEditingController();
  final unitController = TextEditingController();

  // Selected values
  var selectedCropId = ''.obs;
  var selectedUnit = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCropVariants();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.CROPS_VARIANTS) {
      refreshCropVariants();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Don't call loadCropVariants again here since onInit already does it
  }

  void onResume() {
    refreshCropVariants();
  }

  @override
  void onClose() {
    cropVariantNameController.dispose();
    searchController.dispose();
    cropIdController.dispose();
    unitController.dispose();
    super.onClose();
  }

  // Load crop variants from API with pagination
  Future<void> loadCropVariants() async {
    try {
      isLoading.value = true;

      print(
          'Loading crop variants - Page: ${currentPage.value}, Search: ${searchKeyword.value}');

      final response = await CropVariantService.getAllCropVariants(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
      );

      print('API Response: ${response}'); // Debug log

      if (response['success'] == true) {
        final data = response['data'];
        print('Response data: $data'); // Debug log

        if (data != null) {
          List<dynamic> cropVariantsData = [];

          // Handle different API response structures
          if (data is List) {
            // Data is directly a list of crop variants
            cropVariantsData = data;
            totalCount.value = cropVariantsData.length;
            print('Data is List with ${cropVariantsData.length} items');
          } else if (data is Map) {
            // Data contains pagination info or nested structure
            if (data.containsKey('crop_variants')) {
              cropVariantsData = data['crop_variants'] ?? [];
            } else if (data.containsKey('results')) {
              cropVariantsData = data['results'] ?? [];
            } else if (data.containsKey('data')) {
              cropVariantsData = data['data'] ?? [];
            } else {
              // Fallback - try to use the map data directly if it looks like crop variant data
              if (data.containsKey('crop_variant') || data.containsKey('id')) {
                cropVariantsData = [data];
              }
            }

            totalCount.value =
                data['total'] ?? data['count'] ?? cropVariantsData.length;
            hasNext.value = data['has_next'] ?? false;
            hasPrevious.value = data['has_previous'] ?? false;
            totalPages.value = data['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());

            print(
                'Data is Map - crop variants count: ${cropVariantsData.length}, total: ${totalCount.value}');
          }

          // Convert to CropVariant objects
          List<CropVariant> cropVariants = [];
          for (var cropVariantData in cropVariantsData) {
            try {
              if (cropVariantData is Map<String, dynamic>) {
                final cropVariant =
                    CropVariantService.cropVariantFromJson(cropVariantData);
                cropVariants.add(cropVariant);
                print('Parsed crop variant: ${cropVariant.cropVariant}');
              } else {
                print('Invalid crop variant data format: ${cropVariantData}');
              }
            } catch (e) {
              print('Error parsing crop variant: $e');
              print('Crop variant data: $cropVariantData');
            }
          }

          filteredCropVariants.value = cropVariants;
          allCropVariants.value = cropVariants;

          print(
              'Final crop variants list count: ${filteredCropVariants.length}');

          // Update pagination info if not already set
          if (totalPages.value <= 1) {
            totalPages.value = (totalCount.value / itemsPerPage).ceil();
          }
          hasPrevious.value = currentPage.value > 1;
          hasNext.value = currentPage.value < totalPages.value;
        } else {
          print('Response data is null');
          filteredCropVariants.value = [];
          allCropVariants.value = [];
          totalCount.value = 0;
        }
      } else {
        print('API response not successful: ${response}');
        CustomSnackbar.showError(
          title: 'Error',
          message:
              response['data']?['message'] ?? 'Failed to load crop variants',
        );
        filteredCropVariants.value = [];
        allCropVariants.value = [];
        totalCount.value = 0;
      }
    } catch (e) {
      print('Error loading crop variants: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading crop variants: ${e.toString()}',
      );
      filteredCropVariants.value = [];
      allCropVariants.value = [];
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Search crop variants
  void runFilter(String keyword) {
    print('Running filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1;
    loadCropVariants();
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadCropVariants();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadCropVariants();
    }
  }

  List<CropVariant> getPaginatedCropVariants() {
    return filteredCropVariants;
  }

  // Add new crop variant
  Future<void> addCropVariant() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare crop variant data
      Map<String, dynamic> cropVariantData = {
        'crop': selectedCropId.value,
        'crop_variant': cropVariantNameController.text.trim(),
        'unit': selectedUnit.value,
      };

      // Validate crop variant data
      final validationErrors =
          CropVariantService.validateCropVariantData(cropVariantData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Save crop variant
      final response = await CropVariantService.saveCropVariant(
        cropVariantData: cropVariantData,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop variant added successfully');

        // Clear form and refresh list
        clearForm();
        refreshCropVariants();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to add crop variant';
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

  // Update existing crop variant
  Future<void> updateCropVariant(String cropVariantId) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare crop variant data
      Map<String, dynamic> cropVariantData = {
        'crop': selectedCropId.value,
        'crop_variant': cropVariantNameController.text.trim(),
        'unit': selectedUnit.value,
      };

      // Validate crop variant data
      final validationErrors =
          CropVariantService.validateCropVariantData(cropVariantData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Update crop variant
      final response = await CropVariantService.updateCropVariant(
        variantId: cropVariantId,
        cropVariantData: cropVariantData,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop variant updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshCropVariants();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to update crop variant';
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

  // Delete crop variant
  Future<void> deleteCropVariant(String cropVariantId) async {
    if (isDeleting.value) return;

    try {
      isDeleting.value = true;

      final response =
          await CropVariantService.deleteCropVariant(variantId: cropVariantId);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop variant deleted successfully');
        refreshCropVariants();
      } else {
        String errorMessage = 'Failed to delete crop variant';
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

  // Edit crop variant - populate form with existing data
  Future<void> handleEditCropVariant(CropVariant cropVariant) async {
    print('🔍 DEBUG: handleEditCropVariant called');
    print('🔍 DEBUG: CropVariant ID: "${cropVariant.id}"');
    print('🔍 DEBUG: CropVariant Name: "${cropVariant.cropVariant}"');
    print('🔍 DEBUG: Full crop variant object: $cropVariant');

    try {
      isLoading.value = true;

      // First, fetch the latest crop variant details from API
      final cropVariantDetails =
          await getCropVariantDetails(cropVariant.id.toString());

      if (cropVariantDetails != null) {
        // Populate the form with existing data
        populateFormWithCropVariantData(cropVariantDetails);

        // Navigate to edit screen with the crop variant data
        final result = await Get.toNamed(Routes.EDIT_CROPS_VARIANTS,
            arguments: {'cropVariant': cropVariantDetails, 'mode': 'edit'});

        // If edit was successful, refresh the list
        if (result != null && result['success'] == true) {
          refreshCropVariants();
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to load crop variant details: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with existing crop variant data
  void populateFormWithCropVariantData(CropVariant cropVariant) {
    cropVariantNameController.text = cropVariant.cropVariant;
    selectedCropId.value = cropVariant.cropId;
    selectedUnit.value = cropVariant.unit;
  }

  // Enhanced getCropVariantDetails method with better error handling
  Future<CropVariant?> getCropVariantDetails(String cropVariantId) async {
    try {
      print('Fetching crop variant details for ID: $cropVariantId');

      final response =
          await CropVariantService.getCropVariantById(cropVariantId);

      print('Get crop variant details response: $response');

      if (response['success'] == true && response['data'] != null) {
        return CropVariantService.cropVariantFromJson(response['data']);
      } else {
        String errorMessage = 'Failed to get crop variant details';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error fetching crop variant details: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error fetching crop variant details: ${e.toString()}');
    }
    return null;
  }

  // Method to handle update from edit screen
  Future<void> handleUpdateCropVariant(
      String cropVariantId, Map<String, dynamic> updatedData) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;
      print('Updating crop variant $cropVariantId with data: $updatedData');

      // Validate crop variant data
      final validationErrors =
          CropVariantService.validateCropVariantData(updatedData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Call the update API
      final response = await CropVariantService.updateCropVariant(
        variantId: cropVariantId,
        cropVariantData: updatedData,
      );

      print('Update crop variant response: $response');

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop variant updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshCropVariants();
        Get.back(result: {'success': true});
      } else {
        String errorMessage = 'Failed to update crop variant';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error updating crop variant: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error updating crop variant: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  // Clear form
  void clearForm() {
    cropVariantNameController.clear();
    selectedCropId.value = '';
    selectedUnit.value = '';
  }

  // Refresh crop variants list
  Future<void> refreshCropVariants() async {
    print('Refreshing crop variants...');
    currentPage.value = 1;
    await loadCropVariants();
  }

  // Clear search filter
  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    currentPage.value = 1;
    loadCropVariants();
  }

  // Get summary text
  String getSummaryText() {
    return 'Total: ${totalCount.value} crop variants';
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

  // Get available units
  List<String> getAvailableUnits() {
    return CropVariantService.getAvailableUnits();
  }

  // Get unit display name
  String getUnitDisplayName(String unit) {
    return CropVariantService.getUnitDisplayName(unit);
  }
}
