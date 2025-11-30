import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../data/models/crop_variant/crop_variant_model.dart';
import '../../../data/models/farm_segments/farm_seg_models.dart';
import '../../../data/services/crop_variant/crop_variant_service.dart';
import '../../../data/services/farm_segment/farm_seg_service.dart';
import '../../../data/services/yield/yield_service.dart';
import '../../../data/services/crops/crop_service.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class YieldVariantData extends GetxController {
  String variantId = '';
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  @override
  void dispose() {
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }
}

class AddYieldController extends GetxController {
  // Observable variables - using .obs for proper GetX reactivity
  final _isSaving = false.obs;
  final _isUploading = false.obs;
  final _isLoading = false.obs;
  final _isCompressing = false.obs;
  final _selectedIndex = 0.obs;
  final _selectedCropId = ''.obs;
  final _harvestDate = Rxn<DateTime>();
  final _selectedFarmSegments = <String>[].obs;
  final _yieldVariants = <YieldVariantData>[].obs;
  final _billUrls = <String>[].obs;
  final _crops = <Crop>[].obs;
  final _farmSegments = <FarmSegment>[].obs;
  final _availableVariants = <CropVariant>[].obs;
  final _filteredVariants = <CropVariant>[].obs;

  // Image handling properties
  final _billImages = <XFile>[].obs;
  final _compressedImageFiles = <File>[].obs; // Changed to store compressed File objects
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 10;
  static const int maxImageSizeKB = 500;

  // Getters for accessing observable values
  bool get isSaving => _isSaving.value;
  bool get isUploading => _isUploading.value;
  bool get isLoading => _isLoading.value;
  bool get isCompressing => _isCompressing.value;
  int get selectedIndex => _selectedIndex.value;
  String get selectedCropId => _selectedCropId.value;
  DateTime? get harvestDate => _harvestDate.value;
  List<String> get selectedFarmSegments => _selectedFarmSegments.toList();
  List<YieldVariantData> get yieldVariants => _yieldVariants.toList();
  List<String> get billUrls => _billUrls.toList();
  List<Crop> get crops => _crops.toList();
  List<FarmSegment> get farmSegments => _farmSegments.toList();
  List<CropVariant> get availableVariants => _availableVariants.toList();
  List<CropVariant> get filteredVariants => _filteredVariants.toList();

  // Image getters
  List<XFile> get billImages => _billImages.toList();
  List<File> get compressedImageFiles => _compressedImageFiles.toList();
  bool get maxImagesReached => _billImages.length >= maxImages;

  // Public observables for GetX widgets
  RxBool get isSavingObs => _isSaving;
  RxBool get isUploadingObs => _isUploading;
  RxBool get isLoadingObs => _isLoading;
  RxBool get isCompressingObs => _isCompressing;
  RxInt get selectedIndexObs => _selectedIndex;
  RxString get selectedCropIdObs => _selectedCropId;
  Rxn<DateTime> get harvestDateObs => _harvestDate;
  RxList<String> get selectedFarmSegmentsObs => _selectedFarmSegments;
  RxList<YieldVariantData> get yieldVariantsObs => _yieldVariants;
  RxList<String> get billUrlsObs => _billUrls;
  RxList<Crop> get cropsObs => _crops;
  RxList<FarmSegment> get farmSegmentsObs => _farmSegments;
  RxList<CropVariant> get availableVariantsObs => _availableVariants;
  RxList<CropVariant> get filteredVariantsObs => _filteredVariants;
  RxList<XFile> get billImagesObs => _billImages;

