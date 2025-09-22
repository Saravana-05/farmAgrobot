// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:intl/intl.dart';
// import '../../../core/values/app_colors.dart';
// import '../../../data/models/sales/sales_model.dart';
// import '../../../data/models/merchant/merchant_model.dart';
// import '../../../data/services/sales/sales_service.dart';
// import '../../../data/services/merchant/merchant_service.dart';
// import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
// import '../../../global_widgets/drawer/views/drawer.dart';
// import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
// import '../../../global_widgets/custom_snackbar/snackbar.dart';
// import '../../../routes/app_pages.dart';

// class EditSaleController extends GetxController {
//   final _isLoading = false.obs;
//   final _isCompressing = false.obs;
//   final _isUpdating = false.obs;
//   final _isLoadingMerchants = false.obs;
//   final _isLoadingYields = false.obs;
  
//   // Form data
//   final _selectedMerchantId = ''.obs;
//   final _selectedYieldId = ''.obs;
//   final _selectedPaymentMode = ''.obs;
//   final _saleDate = Rxn<DateTime>();
//   final _harvestDate = Rxn<DateTime>();
//   final _commission = 0.0.obs;
//   final _lorryRent = 0.0.obs;
//   final _coolyCharges = 0.0.obs;
//   final _totalAmount = 0.0.obs;
  
//   // Data lists
//   final _merchants = <Merchant>[].obs;
//   final _availableYields = <AvailableYield>[].obs;
//   final _paymentModes = <String>[].obs;
//   final _saleVariants = <SaleVariant>[].obs;
//   final _existingImages = <SaleImage>[].obs;
//   final _newImages = <XFile>[].obs;
//   final _compressedImageFiles = <File>[].obs;
//   final _imagesToDelete = <String>[].obs;
  
//   // Original sale data
//   SaleModel? _originalSale;
  
//   // Image picker
//   final ImagePicker _picker = ImagePicker();
//   static const int maxImages = 10;
  
//   // Text controllers
//   final TextEditingController saleDateController = TextEditingController();
//   final TextEditingController harvestDateController = TextEditingController();
//   final TextEditingController commissionController = TextEditingController();
//   final TextEditingController lorryRentController = TextEditingController();
//   final TextEditingController coolyChargesController = TextEditingController();
  
//   // Getters
//   bool get isLoading => _isLoading.value;
//   bool get isCompressing => _isCompressing.value;
//   bool get isUpdating => _isUpdating.value;
//   bool get isLoadingMerchants => _isLoadingMerchants.value;
//   bool get isLoadingYields => _isLoadingYields.value;
//   String get selectedMerchantId => _selectedMerchantId.value;
//   String get selectedYieldId => _selectedYieldId.value;
//   String get selectedPaymentMode => _selectedPaymentMode.value;
//   DateTime? get saleDate => _saleDate.value;
//   DateTime? get harvestDate => _harvestDate.value;
//   double get commission => _commission.value;
//   double get lorryRent => _lorryRent.value;
//   double get coolyCharges => _coolyCharges.value;
//   double get totalAmount => _totalAmount.value;
//   List<Merchant> get merchants => _merchants.toList();
//   List<AvailableYield> get availableYields => _availableYields.toList();
//   List<String> get paymentModes => _paymentModes.toList();
//   List<SaleVariant> get saleVariants => _saleVariants.toList();
//   List<SaleImage> get existingImages => _existingImages.toList();
//   List<XFile> get newImages => _newImages.toList();
//   List<File> get compressedImageFiles => _compressedImageFiles.toList();
  
//   // Calculated values
//   double get totalDeductions => commission + lorryRent + coolyCharges;
//   double get calculatedTotalFromVariants => 
//       saleVariants.fold(0.0, (sum, variant) => sum + (variant.quantity * variant.amountPerUnit));
//   double get finalAmount => calculatedTotalFromVariants - totalDeductions;
//   int get totalImageCount => existingImages.length + newImages.length;
//   bool get maxImagesReached => totalImageCount >= maxImages;
  
//   @override
//   void onInit() {
//     super.onInit();
//     _initializeWithSaleData();
//   }
  
