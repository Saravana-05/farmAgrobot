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

class EditSaleController extends GetxController {
  // Observable variables
  final _isLoading = false.obs;
  final _isCompressing = false.obs;
  final _isLoadingYields = false.obs;
  final _isLoadingMerchants = false.obs;
  final _isLoadingSale = false.obs;
  final _isSaving = false.obs;
  final _selectedMerchantId = ''.obs;
  final _selectedYieldId = ''.obs;
  final _selectedPaymentMode = ''.obs;
  final _saleDate = Rxn<DateTime>();
  final _totalAmount = 0.0.obs;
  final _merchants = <Merchant>[].obs;
  final _availableYields = <AvailableYield>[].obs;
  final _paymentModes = <String>[].obs;
  final _currentSale = Rxn<SaleModel>();
  final _saleVariants = <SaleVariant>[].obs;
  final _existingImages = <SaleImage>[].obs;
  final _imagesToDelete = <String>[].obs;

  // Error states
  final _merchantsError = ''.obs;
  final _yieldsError = ''.obs;
  final _loadError = ''.obs;

  // Image handling properties
  final _billImages = <XFile>[].obs;
  final _compressedImageFiles = <File>[].obs;
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 10;

  // Sale ID (passed as argument)
  String? saleId;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isCompressing => _isCompressing.value;
  bool get isLoadingYields => _isLoadingYields.value;
  bool get isLoadingMerchants => _isLoadingMerchants.value;
  bool get isLoadingSale => _isLoadingSale.value;
  bool get isSaving => _isSaving.value;
  String get selectedMerchantId => _selectedMerchantId.value;
  String get selectedYieldId => _selectedYieldId.value;
  String get selectedPaymentMode => _selectedPaymentMode.value;
  DateTime? get saleDate => _saleDate.value;
  double get totalAmount => _totalAmount.value;
  List<Merchant> get merchants => _merchants.toList();
  List<AvailableYield> get availableYields => _availableYields.toList();
  List<String> get paymentModes => _paymentModes.toList();
  SaleModel? get currentSale => _currentSale.value;
  List<SaleVariant> get saleVariants => _saleVariants.toList();
  List<SaleImage> get existingImages => _existingImages.toList();
  String get merchantsError => _merchantsError.value;
  String get yieldsError => _yieldsError.value;
  String get loadError => _loadError.value;

  // Image getters
  List<XFile> get billImages => _billImages.toList();
  List<File> get compressedImageFiles => _compressedImageFiles.toList();
  int get totalImagesCount => _existingImages.length + _billImages.length;
  bool get maxImagesReached => totalImagesCount >= maxImages;

  // Text controllers
  final TextEditingController saleDateController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // FIXED: Get sale ID from arguments properly
    final args = Get.arguments;

    if (args is Map<String, dynamic>) {
      saleId = args['saleId'] as String?;
    } else if (args is String) {
      // If the argument is passed directly as a string
      saleId = args;
    } else if (args is SaleModel) {
      // If a SaleModel object is passed
      saleId = args.id;
    }