  // Text controllers
  final TextEditingController harvestDateController = TextEditingController();
  final TextEditingController billUrlController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    addYieldVariant();
  }

  @override
  void onClose() {
    harvestDateController.dispose();
    billUrlController.dispose();
    for (var variant in _yieldVariants) {
      variant.dispose();
    }
    _cleanupCompressedFiles();
    super.onClose();
  }

  void loadInitialData() async {
    _isLoading.value = true;
    try {
      await Future.wait([
        loadCrops(),
        loadFarmSegments(),
        loadVariants(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load data: ${e.toString()}',
      );
    } finally {
      _isLoading.value = false;
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

        _crops.value = parsedCrops;
        print('Total crops loaded: ${_crops.length}');
        _crops.refresh();
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

        _farmSegments.value = parsedSegments;
        print('Total farm segments loaded: ${_farmSegments.length}');
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

        _availableVariants.value = parsedVariants;
        print('Total crop variants loaded: ${_availableVariants.length}');
      } else {
        print('Failed to load crop variants: ${result['data']}');
      }
    } catch (e) {
      print('Exception in loadVariants: $e');
    }
  }

  void selectCrop(String? cropId) {
    if (cropId != null && cropId.isNotEmpty) {
      _selectedCropId.value = cropId;
      print('Selected crop ID: $cropId');

      _filterVariantsByCrop(cropId);
      _clearYieldVariants();
      addYieldVariant();
    } else {
      _selectedCropId.value = '';
      _filteredVariants.clear();
      _clearYieldVariants();
    }
  }

  void _filterVariantsByCrop(String cropId) {
    try {
      final filtered = _availableVariants.where((variant) {
        return variant.cropId == cropId;
      }).toList();

      _filteredVariants.value = filtered;

      print('Filtered ${filtered.length} variants for crop ID: $cropId');
      for (var variant in filtered) {
        print('- Variant: ${variant.cropVariant}, Unit: ${variant.unit}');
      }
    } catch (e) {
      print('Error filtering variants: $e');
      _filteredVariants.clear();
    }
  }

  void _clearYieldVariants() {
    for (var variant in _yieldVariants) {
      variant.dispose();
    }
    _yieldVariants.clear();
  }

  void selectHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: _harvestDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select harvest date',
    );

    if (picked != null) {
      _harvestDate.value = picked;
      harvestDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void toggleFarmSegment(String segmentId) {
    if (_selectedFarmSegments.contains(segmentId)) {
      _selectedFarmSegments.remove(segmentId);
    } else {
      _selectedFarmSegments.add(segmentId);
    }
  }

  void addYieldVariant() {
    final variant = YieldVariantData();
    _yieldVariants.add(variant);
  }

  void removeYieldVariant(int index) {
    if (index >= 0 && index < _yieldVariants.length) {
      _yieldVariants[index].dispose();
      _yieldVariants.removeAt(index);
    }
  }

  void updateVariantId(int index, String variantId) {
    if (index >= 0 && index < _yieldVariants.length) {
      _yieldVariants[index].variantId = variantId;
      _autoPopulateUnit(index, variantId);
      _yieldVariants.refresh();
    }
  }

  void _autoPopulateUnit(int index, String variantId) {
    try {
      if (variantId.isEmpty || index < 0 || index >= _yieldVariants.length) {
        return;
      }

      final selectedVariant = _filteredVariants
          .firstWhereOrNull((variant) => variant.id == variantId);

      if (selectedVariant != null && selectedVariant.unit != null) {
        _yieldVariants[index].unitController.text = selectedVariant.unit!;

        print(
            'Auto-populated unit: ${selectedVariant.unit} for variant: ${selectedVariant.cropVariant}');

        CustomSnackbar.showInfo(
          title: 'Unit Auto-filled',
          message:
              'Unit "${selectedVariant.unit}" has been automatically filled',
        );
      } else {
        print('No unit found for variant ID: $variantId');
        _yieldVariants[index].unitController.clear();
      }
    } catch (e) {
      print('Error auto-populating unit: $e');
    }
  }

  void updateVariantQuantity(int index, String quantity) {
    if (index >= 0 && index < _yieldVariants.length) {
      _yieldVariants[index].quantityController.text = quantity;
    }
  }

  void updateVariantUnit(int index, String unit) {
    if (index >= 0 && index < _yieldVariants.length) {
      _yieldVariants[index].unitController.text = unit;
    }
  }

  // Image picker methods
  Future<void> pickImageFromCamera() async {
    if (_billImages.length >= maxImages) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Maximum $maxImages images are allowed',
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        _isCompressing.value = true;
        await _processAndAddImage(image);
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to capture image: ${e.toString()}',
      );
    } finally {
      _isCompressing.value = false;
    }
  }

  Future<void> pickMultipleImages() async {
    if (_billImages.length >= maxImages) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Maximum $maxImages images are allowed',
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        _isCompressing.value = true;

        final int remainingSlots = maxImages - _billImages.length;
        final List<XFile> imagesToProcess =
            images.take(remainingSlots).toList();

        if (imagesToProcess.length < images.length) {
          CustomSnackbar.showWarning(
            title: 'Warning',
            message:
                'Only ${imagesToProcess.length} images added. Maximum $maxImages allowed.',
          );
        }

        for (XFile image in imagesToProcess) {
          await _processAndAddImage(image);
        }

        CustomSnackbar.showSuccess(
          title: 'Success',
          message: '${imagesToProcess.length} image(s) added successfully',
        );
      }
    } catch (e) {
      print('Error picking multiple images: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to select images: ${e.toString()}',
      );
    } finally {
      _isCompressing.value = false;
    }
  }

  Future<void> _processAndAddImage(XFile image) async {
    try {
      final File? compressedFile = await _compressAndSaveImage(image);

      if (compressedFile != null) {
        _billImages.add(image);
        _compressedImageFiles.add(compressedFile);
      } else {
        CustomSnackbar.showError(
          title: 'Image Error',
          message: 'Could not process image: ${image.name}',
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'An error occurred while processing image: $e',
      );
    }
  }

  Future<File?> _compressAndSaveImage(XFile image) async {
    try {
      // Create unique filename for compressed image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempDir = Directory.systemTemp;
      final fileName = 'yield_bill_compressed_${timestamp}.jpg';
      final compressedPath = '${tempDir.path}/$fileName';

      // Compress image and save to temp file
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes != null) {
        final compressedFile = File(compressedPath);
        await compressedFile.writeAsBytes(compressedBytes);
        print('Compressed image saved: $compressedPath (${compressedBytes.length} bytes)');
        return compressedFile;
      } else {
        // Fallback: copy original file
        final originalFile = File(image.path);
        final fallbackFile = File(compressedPath);
        await originalFile.copy(compressedPath);
        print('Used original image as fallback: $compressedPath');
        return fallbackFile;
      }
    } catch (e) {
      print('Error compressing image: $e');
      try {
        // Final fallback: return original file
        return File(image.path);
      } catch (_) {
        return null;
      }
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _billImages.length) {
      _billImages.removeAt(index);
      
      // Clean up compressed file
      if (index < _compressedImageFiles.length) {
        final file = _compressedImageFiles.removeAt(index);
        _deleteFileIfExists(file);
      }

      CustomSnackbar.showInfo(
        title: 'Info',
        message: 'Image removed',
      );
    }
  }

  void clearAllImages() {
    _billImages.clear();
    
    // Clean up all compressed files
    _cleanupCompressedFiles();

    CustomSnackbar.showInfo(
      title: 'Info',
      message: 'All images cleared',
    );
  }

  void _cleanupCompressedFiles() {
    for (final file in _compressedImageFiles) {
      _deleteFileIfExists(file);
    }
    _compressedImageFiles.clear();
  }

  void _deleteFileIfExists(File file) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
        print('Deleted temp file: ${file.path}');
      }
    } catch (e) {
      print('Error deleting temp file ${file.path}: $e');
    }
  }

  // Bill URL methods
  void addBillUrl() {
    final url = billUrlController.text.trim();

    if (url.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please enter a bill URL',
      );
      return;
    }

    if (!isValidUrl(url)) {
      CustomSnackbar.showError(
        title: 'Error',
        message:
            'Please enter a valid URL (must start with http:// or https://)',
      );
      return;
    }

    if (_billUrls.contains(url)) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'This URL has already been added',
      );
      return;
    }

    if (_billUrls.length >= 10) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Maximum 10 bill URLs are allowed',
      );
      return;
    }

    _billUrls.add(url);
    billUrlController.clear();

    CustomSnackbar.showSuccess(
      title: 'Success',
      message: 'Bill URL added successfully',
    );
  }

  void removeBillUrl(int index) {
    if (index >= 0 && index < _billUrls.length) {
      _billUrls.removeAt(index);
      CustomSnackbar.showInfo(
        title: 'Info',
        message: 'Bill URL removed',
      );
    }
  }

  bool get maxBillUrlsReached => _billUrls.length >= 10;

  String getFormattedBillUrl(String url, {int maxLength = 50}) {
    if (url.length <= maxLength) return url;
    return '${url.substring(0, maxLength - 3)}...';
  }

  void editBillUrl(int index, String newUrl) {
    if (index >= 0 && index < _billUrls.length) {
      if (!isValidUrl(newUrl)) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Please enter a valid URL',
        );
        return;
      }

      if (_billUrls.contains(newUrl) && _billUrls[index] != newUrl) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'This URL already exists',
        );
        return;
      }

      _billUrls[index] = newUrl;
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Bill URL updated successfully',
      );
    }
  }

  // URL validation helper
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  // Enhanced save yield method
  void saveYield() async {
    if (_isSaving.value) return;

    if (!_validateForm()) return;

    try {
      _isSaving.value = true;
      _isUploading.value = true;

      // Prepare yield data with proper data types
      List<int> farmSegmentIds = _selectedFarmSegments
          .map((id) => int.tryParse(id) ?? 0)
          .where((id) => id > 0)
          .toList();

      Map<String, dynamic> yieldData = {
        'crop': int.parse(_selectedCropId.value),
        'harvest_date': YieldService.formatDateForApi(_harvestDate.value!),
        'farm_segments': farmSegmentIds,
        'variants': _yieldVariants
            .map((variant) => {
                  'crop_variant_id': int.parse(variant.variantId),
                  'quantity': double.parse(variant.quantityController.text.trim()),
                  'unit': variant.unitController.text.trim(),
                })
            .toList(),
      };

      // Add manual bill URLs if any
      if (_billUrls.isNotEmpty) {
        yieldData['bill_urls'] = _billUrls.toList();
      }

      print('Saving yield data: $yieldData');
      if (_compressedImageFiles.isNotEmpty) {
        print('Uploading ${_compressedImageFiles.length} image files');
      }

      // Validate yield data using service method
      final validationErrors = YieldService.validateYieldData(yieldData);
      if (validationErrors != null) {
        String errorMessage = validationErrors.values.first;
        CustomSnackbar.showError(
          title: 'Validation Error',
          message: errorMessage,
        );
        return;
      }

      // Save yield with files to backend
      Map<String, dynamic> result = await YieldService.saveYield(
        yieldData: yieldData,
        billImages: _compressedImageFiles.isNotEmpty ? _compressedImageFiles : null,
      );

      if (result['success']) {
        String message = result['data']['message'] ?? 'Yield saved successfully';
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: message,
        );

        _clearForm();
        await Future.delayed(const Duration(milliseconds: 1000));
        Get.offAllNamed(Routes.YIELD, arguments: true);
      } else {
        String errorMessage = result['data']['message'] ?? 'Failed to save yield';
        
        // Handle validation errors from service
        if (result['data']['errors'] != null) {
          final errors = result['data']['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first.toString();
        }
        
        CustomSnackbar.showError(
          title: 'Error',
          message: errorMessage,
        );
      }
    } catch (e) {
      print('Error saving yield: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to save yield: ${e.toString()}',
      );
    } finally {
      _isSaving.value = false;
      _isUploading.value = false;
    }
  }

  // Debug method for yield data
  void debugYieldData() {
    List<int> farmSegmentIds = _selectedFarmSegments
        .map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList();

    Map<String, dynamic> yieldData = {
      'crop': int.parse(_selectedCropId.value),
      'harvest_date': YieldService.formatDateForApi(_harvestDate.value!),
      'farm_segments': farmSegmentIds,
      'variants': _yieldVariants
          .map((variant) => {
                'crop_variant_id': int.parse(variant.variantId),
                'quantity': double.parse(variant.quantityController.text.trim()),
                'unit': variant.unitController.text.trim(),
              })
          .toList(),
    };

    if (_billUrls.isNotEmpty) {
      yieldData['bill_urls'] = _billUrls.toList();
    }

    print('=== DEBUG YIELD DATA ===');
    print('Yield Data Structure:');
    print(json.encode(yieldData));
    print('');
    print('Variants Detail:');
    for (int i = 0; i < yieldData['variants'].length; i++) {
      final variant = yieldData['variants'][i];
      print('Variant $i:');
      print('  crop_variant_id: ${variant['crop_variant_id']} (${variant['crop_variant_id'].runtimeType})');
      print('  quantity: ${variant['quantity']} (${variant['quantity'].runtimeType})');
      print('  unit: ${variant['unit']} (${variant['unit'].runtimeType})');
    }
    print('');
    print('Farm Segments: $farmSegmentIds');
    print('Bill URLs: ${yieldData['bill_urls'] ?? 'none'}');
    print('Images: ${_compressedImageFiles.length} files');
    print('========================');
  }

  bool _validateForm() {
    if (_selectedCropId.value.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select a crop',
      );
      return false;
    }

    if (_harvestDate.value == null) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select harvest date',
      );
      return false;
    }

    if (_selectedFarmSegments.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select at least one farm segment',
      );
      return false;
    }

    if (_yieldVariants.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please add at least one yield variant',
      );
      return false;
    }

    for (int i = 0; i < _yieldVariants.length; i++) {
      final variant = _yieldVariants[i];

      if (variant.variantId.isEmpty) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Please select variant for variant ${i + 1}',
        );
        return false;
      }

      final quantity = double.tryParse(variant.quantityController.text.trim());
      if (quantity == null || quantity <= 0) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Please enter a valid quantity for variant ${i + 1}',
        );
        return false;
      }

      if (variant.unitController.text.trim().isEmpty) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Please enter a unit for variant ${i + 1}',
        );
        return false;
      }
    }

    // Validate bill URLs if any exist
    for (int i = 0; i < _billUrls.length; i++) {
      if (!isValidUrl(_billUrls[i])) {
        CustomSnackbar.showError(
          title: 'Bill URL Error',
          message: 'Invalid URL at position ${i + 1}',
        );
        return false;
      }
    }

    return true;
  }

  void _clearForm() {
    _selectedCropId.value = '';
    _harvestDate.value = null;
    harvestDateController.clear();
    _selectedFarmSegments.clear();
    _filteredVariants.clear();
    _billUrls.clear();
    billUrlController.clear();
    _billImages.clear();
    
    // Clean up compressed files
    _cleanupCompressedFiles();

    for (var variant in _yieldVariants) {
      variant.dispose();
    }
    _yieldVariants.clear();
  }

  void navigateToViewYields() {
    Get.toNamed(Routes.YIELD);
  }

  void navigateToTab(int index) {
    _selectedIndex.value = index;
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

  bool get hasChanges {
    return _selectedCropId.value.isNotEmpty ||
        _harvestDate.value != null ||
        _selectedFarmSegments.isNotEmpty ||
        _yieldVariants.isNotEmpty ||
        _billUrls.isNotEmpty ||
        _billImages.isNotEmpty;
  }

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
                Get.back();
                _clearForm();
                Get.back();
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

  // Helper getters
  String get selectedCropName {
    if (_selectedCropId.value.isEmpty) return '';
    final crop = _crops.firstWhereOrNull((c) => c.id == _selectedCropId.value);
    return crop?.displayName ?? '';
  }

  double get totalYieldQuantity {
    double total = 0;
    for (var variant in _yieldVariants) {
      final quantity = double.tryParse(variant.quantityController.text.trim());
      if (quantity != null) {
        total += quantity;
      }
    }
    return total;
  }

  String get yieldSummary {
    if (_yieldVariants.isEmpty) return 'No variants added';

    List<String> variantSummaries = _yieldVariants.map((variant) {
      final quantity = variant.quantityController.text.trim();
      final unit = variant.unitController.text.trim();
      final variantName = _filteredVariants
              .firstWhereOrNull((v) => v.id == variant.variantId)
              ?.cropVariant ??
          'Unknown Variant';

      if (quantity.isNotEmpty && unit.isNotEmpty) {
        return '$quantity $unit of $variantName';
      }
      return variantName;
    }).toList();

    return variantSummaries.join(', ');
  }

  // Image summary helper
  String get imageSummary {
    if (_billImages.isEmpty) return 'No images selected';
    return '${_billImages.length} image${_billImages.length > 1 ? 's' : ''} selected';
  }

  // Total attachments count
  int get totalAttachments {
    return _billImages.length + _billUrls.length;
  }

  String get attachmentsSummary {
    final imageCount = _billImages.length;
    final urlCount = _billUrls.length;

    if (imageCount == 0 && urlCount == 0) {
      return 'No attachments';
    }

    List<String> parts = [];
    if (imageCount > 0) {
      parts.add('$imageCount image${imageCount > 1 ? 's' : ''}');
    }
    if (urlCount > 0) {
      parts.add('$urlCount URL${urlCount > 1 ? 's' : ''}');
    }

    return parts.join(', ');
  }
}