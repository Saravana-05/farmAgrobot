import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/farm_segment/farm_seg_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class AddFarmSegmentController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var selectedIndex = 0.obs;

  // Text controllers
  final TextEditingController farmNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    farmNameController.dispose();
    super.onClose();
  }

  bool _validateForm() {
    if (farmNameController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter farm name');
      return false;
    }

    if (farmNameController.text.trim().length > 255) {
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Farm name must be less than 255 characters');
      return false;
    }

    return true;
  }

  void saveFarmSegment() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Prepare farm segment data
      Map<String, dynamic> farmSegmentData = {
        'farm_name': farmNameController.text.trim(),
      };

      // Validate farm segment data using service helper
      final validationErrors = FarmSegmentService.validateFarmSegmentData(farmSegmentData);
      if (validationErrors != null) {
        String errorMessage = validationErrors.values.first;
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Save farm segment using service
      Map<String, dynamic> result = await FarmSegmentService.saveFarmSegment(
        farmSegmentData: farmSegmentData,
      );

      if (result['success']) {
        String message = result['data']['message'] ?? 'Farm segment saved successfully';
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: message,
        );

        // Clear form
        _clearForm();

        // Wait for snackbar to show
        await Future.delayed(Duration(milliseconds: 1000));

        // Navigate back with success result
        Get.offAllNamed(Routes.FARM_SEGMENT, arguments: true);
      } else {
        String errorMessage =
            result['data']['message'] ?? 'Failed to save farm segment';
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    farmNameController.clear();
  }

  void navigateToViewFarmSegments() {
    Get.toNamed(Routes.FARM_SEGMENT);
  }

  void navigateToAddFarmSegments() {
    Get.toNamed(Routes.ADD_FARM_SEGMENT);
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
    return farmNameController.text.trim().isNotEmpty;
  }

  // Method to handle back navigation with confirmation
  void handleBackNavigation() {
    if (hasChanges) {
      Get.dialog(
        AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
              'You have unsaved changes. Do you want to discard them?'),
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
}