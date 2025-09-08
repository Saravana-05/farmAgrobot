import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/crop_variant/crop_variant_model.dart';
import '../../../data/services/crop_variant/crop_variant_service.dart';

class CropVariantEditController extends GetxController {
  // Form key and controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController cropVariantController = TextEditingController();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isEditMode = false.obs;
  final RxInt selectedIndex = 0.obs; // For bottom navigation

  // Unit dropdown
  final RxString selectedUnit = ''.obs;
  final RxList<String> availableUnits = <String>[].obs;

  // Crop selection
  final RxString selectedCropId = ''.obs;
  final RxString selectedCropName = ''.obs;
  final RxList<Map<String, dynamic>> availableCrops = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingCrops = false.obs; // Loading state for crops

  // Crop variant data
  final Rx<CropVariant?> currentCropVariant = Rx<CropVariant?>(null);
  String cropVariantId = '';

  @override
  void onInit() {
    super.onInit();
    print('CropVariantEditController onInit started');

    // Initialize available units
    availableUnits.value = CropVariantService.getAvailableUnits();

    // Load available crops
    _loadAvailableCrops();

    final arguments = Get.arguments;
    print('🔍 Arguments received: $arguments');

    if (arguments != null && arguments is Map<String, dynamic>) {
      // Determine if this is edit mode
      if (arguments['mode'] == 'edit') {
        isEditMode.value = true;
      }

      // Handle crop variant ID passed as argument
      if (arguments.containsKey('cropVariantId')) {
        final cropVariantIdArg = arguments['cropVariantId'] as String?;
        if (cropVariantIdArg != null && cropVariantIdArg.isNotEmpty) {
          print('🔍 Found cropVariantId: $cropVariantIdArg');
          cropVariantId = cropVariantIdArg;
          isEditMode.value = true;
          _loadCropVariantById(cropVariantIdArg);
        } else {
          print('❌ Invalid cropVariantId');
          _handleError('Invalid crop variant ID');
        }
      }
      // Handle crop variant object passed as argument
      else if (arguments.containsKey('cropVariant')) {
        final cropVariantData = arguments['cropVariant'];

        if (cropVariantData is CropVariant) {
          print('🔍 CropVariant object received: ${cropVariantData.toString()}');

          // Validate crop variant data
          if (cropVariantData.id.isEmpty) {
            print('❌ CropVariant ID is empty, cannot edit');
            _handleError('Invalid crop variant data - missing ID');
            return;
          }

          cropVariantId = cropVariantData.id;
          isEditMode.value = true;

          // Always fetch fresh data from server for editing
          print('🔍 Fetching fresh data for crop variant ID: ${cropVariantData.id}');
          _loadCropVariantById(cropVariantData.id);
        } else {
          print('❌ Invalid crop variant object type');
          _handleError('Invalid crop variant data format');
        }
      }
      // Handle pre-selected crop for new variant
      else if (arguments.containsKey('cropId')) {
        final cropIdArg = arguments['cropId'] as String?;
        final cropNameArg = arguments['cropName'] as String?;
        if (cropIdArg != null && cropIdArg.isNotEmpty) {
          selectedCropId.value = cropIdArg;
          selectedCropName.value = cropNameArg ?? '';
          print('🔍 Pre-selected crop: $cropIdArg - $cropNameArg');
        }
        isEditMode.value = false;
      } else {
        print('🔍 No existing crop variant data, creating new crop variant');
        isEditMode.value = false;
      }
    } else {
      print('🔍 No arguments provided, creating new crop variant');
      isEditMode.value = false;
    }

    // Set default unit if not in edit mode
    if (!isEditMode.value && availableUnits.isNotEmpty) {
      selectedUnit.value = availableUnits.first;
    }

    print('🔍 onInit completed. Mode: ${isEditMode.value ? "Edit" : "Create"}');
  }