//   @override
//   void onClose() {
//     _disposeControllers();
//     _cleanupCompressedFiles();
//     super.onClose();
//   }
  
//   void _disposeControllers() {
//     saleDateController.dispose();
//     harvestDateController.dispose();
//     commissionController.dispose();
//     lorryRentController.dispose();
//     coolyChargesController.dispose();
//   }
  
//   void _initializeWithSaleData() async {
//     final saleData = Get.arguments;
//     if (saleData == null || saleData is! SaleModel) {
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'No sale data provided',
//       );
//       Get.back();
//       return;
//     }
    
//     _originalSale = saleData;
//     await _loadInitialData();
//     _populateFormWithSaleData();
//   }
  
//   Future<void> _loadInitialData() async {
//     _isLoading.value = true;
//     try {
//       await Future.wait([
//         _loadMerchants(),
//         _loadPaymentModes(),
//         _loadAvailableYields(),
//       ]);
//     } catch (e) {
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'Failed to load data: ${e.toString()}',
//       );
//     } finally {
//       _isLoading.value = false;
//     }
//   }
  
//   void _populateFormWithSaleData() {
//     final sale = _originalSale!;
    
//     // Basic fields
//     _selectedMerchantId.value = sale.merchantId.toString();
//     _selectedYieldId.value = sale.yieldRecordId.toString();
//     _selectedPaymentMode.value = sale.paymentMode;
//     _saleDate.value = sale.createdAt;
//     _harvestDate.value = sale.harvestDate;
//     _commission.value = sale.commission;
//     _lorryRent.value = sale.lorryRent;
//     _coolyCharges.value = sale.coolyCharges;
//     _totalAmount.value = sale.totalCalculatedAmount;
    
//     // Controllers
//     saleDateController.text = DateFormat('dd/MM/yyyy').format(sale.createdAt ?? DateTime.now());
//     harvestDateController.text = DateFormat('dd/MM/yyyy').format(sale.harvestDate);
//     commissionController.text = sale.commission.toString();
//     lorryRentController.text = sale.lorryRent.toString();
//     coolyChargesController.text = sale.coolyCharges.toString();
    
//     // Sale variants
//     _saleVariants.value = List.from(sale.saleVariants);
    
//     // Existing images
//     _existingImages.value = List.from(sale.saleImages);
//   }
  
//   Future<void> _loadMerchants() async {
//     _isLoadingMerchants.value = true;
//     try {
//       final result = await MerchantService.getAllMerchants();
//       if (result['success'] && result['data'] != null) {
//         final responseData = result['data'];
//         List<dynamic> merchantList = responseData is List ? responseData : (responseData['data'] ?? []);
        
//         List<Merchant> parsedMerchants = [];
//         for (var merchantJson in merchantList) {
//           try {
//             parsedMerchants.add(Merchant.fromJson(merchantJson));
//           } catch (e) {
//             print('Error parsing merchant: $e');
//           }
//         }
//         _merchants.value = parsedMerchants;
//       }
//     } catch (e) {
//       print('Error loading merchants: $e');
//     } finally {
//       _isLoadingMerchants.value = false;
//     }
//   }
  
//   Future<void> _loadPaymentModes() async {
//     try {
//       final result = await SalesService.getPaymentModes();
//       if (result['success'] && result['data'] != null) {
//         final responseData = result['data'];
//         List<String> modes = responseData is Map && responseData['data'] is List
//             ? (responseData['data'] as List).cast<String>()
//             : ['Cash', 'Card', 'UPI', 'Online'];
//         _paymentModes.value = modes;
//       } else {
//         _paymentModes.value = ['Cash', 'Card', 'UPI', 'Online'];
//       }
//     } catch (e) {
//       _paymentModes.value = ['Cash', 'Card', 'UPI', 'Online'];
//     }
//   }
  
//   Future<void> _loadAvailableYields() async {
//     _isLoadingYields.value = true;
//     try {
//       final result = await SalesService.getAvailableYields();
//       if (result['success'] && result['data'] != null) {
//         final responseData = result['data'];
//         List<dynamic> yieldList = responseData is List ? responseData : (responseData['data'] ?? []);
        
