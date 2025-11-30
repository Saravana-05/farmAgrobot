import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../data/services/crops/crop_service.dart';

class CropEditController extends GetxController {
  // Form key and controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController cropNameController = TextEditingController();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isEditMode = false.obs;
  final RxBool hasExistingImage = false.obs;
  final RxBool removeExistingImage = false.obs;
  final RxInt selectedIndex = 0.obs; // For bottom navigation

  // Image handling
  final Rx<File?> selectedImageFile = Rx<File?>(null);
  final RxString? selectedImageUrl = RxString('');
  final ImagePicker _picker = ImagePicker();

  // Crop data
  final Rx<Crop?> currentCrop = Rx<Crop?>(null);
  String cropId = '';

  @override
  void onInit() {
    super.onInit();
    print('CropEditController onInit started');

    final arguments = Get.arguments;
    print('🔍 Arguments received: $arguments');

    if (arguments != null && arguments is Map<String, dynamic>) {
      // Determine if this is edit mode
      if (arguments['mode'] == 'edit') {
        isEditMode.value = true;
      }

      // Handle crop ID passed as argument
      if (arguments.containsKey('cropId')) {
        final cropIdArg = arguments['cropId'] as String?;
        if (cropIdArg != null && cropIdArg.isNotEmpty) {
          print('🔍 Found cropId: $cropIdArg');
          cropId = cropIdArg;
          isEditMode.value = true;
          _loadCropById(cropIdArg);
        } else {
          print('❌ Invalid cropId');
          _handleError('Invalid crop ID');
        }
      }
      // Handle crop object passed as argument
      else if (arguments.containsKey('crop')) {
        final cropData = arguments['crop'];

        if (cropData is Crop) {
          print('🔍 Crop object received: ${cropData.toString()}');

          // Validate crop data
          if (cropData.id.isEmpty) {
            print('❌ Crop ID is empty, cannot edit');
            _handleError('Invalid crop data - missing ID');
            return;
          }

          cropId = cropData.id;
          isEditMode.value = true;

          // Always fetch fresh data from server for editing
          print('🔍 Fetching fresh data for crop ID: ${cropData.id}');
          _loadCropById(cropData.id);
        } else {
          print('❌ Invalid crop object type');
          _handleError('Invalid crop data format');
        }
      } else {
        print('🔍 No existing crop data, creating new crop');
        isEditMode.value = false;
      }
    } else {
      print('🔍 No arguments provided, creating new crop');
      isEditMode.value = false;
    }

    print('🔍 onInit completed. Mode: ${isEditMode.value ? "Edit" : "Create"}');
  }