    if (saleId == null || saleId!.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Sale ID is required',
      );
      Get.back();
      return;
    }

    print('EditSaleController initialized with saleId: $saleId');
    loadInitialData();
  }

  @override
  void onClose() {
    saleDateController.dispose();
    totalAmountController.dispose();
    notesController.dispose();
    _cleanupCompressedFiles();
    super.onClose();
  }

  void loadInitialData() async {
    _isLoading.value = true;
    _loadError.value = '';

    try {
      // Load supporting data first
      await Future.wait([
        loadMerchants(),
        loadPaymentModes(),
        loadAvailableYields(),
      ]);

      // THEN load sale details and populate form
      await loadSaleDetails();

      // Populate form AFTER all data is loaded
      _populateFormData();
    } catch (e) {
      print('Error loading initial data: $e');
      _loadError.value = 'Failed to load sale data: ${e.toString()}';
      CustomSnackbar.showError(
        title: 'Error',
        message: _loadError.value,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadSaleDetails() async {
    if (saleId == null || saleId!.isEmpty) return;

    _isLoadingSale.value = true;
    try {
      print('Loading sale details for ID: $saleId');
      final result = await SalesService.getSaleById(saleId!);

      if (result['success'] && result['data'] != null) {
        final responseData = result['data'];

        Map<String, dynamic>? saleData;
        if (responseData is Map && responseData.containsKey('data')) {
          saleData = responseData['data'];
        } else if (responseData is Map) {
          saleData = responseData.cast<String, dynamic>();
        } else {
          throw Exception('Invalid sale data format');
        }

        _currentSale.value = SaleModel.fromJson(saleData!);
        _saleVariants.value = _currentSale.value?.saleVariants ?? [];
        _existingImages.value = _currentSale.value?.saleImages ?? [];

        print('=== Sale Data Loaded ===');
        print('Sale ID: ${_currentSale.value?.id}');
        print('Merchant ID: ${_currentSale.value?.merchantId}');
        print('Yield ID: ${_currentSale.value?.yieldRecordId}');
        print('Payment Mode: ${_currentSale.value?.paymentMode}');
        print('Total Amount: ${_currentSale.value?.totalCalculatedAmount}');
        print('Variants: ${_saleVariants.length}');
        print('Images: ${_existingImages.length}');
        print('======================');
      } else {
        throw Exception(result['data']?['message'] ?? 'Failed to load sale');
      }
    } catch (e) {
      print('Exception in loadSaleDetails: $e');
      _loadError.value = 'Failed to load sale: ${e.toString()}';
      rethrow;
    } finally {
      _isLoadingSale.value = false;
    }
  }

  void _populateFormData() {
    if (_currentSale.value == null) return;

    final sale = _currentSale.value!;

    // Set form values
    _saleDate.value = sale.harvestDate;
    _totalAmount.value = sale.totalCalculatedAmount;

    // Update text controllers
    saleDateController.text = DateFormat('dd/MM/yyyy').format(sale.harvestDate);
    totalAmountController.text = sale.totalCalculatedAmount.toString();

    // FIXED: Only set merchant if it exists in the list
    if (_merchants.any((m) => m.id == sale.merchantId)) {
      _selectedMerchantId.value = sale.merchantId;
    } else {
      print('Warning: Merchant ${sale.merchantId} not found in merchants list');
      _selectedMerchantId.value = '';
    }

    // FIXED: Only set yield if it exists in the list
    if (_availableYields.any((y) => y.id == sale.yieldRecordId)) {
      _selectedYieldId.value = sale.yieldRecordId;
    } else {
      print(
          'Warning: Yield ${sale.yieldRecordId} not found in available yields');
      _selectedYieldId.value = '';
    }

    // FIXED: Only set payment mode if it exists in the list
    if (_paymentModes.contains(sale.paymentMode)) {
      _selectedPaymentMode.value = sale.paymentMode;
    } else {
      print(
          'Warning: Payment mode ${sale.paymentMode} not found in payment modes list');
      _selectedPaymentMode.value = '';
    }

    print('Form populated with sale data');
    print('Merchant ID: ${_selectedMerchantId.value}');
    print('Yield ID: ${_selectedYieldId.value}');
    print('Payment Mode: ${_selectedPaymentMode.value}');
  }

  Future<void> loadMerchants() async {
    _isLoadingMerchants.value = true;
    _merchantsError.value = '';

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
          merchantList = [];
        }

        List<Merchant> parsedMerchants = [];
        for (var merchantJson in merchantList) {
          try {
            parsedMerchants.add(Merchant.fromJson(merchantJson));
          } catch (e) {
            print('Error parsing merchant: $e');
          }
        }

        _merchants.value = parsedMerchants;
        print('Merchants loaded: ${_merchants.length}');
      } else {
        _merchantsError.value = 'Failed to load merchants';
      }
    } catch (e) {
      print('Exception in loadMerchants: $e');
      _merchantsError.value = 'Error loading merchants';
    } finally {
      _isLoadingMerchants.value = false;
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
          modes = ['Cash', 'Card', 'UPI', 'Online'];
        }

        _paymentModes.value = modes;
      } else {
        _paymentModes.value = ['Cash', 'Card', 'UPI', 'Online'];
      }
    } catch (e) {
      print('Exception in loadPaymentModes: $e');
      _paymentModes.value = ['Cash', 'Card', 'UPI', 'Online'];
    }
  }

  Future<void> loadAvailableYields() async {
    _isLoadingYields.value = true;
    _yieldsError.value = '';

    try {
      print('Loading available yields...');
      final result = await SalesService.getAvailableYields();

      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];
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
          }
        }

        List<AvailableYield> parsedYields = [];
        for (var yieldJson in yieldList) {
          try {
            parsedYields.add(AvailableYield.fromJson(yieldJson));
          } catch (e) {
            print('Error parsing yield: $e');
          }
        }

        _availableYields.value = parsedYields;

        // Add current yield if not in available yields
        if (_selectedYieldId.value.isNotEmpty) {
          final hasCurrentYield =
              parsedYields.any((y) => y.id == _selectedYieldId.value);
          if (!hasCurrentYield && _currentSale.value != null) {
            // Create a temporary yield object for the current sale's yield
            print('Current yield not in available list, keeping for editing');
          }
        }

        print('Available yields loaded: ${parsedYields.length}');
      } else {
        _yieldsError.value = 'Failed to load yields';
      }
    } catch (e) {
      print('Exception in loadAvailableYields: $e');
      _yieldsError.value = 'Error loading yields';
    } finally {
      _isLoadingYields.value = false;
    }
  }

  // Date selection
  void selectSaleDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: _saleDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select sale date',
    );

    if (picked != null && picked != _saleDate.value) {
      _saleDate.value = picked;
      saleDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // Selection methods
  void selectMerchant(String? merchantId) {
    if (merchantId != null && merchantId.isNotEmpty) {
      _selectedMerchantId.value = merchantId;
      print('Selected merchant ID: $merchantId');
    }
  }

  void selectYield(String? yieldId) {
    if (yieldId != null && yieldId.isNotEmpty) {
      _selectedYieldId.value = yieldId;
      print('Selected yield ID: $yieldId');
    }
  }

  void selectPaymentMode(String? paymentMode) {
    if (paymentMode != null && paymentMode.isNotEmpty) {
      _selectedPaymentMode.value = paymentMode;
      print('Selected payment mode: $paymentMode');
    }
  }

  void updateTotalAmount(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    _totalAmount.value = amount;
  }

  // Image management for existing images
  void markImageForDeletion(String imageId) {
    if (!_imagesToDelete.contains(imageId)) {
      _imagesToDelete.add(imageId);
      print('Marked image for deletion: $imageId');
    }
  }

  void unmarkImageForDeletion(String imageId) {
    _imagesToDelete.remove(imageId);
    print('Unmarked image for deletion: $imageId');
  }

  bool isImageMarkedForDeletion(String imageId) {
    return _imagesToDelete.contains(imageId);
  }

  Future<void> deleteExistingImage(String imageId) async {
    try {
      if (saleId == null) return;

      final result = await SalesService.deleteSaleImage(
        saleId: saleId!,
        imageId: imageId,
      );

      if (result['success']) {
        _existingImages.removeWhere((img) => img.id == imageId);
        _imagesToDelete.remove(imageId);

        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Image deleted successfully',
        );
      } else {
        throw Exception(result['data']?['message'] ?? 'Failed to delete image');
      }
    } catch (e) {
      print('Error deleting image: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to delete image: ${e.toString()}',
      );
    }
  }

  // New image picker methods
  Future<void> pickImageFromCamera() async {
    if (maxImagesReached) {
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
        message: 'Failed to capture image',
      );
    } finally {
      _isCompressing.value = false;
    }
  }

  Future<void> pickMultipleImages() async {
    if (maxImagesReached) {
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

        final int remainingSlots = maxImages - totalImagesCount;
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
          message: '${imagesToProcess.length} image(s) added',
        );
      }
    } catch (e) {
      print('Error picking multiple images: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to select images',
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
      }
    } catch (e) {
      print('Error processing image: $e');
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
        return compressedFile;
      } else {
        return File(image.path);
      }
    } catch (e) {
      print('Error compressing image: $e');
      return File(image.path);
    }
  }

  void removeNewImage(int index) {
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
      }
    } catch (e) {
      print('Error deleting temp file: $e');
    }
  }

  // Save updated sale
  Future<void> updateSale() async {
    if (!_validateForm()) return;

    _isSaving.value = true;

    try {
      // Prepare sale data
      final saleData = {
        'merchant': _selectedMerchantId.value,
        'yield_record': _selectedYieldId.value,
        'payment_mode': _selectedPaymentMode.value,
        'harvest_date': DateFormat('yyyy-MM-dd').format(_saleDate.value!),
        'total_calculated_amount': _totalAmount.value,
      };

      // Include variants if they exist
      if (_saleVariants.isNotEmpty) {
        saleData['variants'] =
            _saleVariants.map((v) => v.toCreateJson()).toList();
      }

      print('Updating sale with data: $saleData');

      // Call update API
      final result = await SalesService.updateSale(
        saleId: saleId!,
        saleData: saleData,
        saleImages:
            _compressedImageFiles.isNotEmpty ? _compressedImageFiles : null,
      );

      if (result['success']) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Sale updated successfully',
        );

        // Clean up and navigate back
        _cleanupCompressedFiles();
        Get.back(result: true); // Return true to indicate success
      } else {
        throw Exception(result['data']?['message'] ?? 'Failed to update sale');
      }
    } catch (e) {
      print('Error updating sale: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to update sale: ${e.toString()}',
      );
    } finally {
      _isSaving.value = false;
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

    if (_existingImages.isEmpty && _billImages.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please keep at least one image',
      );
      return false;
    }

    return true;
  }

  // Refresh methods
  Future<void> refreshData() async {
    loadInitialData();
  }

  // Navigation
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
                _cleanupCompressedFiles();
                Get.back(); // Go back to previous screen
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      _cleanupCompressedFiles();
      Get.back();
    }
  }

  // Helper getters
  bool get hasChanges {
    if (_currentSale.value == null) return false;

    return _selectedMerchantId.value != _currentSale.value!.merchantId ||
        _selectedYieldId.value != _currentSale.value!.yieldRecordId ||
        _selectedPaymentMode.value != _currentSale.value!.paymentMode ||
        _totalAmount.value != _currentSale.value!.totalCalculatedAmount ||
        _billImages.isNotEmpty ||
        _imagesToDelete.isNotEmpty;
  }

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

  String get formattedTotalAmount {
    return '₹${_totalAmount.value.toStringAsFixed(2)}';
  }

  String get imageSummary {
    final existing = _existingImages.length - _imagesToDelete.length;
    final newImages = _billImages.length;
    final total = existing + newImages;

    if (total == 0) return 'No images';
    return '$total image${total > 1 ? 's' : ''} ($existing existing, $newImages new)';
  }

  bool get hasMerchants => _merchants.isNotEmpty;
  bool get hasYields => _availableYields.isNotEmpty;
  bool get hasPaymentModes => _paymentModes.isNotEmpty;
  bool get canSave => !_isSaving.value && !_isLoading.value;
}