//         List<AvailableYield> parsedYields = [];
//         for (var yieldJson in yieldList) {
//           try {
//             parsedYields.add(AvailableYield.fromJson(yieldJson));
//           } catch (e) {
//             print('Error parsing yield: $e');
//           }
//         }
//         _availableYields.value = parsedYields;
//       }
//     } catch (e) {
//       print('Error loading yields: $e');
//     } finally {
//       _isLoadingYields.value = false;
//     }
//   }
  
//   // Form field updates
//   void selectMerchant(String? merchantId) {
//     if (merchantId != null && merchantId.isNotEmpty) {
//       _selectedMerchantId.value = merchantId;
//     }
//   }
  
//   void selectYield(String? yieldId) {
//     if (yieldId != null && yieldId.isNotEmpty) {
//       _selectedYieldId.value = yieldId;
//     }
//   }
  
//   void selectPaymentMode(String? paymentMode) {
//     if (paymentMode != null && paymentMode.isNotEmpty) {
//       _selectedPaymentMode.value = paymentMode;
//     }
//   }
  
//   void selectSaleDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: Get.context!,
//       initialDate: _saleDate.value ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//       helpText: 'Select sale date',
//     );
    
//     if (picked != null) {
//       _saleDate.value = picked;
//       saleDateController.text = DateFormat('dd/MM/yyyy').format(picked);
//     }
//   }
  
//   void selectHarvestDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: Get.context!,
//       initialDate: _harvestDate.value ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//       helpText: 'Select harvest date',
//     );
    
//     if (picked != null) {
//       _harvestDate.value = picked;
//       harvestDateController.text = DateFormat('dd/MM/yyyy').format(picked);
//     }
//   }
  
//   void updateCommission(String value) {
//     final amount = double.tryParse(value) ?? 0.0;
//     _commission.value = amount;
//   }
  
//   void updateLorryRent(String value) {
//     final amount = double.tryParse(value) ?? 0.0;
//     _lorryRent.value = amount;
//   }
  
//   void updateCoolyCharges(String value) {
//     final amount = double.tryParse(value) ?? 0.0;
//     _coolyCharges.value = amount;
//   }
  
//   void updateVariantPrice(int index, String value) {
//     final price = double.tryParse(value) ?? 0.0;
//     if (index < _saleVariants.length) {
//       _saleVariants[index].amount = price;
//       _saleVariants.refresh();
//     }
//   }
  
//   void updateVariantQuantity(int index, String value) {
//     final quantity = double.tryParse(value) ?? 0.0;
//     if (index < _saleVariants.length) {
//       _saleVariants[index].quantity = quantity;
//       _saleVariants.refresh();
//     }
//   }
  
//   // Image management
//   Future<void> pickImageFromCamera() async {
//     if (maxImagesReached) {
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'Maximum $maxImages images are allowed',
//       );
//       return;
//     }
    
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
      
//       if (image != null) {
//         _isCompressing.value = true;
//         await _processAndAddImage(image);
//       }
//     } catch (e) {
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'Failed to capture image: ${e.toString()}',
//       );
//     } finally {
//       _isCompressing.value = false;
//     }
//   }
  
//   Future<void> pickMultipleImages() async {
//     if (maxImagesReached) {
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'Maximum $maxImages images are allowed',
//       );
//       return;
//     }
    
//     try {
//       final List<XFile> images = await _picker.pickMultiImage(
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
      
//       if (images.isNotEmpty) {
//         _isCompressing.value = true;
        
//         final int remainingSlots = maxImages - totalImageCount;
//         final List<XFile> imagesToProcess = images.take(remainingSlots).toList();
        
//         for (XFile image in imagesToProcess) {
//           await _processAndAddImage(image);
//         }
        
//         CustomSnackbar.showSuccess(
//           title: 'Success',
//           message: '${imagesToProcess.length} image(s) added successfully',
//         );
//       }
//     } catch (e) {
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'Failed to select images: ${e.toString()}',
//       );
//     } finally {
//       _isCompressing.value = false;
//     }
//   }
  
//   Future<void> _processAndAddImage(XFile image) async {
//     try {
//       final File? compressedFile = await _compressAndSaveImage(image);
//       if (compressedFile != null) {
//         _newImages.add(image);
//         _compressedImageFiles.add(compressedFile);
//       }
//     } catch (e) {
//       print('Error processing image: $e');
//     }
//   }
  
