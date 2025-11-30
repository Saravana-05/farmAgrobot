import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../data/models/merchant/merchant_model.dart';
import '../../../data/models/sales/sales_model.dart';
import '../../../data/services/merchant/merchant_service.dart';
import '../../../data/services/sales/sales_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class AddSaleController extends GetxController {
  // Observable variables - using .obs for proper GetX reactivity
  final _isLoading = false.obs;
  final _isCompressing = false.obs;
  final _isLoadingYields = false.obs;
  final _isLoadingMerchants = false.obs;
  final _selectedIndex = 0.obs;
  final _selectedMerchantId = ''.obs;
  final _selectedYieldId = ''.obs;
  final _selectedPaymentMode = ''.obs;
  final _saleDate = Rxn<DateTime>();
  final _totalAmount = 0.0.obs;
  final _merchants = <Merchant>[].obs;
  final _availableYields = <AvailableYield>[].obs; // Changed to AvailableYield
  final _paymentModes = <String>[].obs;

  // Error states
  final _merchantsError = ''.obs;
  final _yieldsError = ''.obs;

  // Image handling properties
  final _billImages = <XFile>[].obs;
  final _compressedImageFiles = <File>[].obs;
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 10;

  // Getters for accessing observable values
  bool get isLoading => _isLoading.value;
  bool get isCompressing => _isCompressing.value;
  bool get isLoadingYields => _isLoadingYields.value;
  bool get isLoadingMerchants => _isLoadingMerchants.value;
  int get selectedIndex => _selectedIndex.value;
  String get selectedMerchantId => _selectedMerchantId.value;
  String get selectedYieldId => _selectedYieldId.value;
  String get selectedPaymentMode => _selectedPaymentMode.value;
  DateTime? get saleDate => _saleDate.value;
  double get totalAmount => _totalAmount.value;
  List<Merchant> get merchants => _merchants.toList();
  List<AvailableYield> get availableYields =>
      _availableYields.toList(); // Changed type
  List<String> get paymentModes => _paymentModes.toList();
  String get merchantsError => _merchantsError.value;
  String get yieldsError => _yieldsError.value;

  // Image getters
  List<XFile> get billImages => _billImages.toList();
  List<File> get compressedImageFiles => _compressedImageFiles.toList();
  bool get maxImagesReached => _billImages.length >= maxImages;

  // Text controllers
  final TextEditingController saleDateController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    // Set today's date as default
    _saleDate.value = DateTime.now();
    saleDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void onClose() {
    saleDateController.dispose();
    totalAmountController.dispose();
    _cleanupCompressedFiles();
    super.onClose();
  }

  void loadInitialData() async {
    _isLoading.value = true;
    try {
      await Future.wait([
        loadMerchants(),
        loadPaymentModes(),
        loadAvailableYields(),
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

  Future<void> loadMerchants() async {
    try {
      print('Loading merchants...');
      final result = await MerchantService.getAllMerchants();

      if (result['success'] && result['data'] != null) {
        final responseData = result['data'];

        List<dynamic> merchantList;
        if (responseData is List) {
          merchantList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          merchantList =
              responseData['data'] is List ? responseData['data'] : [];
        } else {
          print('Unexpected response structure: $responseData');
          merchantList = [];
        }

        List<Merchant> parsedMerchants = [];
        for (var merchantJson in merchantList) {
          try {
            final merchant = Merchant.fromJson(merchantJson);
            parsedMerchants.add(merchant);
            print('Parsed merchant: ${merchant.toString()}');
          } catch (e) {
            print('Error parsing merchant: $merchantJson, Error: $e');
          }
        }

        _merchants.value = parsedMerchants;
        print('Total merchants loaded: ${_merchants.length}');
        _merchants.refresh();
      } else {
        print('Failed to load merchants: ${result['data']}');
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to load merchants',
        );
      }
    } catch (e) {
      print('Exception in loadMerchants: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading merchants: ${e.toString()}',
      );
    }
  }

  Future<void> loadPaymentModes() async {
    try {
      print('Loading payment modes...');
      final result = await SalesService.getPaymentModes();

      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];

        List<String> modes;
        if (responseData is Map && responseData['data'] is List) {
          modes = (responseData['data'] as List).cast<String>();
        } else if (responseData is List) {
          modes = responseData.cast<String>();
        } else {
          // Fallback to hardcoded payment modes if API response is unexpected
          modes = ['Cash', 'Card', 'UPI', 'Online'];
        }

        _paymentModes.value = modes;
        print('Payment modes loaded: ${_paymentModes.toList()}');
      } else {
        // Use fallback payment modes matching your backend model choices
        _paymentModes.value = ['Cash', 'Card', 'UPI', 'Online'];
        print('Using fallback payment modes');
      }
    } catch (e) {
      print('Exception in loadPaymentModes: $e');
      // Use fallback payment modes matching your backend model
      _paymentModes.value = ['Cash', 'Card', 'UPI', 'Online'];
    }
  }

  Future<void> loadAvailableYields() async {
    _isLoadingYields.value = true;
    _yieldsError.value = '';

    try {
      print('Loading available yields from backend...');
      final result = await SalesService.getAvailableYields();

      print('Available yields API response: $result');
      print('Response type: ${result.runtimeType}');

      // Check if response is HTML (error page)
      if (result['data'] is String &&
          result['data'].toString().startsWith('<!DOCTYPE')) {
        throw Exception('API returned HTML error page instead of JSON');
      }

      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];

        // Handle different response structures from your backend
        List<dynamic> yieldList = [];

        if (responseData is List) {
          yieldList = responseData;
        } else if (responseData is Map) {
          if (responseData['data'] is List) {
            yieldList = responseData['data'];
          } else if (responseData['results'] is List) {
            yieldList = responseData['results'];
          } else if (responseData['yields'] is List) {
            yieldList = responseData['yields'];
          } else {
            print('Unexpected yields response structure: $responseData');
            yieldList = [];
          }
        }

        print('Processing ${yieldList.length} yields...');

        List<AvailableYield> parsedYields = [];
        for (int i = 0; i < yieldList.length; i++) {
          try {
            final yieldJson = yieldList[i];
            print('Parsing yield $i: $yieldJson');

            // Create AvailableYield from backend response
            final availableYield = AvailableYield.fromJson(yieldJson);
            parsedYields.add(availableYield);

            print('Successfully parsed yield $i: ${availableYield.toString()}');
          } catch (e, stackTrace) {
            print('Error parsing yield at index $i: $e');
            print('Yield data: ${yieldList[i]}');
            print('Stack trace: $stackTrace');
            // Continue with other yields even if one fails
          }
        }

        _availableYields.value = parsedYields;
        print('Total available yields loaded: ${parsedYields.length}');

        if (parsedYields.isEmpty) {
          _yieldsError.value = 'No available yields found';
        }

        // Log summary for debugging
        _logYieldsSummary(parsedYields);
      } else {
        final errorMsg = result['message'] ??
            result['error'] ??
            'Failed to load available yields';
        print('Yields API error: $errorMsg');
        _yieldsError.value = errorMsg;
      }
    } catch (e, stackTrace) {
      print('Exception in loadAvailableYields: $e');
      print('Stack trace: $stackTrace');
      _yieldsError.value = 'Network error: ${e.toString()}';
    } finally {
      _isLoadingYields.value = false;
    }
  }

  void _logYieldsSummary(List<AvailableYield> yields) {
    print('=== Available Yields Summary ===');
    print('Total yields: ${yields.length}');

    final cropCounts = <String, int>{};
    double totalQuantity = 0.0;

    for (final yield in yields) {
      cropCounts[yield.cropName] = (cropCounts[yield.cropName] ?? 0) + 1;
      totalQuantity += yield.totalQuantity;
    }

    print('Crops available: ${cropCounts.keys.join(', ')}');
    cropCounts.forEach((crop, count) {
      print('  $crop: $count yield(s)');
    });
    print(
        'Total quantity across all yields: ${totalQuantity.toStringAsFixed(1)}');
    print('==============================');
  }

  // Refresh methods
  Future<void> refreshMerchants() async {
    await loadMerchants();
  }

  Future<void> refreshYields() async {
    await loadAvailableYields();
  }

  Future<void> refreshAllData() async {
    loadInitialData();
  }

  void selectSaleDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: _saleDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select sale date',
    );

    if (picked != null) {
      _saleDate.value = picked;
      saleDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void selectMerchant(String? merchantId) {
    if (merchantId != null && merchantId.isNotEmpty) {
      _selectedMerchantId.value = merchantId;
      print('Selected merchant ID: $merchantId');
    } else {
      _selectedMerchantId.value = '';
    }
  }

  void updateTotalAmount(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    _totalAmount.value = amount;
    print('Total amount updated: $amount');
  }

  void selectPaymentMode(String? paymentMode) {
    if (paymentMode != null && paymentMode.isNotEmpty) {
      _selectedPaymentMode.value = paymentMode;
      print('Selected payment mode: $paymentMode');
    } else {
      _selectedPaymentMode.value = '';
    }
  }

  void selectYield(String? yieldId) {
    if (yieldId != null && yieldId.isNotEmpty) {
      _selectedYieldId.value = yieldId;
      print('Selected yield ID: $yieldId');

      // Auto-populate some data based on selected yield
      final selectedYield =
          _availableYields.firstWhereOrNull((y) => y.id == yieldId);
      if (selectedYield != null) {
        print('Selected yield details: ${selectedYield.displayText}');
        print('Available quantity: ${selectedYield.formattedQuantity}');
      }
    } else {
      _selectedYieldId.value = '';
    }
  }

  // Image picker methods (keeping your existing implementation)
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempDir = Directory.systemTemp;
      final fileName = 'bill_image_compressed_${timestamp}.jpg';
      final compressedPath = '${tempDir.path}/$fileName';

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
        print(
            'Compressed image saved: $compressedPath (${compressedBytes.length} bytes)');
        return compressedFile;
      } else {
        final originalFile = File(image.path);
        final fallbackFile = File(compressedPath);
        await originalFile.copy(compressedPath);
        print('Used original image as fallback: $compressedPath');
        return fallbackFile;
      }
    } catch (e) {
      print('Error compressing image: $e');
      try {
        return File(image.path);
      } catch (_) {
        return null;
      }
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _billImages.length) {
      _billImages.removeAt(index);

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

  // Navigate to Review Sale Screen
  void navigateToReviewSale() async {
    if (!_validateForm()) return;

    try {
      final selectedYield = _availableYields
          .firstWhereOrNull((y) => y.id == _selectedYieldId.value);

      // Prepare sale data for review screen
      Map<String, dynamic> saleData = {
        'saleDate': _saleDate.value,
        'merchantId': _selectedMerchantId.value,
        'merchantName': selectedMerchantName,
        'totalAmount': _totalAmount.value,
        'paymentMode': _selectedPaymentMode.value,
        'yieldId': _selectedYieldId.value,
        'yieldName': selectedYieldName,
        'harvestDate': selectedYield?.harvestDate,
        'yieldDisplayText': selectedYield?.displayText ?? '',
        'yieldQuantity': selectedYield?.formattedQuantity ?? '',
        'billImages': _compressedImageFiles,
        'originalImages': _billImages,
      };

      print('Navigating to review sale with data: $saleData');

      // Navigate to review screen without saving to database
      Get.toNamed(Routes.SALES_REVIEW, arguments: saleData);
    } catch (e) {
      print('Error navigating to review sale: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to navigate to review: ${e.toString()}',
      );
    }
  }

  bool _validateForm() {
    if (_saleDate.value == null) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select sale date',
      );
      return false;
    }

    if (_selectedMerchantId.value.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select a merchant',
      );
      return false;
    }

    if (_totalAmount.value <= 0) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please enter a valid total amount',
      );
      return false;
    }

    if (_selectedPaymentMode.value.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select a payment mode',
      );
      return false;
    }

    if (_selectedYieldId.value.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select a yield record',
      );
      return false;
    }

    if (_billImages.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please add at least one bill image',
      );
      return false;
    }

    // Validate selected yield still exists and is available
    final selectedYield = _availableYields
        .firstWhereOrNull((y) => y.id == _selectedYieldId.value);
    if (selectedYield == null) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Selected yield is no longer available',
      );
      return false;
    }

    if (selectedYield.totalQuantity <= 0) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Selected yield has no quantity available',
      );
      return false;
    }

    return true;
  }

  void _clearForm() {
    _selectedMerchantId.value = '';
    _selectedYieldId.value = '';
    _selectedPaymentMode.value = '';
    _saleDate.value = DateTime.now();
    _totalAmount.value = 0.0;
    saleDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    totalAmountController.clear();
    _billImages.clear();

    _cleanupCompressedFiles();
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
    return _selectedMerchantId.value.isNotEmpty ||
        _selectedYieldId.value.isNotEmpty ||
        _selectedPaymentMode.value.isNotEmpty ||
        _totalAmount.value > 0 ||
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
  String get selectedMerchantName {
    if (_selectedMerchantId.value.isEmpty) return '';
    final merchant =
        _merchants.firstWhereOrNull((m) => m.id == _selectedMerchantId.value);
    return merchant?.name ?? '';
  }

  String get selectedYieldName {
    if (_selectedYieldId.value.isEmpty) return '';
    final yieldRecord = _availableYields
        .firstWhereOrNull((y) => y.id == _selectedYieldId.value);
    return yieldRecord?.cropName ?? '';
  }

  // Get selected yield details for display
  AvailableYield? get selectedYield {
    if (_selectedYieldId.value.isEmpty) return null;
    return _availableYields
        .firstWhereOrNull((y) => y.id == _selectedYieldId.value);
  }

  String get formattedTotalAmount {
    return '₹${_totalAmount.value.toStringAsFixed(2)}';
  }

  String get imageSummary {
    if (_billImages.isEmpty) return 'No images selected';
    return '${_billImages.length} image${_billImages.length > 1 ? 's' : ''} selected';
  }

  // Data validation helpers
  bool get hasMerchants => _merchants.isNotEmpty;
  bool get hasYields => _availableYields.isNotEmpty;
  bool get hasPaymentModes => _paymentModes.isNotEmpty;

  // Get yields grouped by crop for better UI organization
  Map<String, List<AvailableYield>> get yieldsByCrop {
    final Map<String, List<AvailableYield>> grouped = {};
    for (final yield in _availableYields) {
      grouped.putIfAbsent(yield.cropName, () => []).add(yield);
    }
    return grouped;
  }
}
