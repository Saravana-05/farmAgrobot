import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/yield/yield_model.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../data/models/crop_variant/crop_variant_model.dart';
import '../../../data/models/farm_segments/farm_seg_models.dart';
import '../../../data/services/yield/yield_service.dart';
import '../../../data/services/crops/crop_service.dart';
import '../../../data/services/crop_variant/crop_variant_service.dart';
import '../../../data/services/farm_segment/farm_seg_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class EditYieldController extends GetxController {
  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Loading states
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isEditMode = false.obs;

  // Current yield being edited
  var currentYield = Rxn<YieldModel>();

  // Form controllers
  final harvestDateController = TextEditingController();
  final notesController = TextEditingController();

  // Selected values
  var selectedCrop = Rxn<String>();
  var selectedCropName = ''.obs;
  var selectedHarvestDate = Rxn<DateTime>();
  var selectedFarmSegments = <String>[].obs;
  var farmSegmentNames = <String>[].obs;

  // Yield variants - using the actual YieldVariant from the model
  var yieldVariants = <YieldVariant>[].obs;

  // Bill images - FIXED: Better image tracking
  var billImages = <File>[].obs;
  var existingBillUrls = <String>[].obs;
  var existingBillImages = <BillImage>[].obs;
  var removedBillImageIds = <String>[].obs;

  // Navigation
  var selectedIndex = 0.obs;

  // Available options - using proper model classes
  var availableCrops = <Crop>[].obs;
  var availableFarmSegments = <FarmSegment>[].obs;
  var availableVariants = <CropVariant>[].obs;
  var filteredVariants = <CropVariant>[].obs;

  // Available units from variants
  var availableUnits = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Get yield data from arguments if editing
    final arguments = Get.arguments;
    if (arguments != null && arguments is YieldModel) {
      isEditMode.value = true;
      currentYield.value = arguments;
      // Load data first, then populate form
      loadInitialData().then((_) {
        populateFormWithYieldData(arguments);
      });
    } else {
      isEditMode.value = false;
      initializeNewYield();
      loadInitialData();
    }
  }

  @override
  void onClose() {
    harvestDateController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Initialize form for new yield
  void initializeNewYield() {
    selectedHarvestDate.value = DateTime.now();
    harvestDateController.text = formatDate(DateTime.now());

    // Add one empty variant by default
    addNewVariant();
  }

  // Populate form with existing yield data
  void populateFormWithYieldData(YieldModel yield) {
    try {
      isLoading.value = true;

      // Basic fields
      selectedCrop.value = yield.cropId;
      selectedCropName.value = yield.cropName;
      selectedHarvestDate.value = yield.harvestDate;
      harvestDateController.text = formatDate(yield.harvestDate);

      // Filter variants by the selected crop - ADD THIS
      _filterVariantsByCrop(yield.cropId);

      // FIXED: Farm segments - ensure proper type casting and refresh
      selectedFarmSegments.value = List<String>.from(
          yield.yieldFarmSegments.map((segment) => segment.farmSegmentId));
      farmSegmentNames.value = List<String>.from(
          yield.yieldFarmSegments.map((segment) => segment.farmSegmentName));

      // Force refresh the observables
      selectedFarmSegments.refresh();
      farmSegmentNames.refresh();

      // Variants - use actual YieldVariant objects from the model
      yieldVariants.value = List<YieldVariant>.from(yield.yieldVariants
          .map((v) => v.copyWith(unit: v.unit.isNotEmpty ? v.unit : 'kg')));
      yieldVariants.refresh();

      // FIXED: Existing bill images - better handling
      existingBillUrls.value = List<String>.from(yield.billUrls);
      existingBillImages.value = List<BillImage>.from(yield.billImages);
      existingBillUrls.refresh();
      existingBillImages.refresh();

      print('Form populated with yield data: ${yield.id}');
      print('Farm segments count: ${selectedFarmSegments.length}');
      print('Existing images count: ${existingBillUrls.length}');
    } catch (e) {
      print('Error populating form: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading yield data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load initial data (crops, farm segments, variants)
  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadCrops(),
        loadFarmSegments(),
        loadVariants(),
      ]);
      _extractAvailableUnits();

      // If in edit mode and crop is already selected, filter variants
      if (isEditMode.value &&
          selectedCrop.value != null &&
          selectedCrop.value!.isNotEmpty) {
        _filterVariantsByCrop(selectedCrop.value!);
      }
    } catch (e) {
      print('Error loading initial data: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCrops() async {
    try {
      print('Loading crops...');
      final result = await CropService.getAllCrops();

      print('Crops API result: $result');

      if (result['success'] && result['data'] != null) {
        final responseData = result['data'];

        List<dynamic> cropList;
        if (responseData is List) {
          cropList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          cropList = responseData['data'] is List ? responseData['data'] : [];
        } else if (responseData is Map &&
            responseData.containsKey('status') &&
            responseData['status'] == 'success') {
          cropList = responseData['data'] is List ? responseData['data'] : [];
        } else {
          print('Unexpected response structure: $responseData');
          cropList = [];
        }

        print('Crop list extracted: $cropList');

        List<Crop> parsedCrops = [];
        for (var cropJson in cropList) {
          try {
            final crop = CropService.cropFromJson(cropJson);
            parsedCrops.add(crop);
            print('Parsed crop: ${crop.toString()}');
          } catch (e) {
            print('Error parsing crop: $cropJson, Error: $e');
          }
        }

        availableCrops.value = parsedCrops;
        print('Total crops loaded: ${availableCrops.length}');
        availableCrops.refresh();
      } else {
        print('Failed to load crops: ${result['data']}');
        CustomSnackbar.showError(
          title: 'Error',
          message:
              'Failed to load crops: ${result['data']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Exception in loadCrops: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading crops: ${e.toString()}',
      );
    }
  }

  Future<void> loadFarmSegments() async {
    try {
      print('Loading farm segments...');
      final result = await FarmSegmentService.getAllFarmSegments();

      print('Farm segments API result: $result');

      if (result['success'] && result['data'] != null) {
        final responseData = result['data'];

        List<dynamic> segmentList;
        if (responseData is List) {
          segmentList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          segmentList =
              responseData['data'] is List ? responseData['data'] : [];
        } else if (responseData is Map &&
            responseData.containsKey('status') &&
            responseData['status'] == 'success') {
          segmentList =
              responseData['data'] is List ? responseData['data'] : [];
        } else {
          print('Unexpected farm segments response structure: $responseData');
          segmentList = [];
        }

        print('Farm segment list extracted: $segmentList');

        List<FarmSegment> parsedSegments = [];
        for (var segmentJson in segmentList) {
          try {
            final segment = FarmSegment.fromJson(segmentJson);
            parsedSegments.add(segment);
            print('Parsed farm segment: ${segment.toString()}');
          } catch (e) {
            print('Error parsing farm segment: $segmentJson, Error: $e');
          }
        }

        availableFarmSegments.value = parsedSegments;
        print('Total farm segments loaded: ${availableFarmSegments.length}');
        availableFarmSegments.refresh();
      } else {
        print('Failed to load farm segments: ${result['data']}');
      }
    } catch (e) {
      print('Exception in loadFarmSegments: $e');
    }
  }

  Future<void> loadVariants() async {
    try {
      print('Loading crop variants...');
      final result = await CropVariantService.getAllCropVariants();

      print('Crop variants API result: $result');

      if (result['success'] && result['data'] != null) {
        final responseData = result['data'];

        List<dynamic> variantList;
        if (responseData is List) {
          variantList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          variantList =
              responseData['data'] is List ? responseData['data'] : [];
        } else if (responseData is Map &&
            responseData.containsKey('status') &&
            responseData['status'] == 'success') {
          variantList =
              responseData['data'] is List ? responseData['data'] : [];
        } else {
          print('Unexpected crop variants response structure: $responseData');
          variantList = [];
        }

        print('Crop variant list extracted: $variantList');

        List<CropVariant> parsedVariants = [];
        for (var variantJson in variantList) {
          try {
            final variant = CropVariant.fromJson(variantJson);
            parsedVariants.add(variant);
            print('Parsed crop variant: ${variant.toString()}');
          } catch (e) {
            print('Error parsing crop variant: $variantJson, Error: $e');
          }
        }

        availableVariants.value = parsedVariants;
        print('Total crop variants loaded: ${availableVariants.length}');
        availableVariants.refresh();
      } else {
        print('Failed to load crop variants: ${result['data']}');
      }
    } catch (e) {
      print('Exception in loadVariants: $e');
    }
  }

  // Extract available units from crop variants
  void _extractAvailableUnits() {
    final Set<String> units = <String>{};

    // Add units from all variants
    for (var variant in availableVariants) {
      if (variant.unit != null && variant.unit!.isNotEmpty) {
        units.add(variant.unit!);
      }
    }

    // Add some default units if none found
    if (units.isEmpty) {
      units.addAll(['Pieces', 'Bunch', 'Pack', 'kg', 'tons', 'quintals']);
    }

    availableUnits.value = units.toList()..sort();
    print('Available units: ${availableUnits.value}');
  }

  // Date handling
  Future<void> selectHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedHarvestDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      selectedHarvestDate.value = picked;
      harvestDateController.text = formatDate(picked);
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Crop selection
  void updateCrop(String? cropId) {
    selectedCrop.value = cropId;
    // Update crop name from available crops
    if (cropId != null) {
      final crop = availableCrops.firstWhereOrNull(
        (c) => c.id == cropId,
      );
      selectedCropName.value = crop?.displayName ?? '';

      // Filter variants by selected crop - THIS IS THE KEY FIX
      _filterVariantsByCrop(cropId);
    } else {
      selectedCropName.value = '';
      filteredVariants.clear();
    }

    // Clear existing variants when crop changes (except in edit mode with existing data)
    if (!isEditMode.value || currentYield.value?.cropId != cropId) {
      yieldVariants.clear();
      addNewVariant();
    }
  }

  void _filterVariantsByCrop(String cropId) {
    try {
      final filtered = availableVariants.where((variant) {
        return variant.cropId == cropId;
      }).toList();

      filteredVariants.value = filtered;
      filteredVariants.refresh(); // FIXED: Force refresh

      print('Filtered ${filtered.length} variants for crop ID: $cropId');
      for (var variant in filtered) {
        print('- Variant: ${variant.cropVariant}, Unit: ${variant.unit}');
      }
    } catch (e) {
      print('Error filtering variants: $e');
      filteredVariants.clear();
    }
  }

  // FIXED: Farm segment selection with proper refresh
  void updateFarmSegments(List<String> segmentIds) {
    selectedFarmSegments.value = List<String>.from(segmentIds);

    // Update farm segment names
    farmSegmentNames.value = segmentIds
        .map((id) {
          final segment = availableFarmSegments.firstWhereOrNull(
            (s) => s.id == id,
          );
          return segment?.displayName ?? '';
        })
        .where((name) => name.isNotEmpty) // Filter out empty names
        .toList()
        .cast<String>();

    // Force refresh both observables
    selectedFarmSegments.refresh();
    farmSegmentNames.refresh();

    print('Updated farm segments: ${selectedFarmSegments.length} selected');
    print('Farm segment names: $farmSegmentNames');
  }

  // Variant management - using the actual YieldVariant from model
  void addNewVariant() {
    yieldVariants.add(YieldVariant(
      yieldRecordId: currentYield.value?.id ?? '',
      cropVariantId: '',
      cropVariantName: '',
      quantity: 0.0,
      unit: availableUnits.isNotEmpty ? availableUnits.first : 'kg',
    ));
    yieldVariants.refresh(); // FIXED: Force refresh
  }

  void removeVariant(int index) {
    if (yieldVariants.length > 1) {
      yieldVariants.removeAt(index);
      yieldVariants.refresh(); // FIXED: Force refresh
    } else {
      CustomSnackbar.showWarning(
        title: 'Warning',
        message: 'At least one variant is required',
      );
    }
  }

  void updateVariant(int index, YieldVariant variant) {
    if (index < yieldVariants.length) {
      yieldVariants[index] = variant;
      yieldVariants.refresh(); // FIXED: Force refresh
    }
  }

  // FIXED: Better variant field update with proper refresh
  void updateVariantField(
    int index, {
    String? cropVariantId,
    String? cropVariantName,
    double? quantity,
    String? unit,
  }) {
    if (index < yieldVariants.length) {
      final currentVariant = yieldVariants[index];

      yieldVariants[index] = currentVariant.copyWith(
        cropVariantId: cropVariantId ?? currentVariant.cropVariantId,
        cropVariantName: cropVariantName ?? currentVariant.cropVariantName,
        quantity: quantity ?? currentVariant.quantity,
        unit: unit ?? currentVariant.unit,
      );

      // Auto-populate unit when variant is selected
      if (cropVariantId != null && cropVariantId.isNotEmpty) {
        _autoPopulateUnit(index, cropVariantId);
      }

      // FIXED: Force refresh
      yieldVariants.refresh();
      print('Updated variant $index: ${yieldVariants[index].toString()}');
    }
  }

  // FIXED: Better auto-populate unit with proper refresh
  void _autoPopulateUnit(int index, String variantId) {
    try {
      if (variantId.isEmpty || index < 0 || index >= yieldVariants.length) {
        return;
      }

      final selectedVariant = filteredVariants
          .firstWhereOrNull((variant) => variant.id == variantId);

      if (selectedVariant != null) {
        final currentVariant = yieldVariants[index];

        yieldVariants[index] = currentVariant.copyWith(
          unit: selectedVariant.unit ?? currentVariant.unit,
          cropVariantName:
              selectedVariant.cropVariant ?? currentVariant.cropVariantName,
        );

        // FIXED: Force refresh to update UI
        yieldVariants.refresh();

        print(
            'Auto-populated unit: ${selectedVariant.unit} for variant: ${selectedVariant.cropVariant}');

        // Show feedback to user
        if (selectedVariant.unit != null && selectedVariant.unit!.isNotEmpty) {
          CustomSnackbar.showInfo(
            title: 'Unit Auto-filled',
            message:
                'Unit "${selectedVariant.unit}" has been automatically filled',
          );
        }
      } else {
        print('No variant found for ID: $variantId in filtered variants');
      }
    } catch (e) {
      print('Error auto-populating unit: $e');
    }
  }

  void updateVariantUnit(int index, String unit) {
    if (index < yieldVariants.length) {
      yieldVariants[index] = yieldVariants[index].copyWith(unit: unit);
      yieldVariants.refresh(); // FIXED: Force refresh
    }
  }

  // FIXED: Better image handling with proper limits and validation
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Check current image count (existing + new)
      final currentImageCount = existingBillUrls.length + billImages.length;
      final maxImages = 10;

      if (currentImageCount >= maxImages) {
        CustomSnackbar.showWarning(
          title: 'Limit Reached',
          message: 'Maximum $maxImages images allowed',
        );
        return;
      }

      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFiles.isNotEmpty) {
        // Limit based on remaining slots
        final remainingSlots = maxImages - currentImageCount;
        final limitedFiles = pickedFiles.take(remainingSlots).toList();

        // Convert XFile to File and validate
        List<File> validFiles = [];
        for (var xFile in limitedFiles) {
          File file = File(xFile.path);
          if (await _validateImageFile(file)) {
            validFiles.add(file);
          }
        }

        if (validFiles.isNotEmpty) {
          billImages.addAll(validFiles);
          billImages.refresh(); // FIXED: Force refresh

          CustomSnackbar.showSuccess(
            title: 'Success',
            message:
                '${validFiles.length} images added (Total: ${existingBillUrls.length + billImages.length})',
          );

          print(
              'Added ${validFiles.length} new images. Total images: ${existingBillUrls.length + billImages.length}');
        } else {
          CustomSnackbar.showError(
            title: 'Error',
            message: 'No valid images selected',
          );
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error selecting images: ${e.toString()}',
      );
    }
  }

  // Pick single image (alternative method)
  Future<void> pickSingleImage() async {
    try {
      // Check image limit
      final currentImageCount = existingBillUrls.length + billImages.length;
      if (currentImageCount >= 10) {
        CustomSnackbar.showWarning(
          title: 'Limit Reached',
          message: 'Maximum 10 images allowed',
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        if (await _validateImageFile(file)) {
          billImages.add(file);
          billImages.refresh(); // FIXED: Force refresh

          CustomSnackbar.showSuccess(
            title: 'Success',
            message:
                'Image added successfully (Total: ${existingBillUrls.length + billImages.length})',
          );
        } else {
          CustomSnackbar.showError(
            title: 'Error',
            message: 'Invalid image file',
          );
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error selecting image: ${e.toString()}',
      );
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      // Check image limit
      final currentImageCount = existingBillUrls.length + billImages.length;
      if (currentImageCount >= 10) {
        CustomSnackbar.showWarning(
          title: 'Limit Reached',
          message: 'Maximum 10 images allowed',
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        if (await _validateImageFile(file)) {
          billImages.add(file);
          billImages.refresh(); // FIXED: Force refresh

          CustomSnackbar.showSuccess(
            title: 'Success',
            message:
                'Image captured successfully (Total: ${existingBillUrls.length + billImages.length})',
          );
        } else {
          CustomSnackbar.showError(
            title: 'Error',
            message: 'Invalid image file',
          );
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error capturing image: ${e.toString()}',
      );
    }
  }

  // Basic image validation (implement based on your requirements)
  Future<bool> _validateImageFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        print('Image file does not exist: ${file.path}');
        return false;
      }

      // Check file size (example: max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        CustomSnackbar.showError(
          title: 'File Too Large',
          message: 'Image size must be less than 10MB',
        );
        return false;
      }

      // Check file extension
      final extension = file.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        CustomSnackbar.showError(
          title: 'Invalid Format',
          message: 'Supported formats: JPG, JPEG, PNG, GIF, WebP',
        );
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating image file: $e');
      return false;
    }
  }

  void removeImage(int index) {
    if (index < billImages.length) {
      billImages.removeAt(index);
      billImages.refresh(); // FIXED: Force refresh

      CustomSnackbar.showInfo(
        title: 'Removed',
        message:
            'Image removed (Total: ${existingBillUrls.length + billImages.length})',
      );
    }
  }

  void removeExistingImage(String imageUrl) {
    existingBillUrls.remove(imageUrl);

    // Find and track the BillImage ID for deletion
    final billImage = existingBillImages.firstWhereOrNull(
      (img) => img.imageUrl == imageUrl,
    );

    if (billImage != null && billImage.id.isNotEmpty) {
      removedBillImageIds.add(billImage.id);
      existingBillImages.remove(billImage);

      // FIXED: Force refresh
      existingBillUrls.refresh();
      existingBillImages.refresh();
      removedBillImageIds.refresh();

      CustomSnackbar.showInfo(
        title: 'Removed',
        message:
            'Existing image removed (Total: ${existingBillUrls.length + billImages.length})',
      );
    }
  }

  // Form validation
  String? validateCrop(String? value) {
    if (selectedCrop.value == null || selectedCrop.value!.isEmpty) {
      return 'Please select a crop';
    }
    return null;
  }

  String? validateHarvestDate(String? value) {
    if (selectedHarvestDate.value == null) {
      return 'Please select harvest date';
    }
    return null;
  }

  String? validateFarmSegments() {
    if (selectedFarmSegments.isEmpty) {
      return 'Please select at least one farm segment';
    }
    return null;
  }

  String? validateVariants() {
    if (yieldVariants.isEmpty) {
      return 'Please add at least one variant';
    }

    for (int i = 0; i < yieldVariants.length; i++) {
      final variant = yieldVariants[i];
      if (variant.cropVariantId.isEmpty) {
        return 'Variant ${i + 1}: Please select crop variant';
      }
      if (variant.quantity <= 0) {
        return 'Variant ${i + 1}: Please enter valid quantity';
      }
      if (variant.unit.isEmpty) {
        return 'Variant ${i + 1}: Please select unit';
      }
    }
    return null;
  }

  // Save yield
  Future<void> saveYield() async {
    if (isSaving.value) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    // Additional validations
    final farmSegmentError = validateFarmSegments();
    if (farmSegmentError != null) {
      CustomSnackbar.showError(
          title: 'Validation Error', message: farmSegmentError);
      return;
    }

    final variantsError = validateVariants();
    if (variantsError != null) {
      CustomSnackbar.showError(
          title: 'Validation Error', message: variantsError);
      return;
    }

    try {
      isSaving.value = true;

      if (isEditMode.value && currentYield.value != null) {
        await _updateExistingYield();
      } else {
        await _createNewYield();
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error saving yield: ${e.toString()}',
      );
    } finally {
      isSaving.value = false;
    }
  }

  // Create new yield
  Future<void> _createNewYield() async {
    // Create YieldModel object
    final newYield = YieldModel(
      id: '', // Will be set by backend
      cropId: selectedCrop.value!,
      cropName: selectedCropName.value,
      harvestDate: selectedHarvestDate.value!,
      yieldVariants: yieldVariants
          .map((v) => v.copyWith(
                yieldRecordId: '', // Will be set by backend
              ))
          .toList(),
      yieldFarmSegments: selectedFarmSegments.map((segmentId) {
        final segment =
            availableFarmSegments.firstWhereOrNull((s) => s.id == segmentId);
        return YieldFarmSegment(
          yieldRecordId: '', // Will be set by backend
          farmSegmentId: segmentId,
          farmSegmentName: segment?.displayName ?? '',
        );
      }).toList(),
    );

    // Use the toCreateJson method from the model
    final yieldData = newYield.toCreateJson();

    final response = await YieldService.saveYield(
      yieldData: yieldData,
      billImages: billImages.isNotEmpty ? billImages.toList() : null,
    );

    if (response['success'] == true) {
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Yield saved successfully',
      );
      Get.back(result: {'success': true});
    } else {
      _handleSaveError(response);
    }
  }

  // FIXED: Better update existing yield with proper image handling
  Future<void> _updateExistingYield() async {
    try {
      final updatedYield = currentYield.value!.copyWith(
        cropId: selectedCrop.value!,
        cropName: selectedCropName.value,
        harvestDate: selectedHarvestDate.value!,
        yieldVariants: yieldVariants,
        yieldFarmSegments: selectedFarmSegments.map((segmentId) {
          final segment =
              availableFarmSegments.firstWhereOrNull((s) => s.id == segmentId);
          return YieldFarmSegment(
            yieldRecordId: currentYield.value!.id,
            farmSegmentId: segmentId,
            farmSegmentName: segment?.displayName ?? '',
          );
        }).toList(),
      );

      final yieldData = updatedYield.toCreateJson();

      // Update main yield data
      final response = await YieldService.updateYield(
        yieldId: currentYield.value!.id,
        yieldData: yieldData,
      );

      if (response['success'] != true) {
        _handleSaveError(response);
        return;
      }

      // FIXED: Handle new bill images - add them one by one for better error handling
      if (billImages.isNotEmpty) {
        print('Adding ${billImages.length} new images...');

        for (int i = 0; i < billImages.length; i++) {
          try {
            final imageResponse = await YieldService.addBillImages(
              yieldId: currentYield.value!.id,
              imageFiles: [billImages[i]], // Add one image at a time
            );

            if (imageResponse['success'] != true) {
              print('Failed to add image ${i + 1}: ${imageResponse['data']}');
              CustomSnackbar.showWarning(
                title: 'Partial Success',
                message: 'Some images could not be uploaded',
              );
            } else {
              print('Successfully added image ${i + 1}');
            }
          } catch (e) {
            print('Error adding image ${i + 1}: $e');
            CustomSnackbar.showWarning(
              title: 'Image Upload Warning',
              message: 'Image ${i + 1} could not be uploaded: ${e.toString()}',
            );
          }
        }
      }

      // FIXED: Handle removed bill images - remove them one by one
      if (removedBillImageIds.isNotEmpty) {
        print('Removing ${removedBillImageIds.length} existing images...');

        for (String imageId in removedBillImageIds) {
          try {
            final removeResponse = await YieldService.removeBillImage(
              yieldId: currentYield.value!.id,
              imageId: imageId,
            );

            if (removeResponse['success'] != true) {
              print(
                  'Failed to remove image $imageId: ${removeResponse['data']}');
            } else {
              print('Successfully removed image $imageId');
            }
          } catch (e) {
            print('Error removing image $imageId: $e');
          }
        }
      }

      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Yield updated successfully',
      );
      Get.back(result: {'success': true});
    } catch (e) {
      print('Error in _updateExistingYield: $e');
      CustomSnackbar.showError(
        title: 'Update Error',
        message: 'Error updating yield: ${e.toString()}',
      );
    }
  }

  void _handleSaveError(Map<String, dynamic> response) {
    String errorMessage = 'Failed to save yield';
    if (response['data'] != null && response['data']['message'] != null) {
      errorMessage = response['data']['message'];
    }
    CustomSnackbar.showError(title: 'Error', message: errorMessage);
  }

  // Navigation methods
  void navigateToTab(int index) {
    selectedIndex.value = index;
    // Handle navigation based on index
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.HOME);
        break;
      case 1:
        Get.offAllNamed(Routes.YIELD);
        break;
      case 2:
        Get.offAllNamed(Routes.MERCHANT);
        break;
      // Add other cases as needed
    }
  }

  void navigateToViewYields() {
    Get.offAllNamed(Routes.YIELD);
  }

  // Utility methods
  double get totalQuantity {
    return yieldVariants.fold(0.0, (sum, variant) => sum + variant.quantity);
  }

  String get variantsSummary {
    if (yieldVariants.isEmpty) return 'No variants';
    if (yieldVariants.length == 1) {
      final variant = yieldVariants.first;
      return '${variant.quantity} ${variant.unit}';
    }
    return '${yieldVariants.length} variants';
  }

  // FIXED: Better unsaved changes detection
  bool get hasUnsavedChanges {
    if (!isEditMode.value) {
      return selectedCrop.value != null ||
          selectedFarmSegments.isNotEmpty ||
          yieldVariants
              .any((v) => v.quantity > 0 || v.cropVariantId.isNotEmpty) ||
          billImages.isNotEmpty;
    }

    // For edit mode, check if anything has changed from original
    final original = currentYield.value!;
    return selectedCrop.value != original.cropId ||
        selectedHarvestDate.value != original.harvestDate ||
        !_listsEqual(
            selectedFarmSegments.toList(),
            original.yieldFarmSegments
                .map((s) => s.farmSegmentId)
                .toList()
                .cast<String>()) ||
        !_variantsEqual(yieldVariants.toList(), original.yieldVariants) ||
        billImages.isNotEmpty ||
        removedBillImageIds.isNotEmpty ||
        existingBillUrls.length != original.billUrls.length;
  }

  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _variantsEqual(List<YieldVariant> a, List<YieldVariant> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].cropVariantId != b[i].cropVariantId ||
          a[i].quantity != b[i].quantity ||
          a[i].unit != b[i].unit) {
        return false;
      }
    }
    return true;
  }

  // Method to get current yield as YieldModel (useful for preview/summary)
  YieldModel getCurrentYieldModel() {
    return YieldModel(
      id: currentYield.value?.id ?? '',
      cropId: selectedCrop.value ?? '',
      cropName: selectedCropName.value,
      harvestDate: selectedHarvestDate.value ?? DateTime.now(),
      yieldVariants: yieldVariants,
      yieldFarmSegments: selectedFarmSegments.map((segmentId) {
        final segment =
            availableFarmSegments.firstWhereOrNull((s) => s.id == segmentId);
        return YieldFarmSegment(
          yieldRecordId: currentYield.value?.id ?? '',
          farmSegmentId: segmentId,
          farmSegmentName: segment?.displayName ?? '',
        );
      }).toList(),
      billImages: [
        ...existingBillImages,
        // Note: Can't create BillImage objects from File objects without uploading first
      ],
    );
  }

  // Helper method to get crop name by ID
  String getCropNameById(String? cropId) {
    if (cropId == null || cropId.isEmpty) return '';
    final crop = availableCrops.firstWhereOrNull((c) => c.id == cropId);
    return crop?.displayName ?? '';
  }

  // Helper method to get farm segment name by ID
  String getFarmSegmentNameById(String? segmentId) {
    if (segmentId == null || segmentId.isEmpty) return '';
    final segment =
        availableFarmSegments.firstWhereOrNull((s) => s.id == segmentId);
    return segment?.displayName ?? '';
  }

  // Helper method to get variant name by ID
  String getVariantNameById(String? variantId) {
    if (variantId == null || variantId.isEmpty) return '';
    final variant = filteredVariants.firstWhereOrNull((v) => v.id == variantId);
    return variant?.cropVariant ?? '';
  }

  // Helper method to get unit by variant ID
  String getUnitByVariantId(String? variantId) {
    if (variantId == null || variantId.isEmpty) return '';
    final variant = filteredVariants.firstWhereOrNull((v) => v.id == variantId);
    return variant?.unit ?? '';
  }

  // FIXED: Additional helper methods for better debugging and UI updates

  // Get total image count (existing + new)
  int get totalImageCount => existingBillUrls.length + billImages.length;

  // Get farm segment count for display
  int get farmSegmentCount => selectedFarmSegments.length;

  // Check if variant has auto-fillable unit
  bool canAutoFillUnit(String variantId) {
    final variant = filteredVariants.firstWhereOrNull((v) => v.id == variantId);
    return variant != null && variant.unit != null && variant.unit!.isNotEmpty;
  }

  // Force refresh all observables (useful for debugging)
  void forceRefreshAll() {
    selectedFarmSegments.refresh();
    farmSegmentNames.refresh();
    yieldVariants.refresh();
    billImages.refresh();
    existingBillUrls.refresh();
    existingBillImages.refresh();
    filteredVariants.refresh();
    print('Force refreshed all observables');
  }

  // Debug method to print current state
  void debugPrintCurrentState() {
    print('=== EditYieldController Current State ===');
    print('Edit Mode: ${isEditMode.value}');
    print('Selected Crop: ${selectedCrop.value} (${selectedCropName.value})');
    print('Farm Segments: ${selectedFarmSegments.length} selected');
    print('Variants: ${yieldVariants.length}');
    print('Filtered Variants: ${filteredVariants.length}');
    print(
        'Bill Images: ${billImages.length} new, ${existingBillUrls.length} existing');
    print('==========================================');
  }
}