//   Future<File?> _compressAndSaveImage(XFile image) async {
//     try {
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final tempDir = Directory.systemTemp;
//       final fileName = 'edit_sale_image_compressed_${timestamp}.jpg';
//       final compressedPath = '${tempDir.path}/$fileName';
      
//       final compressedBytes = await FlutterImageCompress.compressWithFile(
//         image.path,
//         minWidth: 1024,
//         minHeight: 1024,
//         quality: 70,
//         format: CompressFormat.jpeg,
//       );
      
//       if (compressedBytes != null) {
//         final compressedFile = File(compressedPath);
//         await compressedFile.writeAsBytes(compressedBytes);
//         return compressedFile;
//       } else {
//         return File(image.path);
//       }
//     } catch (e) {
//       print('Error compressing image: $e');
//       return File(image.path);
//     }
//   }
  
//   void removeNewImage(int index) {
//     if (index >= 0 && index < _newImages.length) {
//       _newImages.removeAt(index);
//       if (index < _compressedImageFiles.length) {
//         final file = _compressedImageFiles.removeAt(index);
//         _deleteFileIfExists(file);
//       }
//     }
//   }
  
//   void removeExistingImage(int index) {
//     if (index >= 0 && index < _existingImages.length) {
//       final imageToDelete = _existingImages[index];
//       _imagesToDelete.add(imageToDelete.id);
//       _existingImages.removeAt(index);
//     }
//   }
  
//   void _cleanupCompressedFiles() {
//     for (final file in _compressedImageFiles) {
//       _deleteFileIfExists(file);
//     }
//     _compressedImageFiles.clear();
//   }
  
//   void _deleteFileIfExists(File file) {
//     try {
//       if (file.existsSync()) {
//         file.deleteSync();
//       }
//     } catch (e) {
//       print('Error deleting temp file: $e');
//     }
//   }
  
//   // Validation
//   bool _validateForm() {
//     if (_selectedMerchantId.value.isEmpty) {
//       CustomSnackbar.showError(title: 'Error', message: 'Please select a merchant');
//       return false;
//     }
    
//     if (_selectedYieldId.value.isEmpty) {
//       CustomSnackbar.showError(title: 'Error', message: 'Please select a yield record');
//       return false;
//     }
    
//     if (_selectedPaymentMode.value.isEmpty) {
//       CustomSnackbar.showError(title: 'Error', message: 'Please select a payment mode');
//       return false;
//     }
    
//     if (_saleDate.value == null) {
//       CustomSnackbar.showError(title: 'Error', message: 'Please select sale date');
//       return false;
//     }
    
//     if (_harvestDate.value == null) {
//       CustomSnackbar.showError(title: 'Error', message: 'Please select harvest date');
//       return false;
//     }
    
//     if (_saleVariants.isEmpty) {
//       CustomSnackbar.showError(title: 'Error', message: 'No sale variants found');
//       return false;
//     }
    
//     for (var variant in _saleVariants) {
//       if (variant.amount <= 0) {
//         CustomSnackbar.showError(
//           title: 'Error', 
//           message: 'Please set valid prices for all variants'
//         );
//         return false;
//       }
//       if (variant.quantity <= 0) {
//         CustomSnackbar.showError(
//           title: 'Error', 
//           message: 'Please set valid quantities for all variants'
//         );
//         return false;
//       }
//     }
    
//     if (totalImageCount == 0) {
//       CustomSnackbar.showError(title: 'Error', message: 'Please add at least one image');
//       return false;
//     }
    
//     return true;
//   }
  
//   // Submit update
//   Future<void> updateSale() async {
//     if (!_validateForm() || _isUpdating.value) return;
    
//     _isUpdating.value = true;
    
//     try {
//       // Prepare variant data
//       List<Map<String, dynamic>> variantData = _saleVariants.map((variant) => {
//         'crop_variant_id': int.tryParse(variant.cropVariantId.toString()) ?? 0,
//         'quantity': variant.quantity,
//         'amount': variant.amount,
//         'unit': variant.unit,
//       }).toList();
      