  // Method to load available crops
  Future<void> _loadAvailableCrops() async {
    try {
      isLoadingCrops.value = true;
      print('🔍 Loading available crops...');

      final result = await CropVariantService.getAllCrops();
      print('🔍 Crops API Result: $result');

      if (result['success'] == true) {
        final cropsData = result['data'];
        print('🔍 Crops data received: $cropsData');

        if (cropsData != null) {
          // Handle different response structures
          List<dynamic> cropsList = [];
          
          if (cropsData is List) {
            cropsList = cropsData;
          } else if (cropsData is Map && cropsData.containsKey('data')) {
            cropsList = cropsData['data'] ?? [];
          } else if (cropsData is Map && cropsData.containsKey('crops')) {
            cropsList = cropsData['crops'] ?? [];
          }

          // Convert to the format expected by the UI
          availableCrops.value = cropsList.map<Map<String, dynamic>>((crop) {
            return {
              'id': crop['id']?.toString() ?? '',
              'name': crop['crop_name'] ?? crop['name'] ?? '',
            };
          }).toList();

          print('✅ Available crops loaded: ${availableCrops.length} crops');
        } else {
          print('❌ No crops data received');
          availableCrops.clear();
        }
      } else {
        final errorMessage = result['data']?['message'] ??
            result['data']?['error'] ??
            'Failed to load crops';
        print('❌ Failed to load crops: $errorMessage');
        Get.snackbar(
          'Warning',
          'Failed to load crops: $errorMessage',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error loading crops: $e');
      Get.snackbar(
        'Warning',
        'Error loading crops: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      isLoadingCrops.value = false;
    }
  }

  // Method to load crop variant by ID
  Future<void> _loadCropVariantById(String id) async {
    try {
      isLoading.value = true;
      print('🔍 Loading crop variant with ID: $id');

      final result = await CropVariantService.getCropVariantById(id);
      print('🔍 API Result: $result');

      if (result['success'] == true) {
        final cropVariantData = result['data'];
        print('🔍 Crop variant data received: $cropVariantData');

        if (cropVariantData != null && cropVariantData is Map<String, dynamic>) {
          final cropVariant = CropVariantService.cropVariantFromJson(cropVariantData);
          _populateForm(cropVariant);
          print('✅ Crop variant loaded successfully: ${cropVariant.cropVariant}');
        } else {
          print('❌ Invalid crop variant data format from API');
          _handleError('Invalid crop variant data received from server');
        }
      } else {
        final errorMessage = result['data']?['message'] ??
            result['data']?['error'] ??
            'Failed to load crop variant data';
        print('❌ Failed to load crop variant: $errorMessage');
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error loading crop variant: $e');
      _handleError('Error loading crop variant data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with crop variant data
  void _populateForm(CropVariant cropVariant) {
    currentCropVariant.value = cropVariant;
    cropVariantId = cropVariant.id;

    // Populate form fields
    cropVariantController.text = cropVariant.cropVariant;
    selectedUnit.value = cropVariant.unit;
    selectedCropId.value = cropVariant.cropId;
    selectedCropName.value = cropVariant.cropName;

    print('🔍 Form populated successfully');
    print('🔍 Crop Variant: ${cropVariant.cropVariant}');
    print('🔍 Unit: ${cropVariant.unit}');
    print('🔍 Crop: ${cropVariant.cropName}');
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
  void navigateToViewCropVariants() {
    Get.toNamed('/view-crop-variants');
  }

  void navigateToTab(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.offNamed('/home');
        break;
      case 1:
        Get.offNamed('/crops');
        break;
      case 2:
        Get.offNamed('/profile');
        break;
    }
  }

  // Unit selection method
  void selectUnit(String unit) {
    selectedUnit.value = unit;
    print('🔍 Unit selected: $unit');
  }

  // Crop selection method - Updated to work with dropdown
  void selectCrop(String cropId, String cropName) {
    selectedCropId.value = cropId;
    selectedCropName.value = cropName;
    print('🔍 Crop selected: $cropId - $cropName');
  }

  // Method to refresh crops list
  Future<void> refreshCrops() async {
    await _loadAvailableCrops();
  }

  // Save crop variant method
  Future<void> saveCropVariant() async {
    try {
      // Validate form
      if (!formKey.currentState!.validate()) {
        return;
      }

      // Additional validation
      if (!_validateForm()) {
        return;
      }

      isSaving.value = true;

      // Prepare crop variant data
      final cropVariantData = {
        'crop': selectedCropId.value,
        'crop_variant': cropVariantController.text.trim(),
        'unit': selectedUnit.value,
      };

      // Validate crop variant data
      final validationErrors = CropVariantService.validateCropVariantData(cropVariantData);
      if (validationErrors != null) {
        _showValidationErrors(validationErrors);
        return;
      }

      Map<String, dynamic> result;

      if (isEditMode.value && cropVariantId.isNotEmpty) {
        // Update existing crop variant
        result = await CropVariantService.updateCropVariant(
          variantId: cropVariantId,
          cropVariantData: cropVariantData,
        );
      } else {
        // Create new crop variant
        result = await CropVariantService.saveCropVariant(
          cropVariantData: cropVariantData,
        );
      }

      if (result['success'] == true) {
        final responseData = result['data'];
        String message = responseData['message'] ??
            (isEditMode.value
                ? 'Crop variant updated successfully'
                : 'Crop variant added successfully');

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
            'Failed to save crop variant';
        _handleError(errorMessage);
      }
    } catch (e) {
      print('❌ Error saving crop variant: $e');
      _handleError('Error saving crop variant: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  bool _validateForm() {
    if (cropVariantController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Crop variant name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedCropId.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select a crop',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedUnit.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select a unit',
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

  // Method to test API connection
  Future<void> testApiConnection() async {
    try {
      print('🔍 Testing API connection...');

      final testData = {
        'crop': '1',
        'crop_variant': 'Test Variant ${DateTime.now().millisecondsSinceEpoch}',
        'unit': 'Pieces',
      };

      final result = await CropVariantService.saveCropVariant(
        cropVariantData: testData,
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
  String get unitDisplayName => CropVariantService.getUnitDisplayName(selectedUnit.value);
  bool get hasCropSelected => selectedCropId.value.isNotEmpty;
  bool get hasValidData => cropVariantController.text.trim().isNotEmpty && 
                          selectedCropId.value.isNotEmpty && 
                          selectedUnit.value.isNotEmpty;
  
  // New getter for crop dropdown
  Map<String, dynamic>? get selectedCrop {
    if (selectedCropId.value.isEmpty) return null;
    return availableCrops.firstWhereOrNull(
      (crop) => crop['id'] == selectedCropId.value,
    );
  }

  @override
  void onClose() {
    cropVariantController.dispose();
    super.onClose();
  }
}