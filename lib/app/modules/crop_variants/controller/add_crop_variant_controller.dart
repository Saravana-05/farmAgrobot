import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../data/services/crop_variant/crop_variant_service.dart';
import '../../../data/services/crops/crop_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';


class AddCropVariantController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var isLoadingCrops = false.obs;
  var selectedIndex = 0.obs;
  var selectedCrop = Rxn<Crop>();
  var selectedUnit = 'Pieces'.obs;

  // Text controllers
  final TextEditingController cropVariantController = TextEditingController();

  // Dropdown data
  var crops = <Crop>[].obs;
  final List<String> availableUnits = CropVariantService.getAvailableUnits();

  @override
  void onInit() {
    super.onInit();
    loadCrops();
  }

  @override
  void onClose() {
    cropVariantController.dispose();
    super.onClose();
  }

  Future<void> loadCrops() async {
    try {
      isLoadingCrops.value = true;
      
      final result = await CropService.getAllCrops();
      
      if (result['success']) {
        final cropList = CropService.cropListFromJson(result['data']);
        crops.value = cropList;
      } else {
        CustomSnackbar.showError(
          title: 'Error',
          message: result['data']['message'] ?? 'Failed to load crops',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load crops: ${e.toString()}',
      );
    } finally {
      isLoadingCrops.value = false;
    }
  }

  void onCropSelected(Crop? crop) {
    selectedCrop.value = crop;
  }

  void onUnitSelected(String? unit) {
    if (unit != null) {
      selectedUnit.value = unit;
    }
  }

  bool _validateForm() {
    if (selectedCrop.value == null) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select a crop',
      );
      return false;
    }

    if (cropVariantController.text.trim().isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please enter crop variant name',
      );
      return false;
    }

    if (cropVariantController.text.trim().length > 100) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Crop variant name must be less than 100 characters',
      );
      return false;
    }

    if (selectedUnit.value.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select a unit',
      );
      return false;
    }

    return true;
  }

  void saveCropVariant() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Prepare crop variant data
      Map<String, dynamic> cropVariantData = {
        'crop': selectedCrop.value!.id,
        'crop_variant': cropVariantController.text.trim(),
        'unit': selectedUnit.value,
      };

      // Validate crop variant data using service helper
      final validationErrors = CropVariantService.validateCropVariantData(cropVariantData);
      if (validationErrors != null) {
        String errorMessage = validationErrors.values.first;
        CustomSnackbar.showError(
          title: 'Validation Error',
          message: errorMessage,
        );
        return;
      }

      // Save crop variant using service
      Map<String, dynamic> result = await CropVariantService.saveCropVariant(
        cropVariantData: cropVariantData,
      );

      if (result['success']) {
        String message = result['data']['message'] ?? 'Crop variant saved successfully';
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: message,
        );

        // Clear form
        _clearForm();

        // Wait for snackbar to show
        await Future.delayed(Duration(milliseconds: 1000));

        // Navigate back with success result
        Get.offAllNamed(Routes.CROPS_VARIANTS, arguments: true);
      } else {
        String errorMessage = result['data']['message'] ?? 'Failed to save crop variant';
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    cropVariantController.clear();
    selectedCrop.value = null;
    selectedUnit.value = 'Pieces';
  }

  void navigateToViewCropVariants() {
    Get.toNamed(Routes.CROPS_VARIANTS);
  }

  void navigateToAddCropVariants() {
    Get.toNamed(Routes.CROPS_VARIANTS);
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

  // Helper method to check if form has changes
  bool get hasChanges {
    return cropVariantController.text.trim().isNotEmpty || 
           selectedCrop.value != null ||
           selectedUnit.value != 'Pieces';
  }

  // Method to handle back navigation with confirmation
  void handleBackNavigation() {
    if (hasChanges) {
      Get.dialog(
        AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Do you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                _clearForm();
                Get.back(); // Go back to previous screen
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  // Helper method to get unit display name
  String getUnitDisplayName(String unit) {
    return CropVariantService.getUnitDisplayName(unit);
  }

  // Method to refresh crops list
  Future<void> refreshCrops() async {
    await loadCrops();
  }
}