//       // Prepare sale data
//       Map<String, dynamic> updateData = {
//         'merchant': int.tryParse(_selectedMerchantId.value) ?? 0,
//         'yield_record': int.tryParse(_selectedYieldId.value) ?? 0,
//         'payment_mode': _selectedPaymentMode.value,
//         'harvest_date': SalesService.formatDateForApi(_harvestDate.value!),
//         'total_amount': calculatedTotalFromVariants,
//         'total_calculated_amount': calculatedTotalFromVariants,
//         'commission': _commission.value,
//         'lorry_rent': _lorryRent.value,
//         'cooly_charges': _coolyCharges.value,
//         'variants': variantData,
//       };
      
//       print('Updating sale with data: ${json.encode(updateData)}');
//       print('New images: ${_compressedImageFiles.length}');
//       print('Images to delete: ${_imagesToDelete.length}');
      
//       // Update sale
//       final result = await SalesService.updateSale(
//         saleId: _originalSale!.id,
//         saleData: updateData,
//         saleImages: _compressedImageFiles.isNotEmpty ? _compressedImageFiles : null,
//       );
      
//       if (result['success']) {
//         // Delete marked images
//         if (_imagesToDelete.isNotEmpty) {
//           for (String imageId in _imagesToDelete) {
//             try {
//               await SalesService.deleteSaleImage(
//                 saleId: _originalSale!.id,
//                 imageId: imageId,
//               );
//             } catch (e) {
//               print('Error deleting image $imageId: $e');
//             }
//           }
//         }
        
//         CustomSnackbar.showSuccess(
//           title: 'Success',
//           message: 'Sale updated successfully!',
//         );
        
//         Get.back(result: {'success': true, 'updated': true});
//       } else {
//         String errorMessage = result['data']['message'] ?? 'Failed to update sale';
        
//         if (result['data']['errors'] != null) {
//           final errors = result['data']['errors'] as Map<String, dynamic>;
//           if (errors.isNotEmpty) {
//             errorMessage = errors.values.first.toString();
//           }
//         }
        
//         CustomSnackbar.showError(
//           title: 'Update Failed',
//           message: errorMessage,
//         );
//       }
//     } catch (e) {
//       print('Error updating sale: $e');
//       CustomSnackbar.showError(
//         title: 'Error',
//         message: 'Network error occurred. Please try again.',
//       );
//     } finally {
//       _isUpdating.value = false;
//     }
//   }
  
//   // Helper getters
//   String get selectedMerchantName {
//     if (_selectedMerchantId.value.isEmpty) return '';
//     final merchant = _merchants.firstWhereOrNull((m) => m.id == _selectedMerchantId.value);
//     return merchant?.name ?? '';
//   }
  
//   String get selectedYieldName {
//     if (_selectedYieldId.value.isEmpty) return '';
//     final yieldRecord = _availableYields.firstWhereOrNull((y) => y.id == _selectedYieldId.value);
//     return yieldRecord?.cropName ?? '';
//   }
  
//   bool get hasChanges {
//     final sale = _originalSale!;
//     return _selectedMerchantId.value != sale.merchant.toString() ||
//            _selectedYieldId.value != sale.yieldRecord.toString() ||
//            _selectedPaymentMode.value != sale.paymentMode ||
//            _commission.value != sale.commission ||
//            _lorryRent.value != sale.lorryRent ||
//            _coolyCharges.value != sale.coolyCharges ||
//            _newImages.isNotEmpty ||
//            _imagesToDelete.isNotEmpty ||
//            _hasVariantChanges();
//   }
  
//   bool _hasVariantChanges() {
//     final originalVariants = _originalSale!.saleVariants;
//     if (originalVariants.length != _saleVariants.length) return true;
    
//     for (int i = 0; i < originalVariants.length; i++) {
//       final original = originalVariants[i];
//       final current = _saleVariants[i];
      
//       if (original.amount != current.amount || 
//           original.quantity != current.quantity) {
//         return true;
//       }
//     }
//     return false;
//   }
// }

// class EditSalesScreen extends StatelessWidget {
//   const EditSalesScreen({Key? key}) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(EditSaleController());
    