  // Method to load crop by ID
  Future<void> _loadCropById(String id) async {
    try {
      isLoading.value = true;
      print('🔍 Loading crop with ID: $id');

      final result = await CropService.getCropById(id);
      print('🔍 API Result: $result');

      if (result['success'] == true) {
        final cropData = result['data'];
        print('🔍 Crop data received: $cropData');

        if (cropData != null && cropData is Map<String, dynamic>) {
          final crop = CropService.cropFromJson(cropData);
          _populateForm(crop);
          print('✅ Crop loaded successfully: ${crop.cropName}');
        } else {
          print('❌ Invalid crop data format from API');
          _handleError('Invalid crop data received from server');
        }
      } else {
        final errorMessage = result['data']?['message'] ??
            result['data']?['error'] ??
            'Failed to load crop data';
        print('❌ Failed to load crop: $errorMessage');
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error loading crop: $e');
      _handleError('Error loading crop data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with crop data
  void _populateForm(Crop crop) {
    currentCrop.value = crop;
    cropId = crop.id;

    // Populate form fields
    cropNameController.text = crop.cropName;

    // Handle image
    if (crop.hasImage) {
      if (crop.imageUrl != null && crop.imageUrl!.isNotEmpty) {
        selectedImageUrl?.value = crop.imageUrl!;
        hasExistingImage.value = true;
        print('🔍 Image URL set: ${crop.imageUrl}');
      } else if (crop.cropImage != null && crop.cropImage!.isNotEmpty) {
        // Fallback to cropImage if imageUrl is not available
        selectedImageUrl?.value = crop.cropImage!;
        hasExistingImage.value = true;
        print('🔍 Using crop_image as URL: ${crop.cropImage}');
      }
    } else {
      selectedImageUrl?.value = '';
      hasExistingImage.value = false;
      print('🔍 No image for this crop');
    }

    print('🔍 Form populated successfully');
    print('🔍 Crop Name: ${crop.cropName}');
    print('🔍 Has Image: ${crop.hasImage}');
    print('🔍 Image URL: ${selectedImageUrl?.value}');
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
  void navigateToViewCrops() {
    // Navigate to view crops screen
    Get.toNamed('/view-crops'); // Adjust route name as needed
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
        Get.offNamed('/crops'); // Adjust route name as needed
        break;
      case 2:
        Get.offNamed('/profile'); // Adjust route name as needed
        break;
      // Add more cases as needed
    }
  }

  // Image picker methods
  void showImagePickerOptions() {
    if (isUploading.value) return;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      pickImageFromCamera();
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.camera_alt, size: 50, color: Colors.blue),
                        SizedBox(height: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      pickImageFromGallery();
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.photo_library,
                            size: 50, color: Colors.green),
                        SizedBox(height: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickImageFromCamera() async {
    try {
      isUploading.value = true;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        selectedImageFile.value = File(image.path);
        removeExistingImage.value = false;
        print('🔍 Image selected from camera: ${image.path}');
      }
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      Get.snackbar(
        'Error',
        'Failed to capture image from camera',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      isUploading.value = true;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        selectedImageFile.value = File(image.path);
        removeExistingImage.value = false;
        print('🔍 Image selected from gallery: ${image.path}');
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  void toggleRemoveExistingImage() {
    removeExistingImage.value = !removeExistingImage.value;
    print('🔍 Toggle remove existing image: ${removeExistingImage.value}');
  }

  void removeSelectedImage() {
    selectedImageFile.value = null;
    print('🔍 Selected image removed');
  }

  // Save crop method
  Future<void> saveCrop() async {
    try {
      // Validate form
      if (!formKey.currentState!.validate()) {
        return;
      }

      isSaving.value = true;

      // Prepare crop data
      final cropData = {
        'crop_name': cropNameController.text.trim(),
      };

      // Validate crop data
      final validationErrors = CropService.validateCropData(cropData);
      if (validationErrors != null) {
        _showValidationErrors(validationErrors);
        return;
      }

      Map<String, dynamic> result;

      if (isEditMode.value && cropId.isNotEmpty) {
        // Update existing crop
        result = await CropService.updateCrop(
          cropId: cropId,
          cropData: cropData,
          imageFile: selectedImageFile.value,
          removeImage: removeExistingImage.value,
        );
      } else {
        // Create new crop
        result = await CropService.saveCrop(
          cropData: cropData,
          imageFile: selectedImageFile.value,
        );
      }

      if (result['success'] == true) {
        final responseData = result['data'];
        String message = responseData['message'] ??
            (isEditMode.value
                ? 'Crop updated successfully'
                : 'Crop added successfully');

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
            'Failed to save crop';
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error saving crop: $e');
      _handleError('Error saving crop: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  bool _validateForm() {
    if (cropNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Crop name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    // Validate image file if selected
    if (selectedImageFile.value != null) {
      if (!CropService.isValidImageFile(selectedImageFile.value)) {
        Get.snackbar(
          'Validation Error',
          'Please select a valid image file (JPG, PNG, GIF, WebP)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      if (!CropService.isValidImageSize(selectedImageFile.value)) {
        Get.snackbar(
          'Validation Error',
          'Image size must be less than 10MB',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    }

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

  // Method to test API connection
  Future<void> testApiConnection() async {
    try {
      print('🔍 Testing API connection...');

      // Test with minimal data
      final testData = {
        'crop_name': 'Test Crop ${DateTime.now().millisecondsSinceEpoch}',
      };

      final result = await CropService.saveCrop(
        cropData: testData,
        imageFile: null,
      );

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
          'API returned error: ${result['message'] ?? 'Unknown error'}',
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
  bool get hasSelectedImage => selectedImageFile.value != null;
  bool get hasAnyImage =>
      hasSelectedImage ||
      (hasExistingImage.value && !removeExistingImage.value);
  String get imageDisplayUrl => selectedImageUrl?.value ?? '';

  @override
  void onClose() {
    cropNameController.dispose();
    super.onClose();
  }
}
