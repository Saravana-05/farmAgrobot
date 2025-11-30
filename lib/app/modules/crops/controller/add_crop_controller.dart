import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/crops/crop_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class AddCropsController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var image = Rxn<Uint8List>();
  var selectedIndex = 0.obs;
  var isUploading = false.obs;

  // Text controllers
  final TextEditingController cropNameController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    cropNameController.dispose();
    super.onClose();
  }

  void selectImage() {
    Get.dialog(
      AlertDialog(
        title: const Text('Choose an option'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              GestureDetector(
                child: const Text('Camera'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.camera);
                },
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              GestureDetector(
                child: const Text('Gallery'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      isUploading.value = true;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        CustomSnackbar.showInfo(title: 'Info', message: 'No image selected');
        return;
      }

      _imageFile = File(pickedFile.path);

      // Validate image file type
      if (!CropService.isValidImageFile(_imageFile)) {
        CustomSnackbar.showError(
          title: 'Error',
          message:
              'Please select a valid image file (jpg, jpeg, png, gif, webp)',
        );
        _imageFile = null;
        return;
      }

      // Validate image file size
      if (!CropService.isValidImageSize(_imageFile)) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Image size should be less than 10MB',
        );
        _imageFile = null;
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();

      // Set the image directly
      image.value = imageBytes;

      CustomSnackbar.showInfo(
          title: 'Info', message: 'Image selected successfully');
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  void removeImage() {
    image.value = null;
    _imageFile = null;
    CustomSnackbar.showInfo(title: 'Info', message: 'Image removed');
  }

  bool _validateForm() {
    if (cropNameController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter crop name');
      return false;
    }

    if (cropNameController.text.trim().length > 255) {
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Crop name must be less than 255 characters');
      return false;
    }

    return true;
  }

  void saveCrop() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Prepare crop data
      Map<String, dynamic> cropData = {
        'crop_name': cropNameController.text.trim(),
      };

      // Validate crop data using service helper
      final validationErrors = CropService.validateCropData(cropData);
      if (validationErrors != null) {
        String errorMessage = validationErrors.values.first;
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Save crop using service
      Map<String, dynamic> result = await CropService.saveCrop(
        cropData: cropData,
        imageFile: _imageFile,
        imageBytes: image.value,
      );

      if (result['success']) {
        String message = result['data']['message'] ?? 'Crop saved successfully';
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: message,
        );

        // Clear form
        _clearForm();

        // Wait for snackbar to show
        await Future.delayed(Duration(milliseconds: 1000));

        // Navigate back with success result
        Get.offAllNamed(Routes.CROPS, arguments: true);
      } else {
        String errorMessage =
            result['data']['message'] ?? 'Failed to save crop';
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    cropNameController.clear();
    image.value = null;
    _imageFile = null;
  }

  void navigateToViewCrops() {
    Get.toNamed(Routes.CROPS);
  }

  void navigateToAddCrops() {
    Get.toNamed(Routes.ADD_CROPS);
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

  // Helper method to get image display widget
  Widget? getImageWidget() {
    if (image.value != null) {
      return Image.memory(
        image.value!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  // Helper method to check if form has changes
  bool get hasChanges {
    return cropNameController.text.trim().isNotEmpty || image.value != null;
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