//     return Scaffold(
//       appBar: MenuAppBar(title: 'Edit Sale'),
//       endDrawer: MyDrawer(),
//       body: Obx(() {
//         if (controller.isLoading) {
//           return Center(child: CircularProgressIndicator());
//         }
        
//         return SingleChildScrollView(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Current total display
//               Card(
//                 color: kLightGreen,
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Current Sale Amount',
//                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           color: kSecondaryColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         '₹ ${controller.finalAmount.toStringAsFixed(2)}',
//                         style: Theme.of(context).textTheme.displaySmall?.copyWith(
//                           color: kPrimaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(height: 16),
              
//               // Basic Details Card
//               Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Basic Details',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: kSecondaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 16),
                      
//                       // Merchant dropdown
//                       DropdownButtonFormField<String>(
//                         value: controller.selectedMerchantId.isNotEmpty 
//                             ? controller.selectedMerchantId 
//                             : null,
//                         decoration: InputDecoration(
//                           labelText: 'Select Merchant *',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: controller.merchants.map((merchant) {
//                           return DropdownMenuItem(
//                             value: merchant.id,
//                             child: Text('${merchant.name} (${merchant.phone})'),
//                           );
//                         }).toList(),
//                         onChanged: controller.selectMerchant,
//                       ),
                      
//                       SizedBox(height: 16),
                      
//                       // Yield dropdown
//                       DropdownButtonFormField<String>(
//                         value: controller.selectedYieldId.isNotEmpty 
//                             ? controller.selectedYieldId 
//                             : null,
//                         decoration: InputDecoration(
//                           labelText: 'Select Yield Record *',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: controller.availableYields.map((yield) {
//                           return DropdownMenuItem(
//                             value: yield.id,
//                             child: Text(yield.displayText),
//                           );
//                         }).toList(),
//                         onChanged: controller.selectYield,
//                       ),
                      
//                       SizedBox(height: 16),
                      
//                       // Payment mode dropdown
//                       DropdownButtonFormField<String>(
//                         value: controller.selectedPaymentMode.isNotEmpty 
//                             ? controller.selectedPaymentMode 
//                             : null,
//                         decoration: InputDecoration(
//                           labelText: 'Payment Mode *',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: controller.paymentModes.map((mode) {
//                           return DropdownMenuItem(
//                             value: mode,
//                             child: Text(mode),
//                           );
//                         }).toList(),
//                         onChanged: controller.selectPaymentMode,
//                       ),
                      
//                       SizedBox(height: 16),
                      
//                       // Date fields
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: controller.saleDateController,
//                               decoration: InputDecoration(
//                                 labelText: 'Sale Date *',
//                                 border: OutlineInputBorder(),
//                                 suffixIcon: Icon(Icons.calendar_today),
//                               ),
//                               readOnly: true,
//                               onTap: controller.selectSaleDate,
//                             ),
//                           ),
//                           SizedBox(width: 16),
//                           Expanded(
//                             child: TextFormField(
//                               controller: controller.harvestDateController,
//                               decoration: InputDecoration(
//                                 labelText: 'Harvest Date *',
//                                 border: OutlineInputBorder(),
//                                 suffixIcon: Icon(Icons.calendar_today),
//                               ),
//                               readOnly: true,
//                               onTap: controller.selectHarvestDate,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(height: 16),
              
//               // Sale Variants Card
//               Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Sale Variants',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: kSecondaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'Update pricing and quantities for each variant',
//                         style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                       ),
//                       SizedBox(height: 16),
                      
//                       // Variants list
//                       ...controller.saleVariants.asMap().entries.map((entry) {
//                         int index = entry.key;
//                         SaleVariant variant = entry.value;
                        
