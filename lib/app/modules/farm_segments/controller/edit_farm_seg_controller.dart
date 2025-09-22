import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/farm_segments/farm_seg_models.dart';
import '../../../data/services/farm_segment/farm_seg_service.dart';

class FarmSegmentEditController extends GetxController {
  // Form key and controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController farmNameController = TextEditingController();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isEditMode = false.obs;
  final RxInt selectedIndex = 0.obs; // For bottom navigation

  // Farm segment data
  final Rx<FarmSegment?> currentFarmSegment = Rx<FarmSegment?>(null);
  String farmSegmentId = '';

  @override
  void onInit() {
    super.onInit();
    print('FarmSegmentEditController onInit started');

    final arguments = Get.arguments;
    print('🔍 Arguments received: $arguments');

    if (arguments != null && arguments is Map<String, dynamic>) {
      // Determine if this is edit mode
      if (arguments['mode'] == 'edit') {
        isEditMode.value = true;
      }

      // Handle farm segment ID passed as argument
      if (arguments.containsKey('farmSegmentId')) {
        final farmSegmentIdArg = arguments['farmSegmentId'] as String?;
        if (farmSegmentIdArg != null && farmSegmentIdArg.isNotEmpty) {
          print('🔍 Found farmSegmentId: $farmSegmentIdArg');
          farmSegmentId = farmSegmentIdArg;
          isEditMode.value = true;
          _loadFarmSegmentById(farmSegmentIdArg);
        } else {
          print('❌ Invalid farmSegmentId');
          _handleError('Invalid farm segment ID');
        }
      }
      // Handle farm segment object passed as argument
      else if (arguments.containsKey('farmSegment')) {
        final farmSegmentData = arguments['farmSegment'];

        if (farmSegmentData is FarmSegment) {
          print('🔍 FarmSegment object received: ${farmSegmentData.toString()}');

          // Validate farm segment data
          if (farmSegmentData.id.isEmpty) {
            print('❌ Farm Segment ID is empty, cannot edit');
            _handleError('Invalid farm segment data - missing ID');
            return;
          }

          farmSegmentId = farmSegmentData.id;
          isEditMode.value = true;

          // Always fetch fresh data from server for editing
          print('🔍 Fetching fresh data for farm segment ID: ${farmSegmentData.id}');
          _loadFarmSegmentById(farmSegmentData.id);
        } else {
          print('❌ Invalid farm segment object type');
          _handleError('Invalid farm segment data format');
        }
      } else {
        print('🔍 No existing farm segment data, creating new farm segment');
        isEditMode.value = false;
      }
    } else {
      print('🔍 No arguments provided, creating new farm segment');
      isEditMode.value = false;
    }

    print('🔍 onInit completed. Mode: ${isEditMode.value ? "Edit" : "Create"}');
  }

  // Method to load farm segment by ID
  Future<void> _loadFarmSegmentById(String id) async {
    try {
      isLoading.value = true;
      print('🔍 Loading farm segment with ID: $id');

      final result = await FarmSegmentService.getFarmSegmentById(id);
      print('🔍 API Result: $result');

      if (result['success'] == true) {
        final farmSegmentData = result['data'];
        print('🔍 Farm segment data received: $farmSegmentData');

        if (farmSegmentData != null && farmSegmentData is Map<String, dynamic>) {
          final farmSegment = FarmSegmentService.farmSegmentFromJson(farmSegmentData);
          _populateForm(farmSegment);
          print('✅ Farm segment loaded successfully: ${farmSegment.farmName}');
        } else {
          print('❌ Invalid farm segment data format from API');
          _handleError('Invalid farm segment data received from server');
        }
      } else {
        final errorMessage = result['data']?['message'] ??
            result['data']?['error'] ??
            'Failed to load farm segment data';
        print('❌ Failed to load farm segment: $errorMessage');
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error loading farm segment: $e');
      _handleError('Error loading farm segment data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with farm segment data
  void _populateForm(FarmSegment farmSegment) {
    currentFarmSegment.value = farmSegment;
    farmSegmentId = farmSegment.id;

    // Populate form fields
    farmNameController.text = farmSegment.farmName;

    print('🔍 Form populated successfully');
    print('🔍 Farm Name: ${farmSegment.farmName}');
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
  void navigateToViewFarmSegments() {
    // Navigate to view farm segments screen
    Get.toNamed('/view-farm-segments'); // Adjust route name as needed
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
        Get.offNamed('/farm-segments'); // Adjust route name as needed
        break;
      case 2:
        Get.offNamed('/profile'); // Adjust route name as needed
        break;
      // Add more cases as needed
    }
  }

  // Save farm segment method
  Future<void> saveFarmSegment() async {
    try {
      // Validate form
      if (!formKey.currentState!.validate()) {
        return;
      }

      isSaving.value = true;

      // Prepare farm segment data
      final farmSegmentData = {
        'farm_name': farmNameController.text.trim(),
      };

      // Validate farm segment data
      final validationErrors = FarmSegmentService.validateFarmSegmentData(farmSegmentData);
      if (validationErrors != null) {
        _showValidationErrors(validationErrors);
        return;
      }

      Map<String, dynamic> result;

      if (isEditMode.value && farmSegmentId.isNotEmpty) {
        // Update existing farm segment
        result = await FarmSegmentService.updateFarmSegment(
          farmSegmentId: farmSegmentId,
          farmSegmentData: farmSegmentData,
        );
      } else {
        // Create new farm segment
        result = await FarmSegmentService.saveFarmSegment(
          farmSegmentData: farmSegmentData,
        );
      }

      if (result['success'] == true) {
        final responseData = result['data'];
        String message = responseData['message'] ??
            (isEditMode.value
                ? 'Farm segment updated successfully'
                : 'Farm segment added successfully');

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
            'Failed to save farm segment';
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error saving farm segment: $e');
      _handleError('Error saving farm segment: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  bool _validateForm() {
    if (farmNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Farm name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (farmNameController.text.trim().length > 255) {
      Get.snackbar(
        'Validation Error',
        'Farm name must be less than 255 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
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

  

  @override
  void onClose() {
    farmNameController.dispose();
    super.onClose();
  }
}