//                         return Container(
//                           margin: EdgeInsets.only(bottom: 16),
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.grey.shade50,
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 variant.cropVariantName,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                   color: kSecondaryColor,
//                                 ),
//                               ),
//                               SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: TextFormField(
//                                       initialValue: variant.quantity.toString(),
//                                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                                       decoration: InputDecoration(
//                                         labelText: 'Quantity',
//                                         border: OutlineInputBorder(),
//                                         suffixText: variant.unit,
//                                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                       ),
//                                       onChanged: (value) => controller.updateVariantQuantity(index, value),
//                                     ),
//                                   ),
//                                   SizedBox(width: 16),
//                                   Expanded(
//                                     child: TextFormField(
//                                       initialValue: variant.amount.toString(),
//                                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                                       decoration: InputDecoration(
//                                         labelText: 'Price per ${variant.unit}',
//                                         border: OutlineInputBorder(),
//                                         prefixText: '₹ ',
//                                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                       ),
//                                       onChanged: (value) => controller.updateVariantPrice(index, value),
//                                     ),
//                                   ),
//                                   SizedBox(width: 16),
//                                   Container(
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: kLightGreen,
//                                       borderRadius: BorderRadius.circular(4),
//                                       border: Border.all(color: kPrimaryColor, width: 1),
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Total',
//                                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                                         ),
//                                         Text(
//                                           '₹ ${(variant.quantity * variant.amount).toStringAsFixed(2)}',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 14,
//                                             color: kSecondaryColor,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         );
//                       }).toList(),
                      
//                       // Total from variants
//                       Container(
//                         padding: EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: kLightGreen,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: kPrimaryColor),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Total from Variants:',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 16,
//                                 color: kSecondaryColor,
//                               ),
//                             ),
//                             Text(
//                               '₹ ${controller.calculatedTotalFromVariants.toStringAsFixed(2)}',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                                 color: kPrimaryColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(height: 16),
              
//               // Deductions Card
//               Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Deductions',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: kSecondaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 16),
                      
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: controller.commissionController,
//                               keyboardType: TextInputType.numberWithOptions(decimal: true),
//                               decoration: InputDecoration(
//                                 labelText: 'Commission',
//                                 border: OutlineInputBorder(),
//                                 prefixText: '₹ ',
//                               ),
//                               onChanged: controller.updateCommission,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: TextFormField(
//                               controller: controller.lorryRentController,
//                               keyboardType: TextInputType.numberWithOptions(decimal: true),
//                               decoration: InputDecoration(
//                                 labelText: 'Lorry Rent',
//                                 border: OutlineInputBorder(),
//                                 prefixText: '₹ ',
//                               ),
//                               onChanged: controller.updateLorryRent,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: TextFormField(
//                               controller: controller.coolyChargesController,
//                               keyboardType: TextInputType.numberWithOptions(decimal: true),
//                               decoration: InputDecoration(
//                                 labelText: 'Cooly Charges',
//                                 border: OutlineInputBorder(),
//                                 prefixText: '₹ ',
//                               ),
//                               onChanged: controller.updateCoolyCharges,
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       SizedBox(height: 16),
                      
//                       // Total deductions
//                       Container(
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.red.shade300),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Total Deductions:',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.red.shade700,
//                               ),
//                             ),
//                             Text(
//                               '₹ ${controller.totalDeductions.toStringAsFixed(2)}',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.red.shade700,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(height: 16),
              
//               // Images Card
//               Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Sale Images (${controller.totalImageCount}/10)',
//                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               color: kSecondaryColor,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           if (controller.isCompressing)
//                             SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                         ],
//                       ),
//                       SizedBox(height: 16),
                      
//                       // Image picker buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: controller.maxImagesReached ? null : controller.pickImageFromCamera,
//                               icon: Icon(Icons.camera_alt),
//                               label: Text('Camera'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kSecondaryColor,
//                                 foregroundColor: Colors.white,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: controller.maxImagesReached ? null : controller.pickMultipleImages,
//                               icon: Icon(Icons.photo_library),
//                               label: Text('Gallery'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: kPrimaryColor,
//                                 foregroundColor: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       if (controller.maxImagesReached)
//                         Padding(
//                           padding: EdgeInsets.only(top: 8),
//                           child: Text(
//                             'Maximum 10 images allowed',
//                             style: TextStyle(color: Colors.orange, fontSize: 12),
//                           ),
//                         ),
                      
//                       SizedBox(height: 16),
                      
//                       // Existing images
//                       if (controller.existingImages.isNotEmpty) ...[
//                         Text(
//                           'Current Images (${controller.existingImages.length})',
//                           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//                         ),
//                         SizedBox(height: 8),
//                         GridView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 3,
//                             crossAxisSpacing: 8,
//                             mainAxisSpacing: 8,
//                           ),
//                           itemCount: controller.existingImages.length,
//                           itemBuilder: (context, index) {
//                             final image = controller.existingImages[index];
//                             return Stack(
//                               children: [
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     border: Border.all(color: Colors.grey),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.network(
//                                       image.imageUrl.startsWith('http') 
//                                           ? image.imageUrl 
//                                           : 'https://your-base-url.com/${image.imageUrl}',
//                                       fit: BoxFit.cover,
//                                       width: double.infinity,
//                                       height: double.infinity,
//                                       errorBuilder: (context, error, stackTrace) {
//                                         return Container(
//                                           color: Colors.grey[300],
//                                           child: Icon(Icons.error),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                                 Positioned(
//                                   top: 4,
//                                   right: 4,
//                                   child: GestureDetector(
//                                     onTap: () => controller.removeExistingImage(index),
//                                     child: Container(
//                                       padding: EdgeInsets.all(4),
//                                       decoration: BoxDecoration(
//                                         color: Colors.red,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Icon(Icons.close, color: Colors.white, size: 16),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                         SizedBox(height: 16),
//                       ],
                      
//                       // New images
//                       if (controller.newImages.isNotEmpty) ...[
//                         Text(
//                           'New Images (${controller.newImages.length})',
//                           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//                         ),
//                         SizedBox(height: 8),
//                         GridView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 3,
//                             crossAxisSpacing: 8,
//                             mainAxisSpacing: 8,
//                           ),
//                           itemCount: controller.newImages.length,
//                           itemBuilder: (context, index) {
//                             final image = controller.newImages[index];
//                             return Stack(
//                               children: [
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     border: Border.all(color: Colors.grey),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.file(
//                                       File(image.path),
//                                       fit: BoxFit.cover,
//                                       width: double.infinity,
//                                       height: double.infinity,
//                                       errorBuilder: (context, error, stackTrace) {
//                                         return Container(
//                                           color: Colors.grey[300],
//                                           child: Icon(Icons.error),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                                 Positioned(
//                                   top: 4,
//                                   right: 4,
//                                   child: GestureDetector(
//                                     onTap: () => controller.removeNewImage(index),
//                                     child: Container(
//                                       padding: EdgeInsets.all(4),
//                                       decoration: BoxDecoration(
//                                         color: Colors.red,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Icon(Icons.close, color: Colors.white, size: 16),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                         SizedBox(height: 16),
//                       ],
                      
//                       if (controller.totalImageCount == 0)
//                         Container(
//                           padding: EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(Icons.image, size: 48, color: Colors.grey),
//                               SizedBox(height: 8),
//                               Text(
//                                 'No images selected',
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(height: 16),
              
//               // Final calculation summary
//               Card(
//                 color: kLightGreen,
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Final Calculation Summary',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: kPrimaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Variants Total:',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                           ),
//                           Text(
//                             '₹ ${controller.calculatedTotalFromVariants.toStringAsFixed(2)}',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Total Deductions:',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red.shade700),
//                           ),
//                           Text(
//                             '- ₹ ${controller.totalDeductions.toStringAsFixed(2)}',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade700),
//                           ),
//                         ],
//                       ),
//                       Divider(height: 24, thickness: 2),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Final Amount:',
//                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: kSecondaryColor,
//                             ),
//                           ),
//                           Text(
//                             '₹ ${controller.finalAmount.toStringAsFixed(2)}',
//                             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: kSecondaryColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               SizedBox(height: 24),
              
//               // Update button
//               CustomElevatedButton(
//                 text: controller.isUpdating ? 'Updating...' : 'Update Sale',
//                 onPressed: controller.isUpdating ? null : controller.updateSale,
//                 backgroundColor: controller.isUpdating ? Colors.grey : kSecondaryColor,
//                 textColor: kLightColor,
//               ),
              
//               SizedBox(height: 8),
              
//               // Changes indicator
//               if (controller.hasChanges)
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.orange.shade300),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info, color: Colors.orange.shade700, size: 20),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'You have unsaved changes',
//                           style: TextStyle(
//                             color: Colors.orange.shade700,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
              
//               SizedBox(height: 24),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }