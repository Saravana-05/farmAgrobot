import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../data/services/crops/crop_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';
import '../views/crop_edit_screen.dart';

class CropsViewController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var filteredCrops = <Crop>[].obs;
  var allCrops = <Crop>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;
  var selectedImageFile = Rxn<File>();

  // Form controllers for add/edit crop
  final cropNameController = TextEditingController();
  final searchController = TextEditingController();

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadCrops();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.CROPS) {
      refreshCrops();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Don't call loadCrops again here since onInit already does it
  }

  void onResume() {
    refreshCrops();
  }

  @override
  void onClose() {
    cropNameController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Load crops from API with pagination
  Future<void> loadCrops() async {
    try {
      isLoading.value = true;

      print(
          'Loading crops - Page: ${currentPage.value}, Search: ${searchKeyword.value}');

      final response = await CropService.getAllCrops(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
      );

      print('API Response: ${response}'); // Debug log

      if (response['success'] == true) {
        final data = response['data'];
        print('Response data: $data'); // Debug log

        if (data != null) {
          List<dynamic> cropsData = [];

          // Handle different API response structures
          if (data is List) {
            // Data is directly a list of crops
            cropsData = data;
            totalCount.value = cropsData.length;
            print('Data is List with ${cropsData.length} items');
          } else if (data is Map) {
            // Data contains pagination info or nested structure
            if (data.containsKey('crops')) {
              cropsData = data['crops'] ?? [];
            } else if (data.containsKey('results')) {
              cropsData = data['results'] ?? [];
            } else if (data.containsKey('data')) {
              cropsData = data['data'] ?? [];
            } else {
              // Fallback - try to use the map data directly if it looks like crop data
              if (data.containsKey('crop_name') || data.containsKey('id')) {
                cropsData = [data];
              }
            }

            totalCount.value =
                data['total'] ?? data['count'] ?? cropsData.length;
            hasNext.value = data['has_next'] ?? false;
            hasPrevious.value = data['has_previous'] ?? false;
            totalPages.value = data['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());

            print(
                'Data is Map - crops count: ${cropsData.length}, total: ${totalCount.value}');
          }

          // Convert to Crop objects
          List<Crop> crops = [];
          for (var cropData in cropsData) {
            try {
              if (cropData is Map<String, dynamic>) {
                final crop = CropService.cropFromJson(cropData);
                crops.add(crop);
                print('Parsed crop: ${crop.cropName}');
              } else {
                print('Invalid crop data format: ${cropData}');
              }
            } catch (e) {
              print('Error parsing crop: $e');
              print('Crop data: $cropData');
            }
          }

          filteredCrops.value = crops;
          allCrops.value = crops;

          print('Final crops list count: ${filteredCrops.length}');

          // Update pagination info if not already set
          if (totalPages.value <= 1) {
            totalPages.value = (totalCount.value / itemsPerPage).ceil();
          }
          hasPrevious.value = currentPage.value > 1;
          hasNext.value = currentPage.value < totalPages.value;
        } else {
          print('Response data is null');
          filteredCrops.value = [];
          allCrops.value = [];
          totalCount.value = 0;
        }
      } else {
        print('API response not successful: ${response}');
        CustomSnackbar.showError(
          title: 'Error',
          message: response['data']?['message'] ?? 'Failed to load crops',
        );
        filteredCrops.value = [];
        allCrops.value = [];
        totalCount.value = 0;
      }
    } catch (e) {
      print('Error loading crops: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading crops: ${e.toString()}',
      );
      filteredCrops.value = [];
      allCrops.value = [];
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Search crops
  void runFilter(String keyword) {
    print('Running filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1;
    loadCrops();
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadCrops();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadCrops();
    }
  }

  List<Crop> getPaginatedCrops() {
    return filteredCrops;
  }

  // Image selection methods
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        File imageFile = File(image.path);

        // Validate image
        if (!CropService.isValidImageFile(imageFile)) {
          CustomSnackbar.showError(
              title: 'Invalid Image',
              message:
                  'Please select a valid image file (jpg, jpeg, png, gif, webp)');
          return;
        }

        // Validate image size
        if (!CropService.isValidImageSize(imageFile)) {
          CustomSnackbar.showError(
              title: 'Image Too Large',
              message: 'Please select an image smaller than 10MB');
          return;
        }

        selectedImageFile.value = imageFile;
      }
    } catch (e) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        File imageFile = File(image.path);

        // Validate image
        if (!CropService.isValidImageFile(imageFile)) {
          CustomSnackbar.showError(
              title: 'Invalid Image',
              message: 'Please select a valid image file');
          return;
        }

        // Validate image size
        if (!CropService.isValidImageSize(imageFile)) {
          CustomSnackbar.showError(
              title: 'Image Too Large',
              message: 'Please select an image smaller than 10MB');
          return;
        }

        selectedImageFile.value = imageFile;
      }
    } catch (e) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Failed to take photo: ${e.toString()}');
    }
  }

  void removeSelectedImage() {
    selectedImageFile.value = null;
  }

  // Add new crop
  Future<void> addCrop() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare crop data
      Map<String, dynamic> cropData = {
        'crop_name': cropNameController.text.trim(),
      };

      // Validate crop data
      final validationErrors = CropService.validateCropData(cropData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Save crop with optional image
      final response = await CropService.saveCrop(
        cropData: cropData,
        imageFile: selectedImageFile.value,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop added successfully');

        // Clear form and refresh list
        clearForm();
        refreshCrops();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to add crop';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  // Update existing crop
  Future<void> updateCrop(String cropId) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare crop data
      Map<String, dynamic> cropData = {
        'crop_name': cropNameController.text.trim(),
      };

      // Validate crop data
      final validationErrors = CropService.validateCropData(cropData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Update crop with optional image
      final response = await CropService.updateCrop(
        cropId: cropId,
        cropData: cropData,
        imageFile: selectedImageFile.value,
        removeImage: false, // You can add logic for this if needed
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshCrops();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to update crop';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  // Delete crop
  Future<void> deleteCrop(String cropId) async {
    if (isDeleting.value) return;

    try {
      isDeleting.value = true;

      final response = await CropService.deleteCrop(cropId: cropId);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop deleted successfully');
        refreshCrops();
      } else {
        String errorMessage = 'Failed to delete crop';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isDeleting.value = false;
    }
  }

  // View crop details
  void viewCrop(Crop crop) {
    Get.dialog(
      AlertDialog(
        title: Text(crop.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${crop.id}'),
              SizedBox(height: 8),
              Text('Name: ${crop.displayName}'),
              SizedBox(height: 8),
              Text('Created: ${crop.formattedCreatedAt}'),
              SizedBox(height: 8),
              Text('Updated: ${crop.formattedUpdatedAt}'),
              SizedBox(height: 8),
              Text('Has Image: ${crop.hasImage ? "Yes" : "No"}'),
              if (crop.hasImage && crop.imageUrl != null) ...[
                SizedBox(height: 12),
                Text('Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(
                    crop.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image, size: 50),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Edit crop - populate form with existing data
  Future<void> editCrop(Crop crop) async {
    final result = await Get.to(() => CropEditScreen(), arguments: crop);

    if (result != null && result['success'] == true) {
      // Refresh the crops list
      refreshCrops();
    }
  }

  Future<void> handleEditCrop(Crop crop) async {
    print('🔍 DEBUG: handleEditCrop called');
    print('🔍 DEBUG: Crop ID: "${crop.id}"');
    print('🔍 DEBUG: Crop Name: "${crop.cropName}"');
    print('🔍 DEBUG: Crop hasImage: ${crop.hasImage}');
    print('🔍 DEBUG: Full crop object: $crop');
    try {
      isLoading.value = true;

      // First, fetch the latest crop details from API
      final cropDetails = await getCropDetails(crop.id.toString());

      if (cropDetails != null) {
        // Populate the form with existing data
        populateFormWithCropData(cropDetails);

        // Navigate to edit screen with the crop data
        final result = await Get.toNamed(Routes.EDIT_CROPS,
            arguments: {'crop': cropDetails, 'mode': 'edit'});

        // If edit was successful, refresh the list
        if (result != null && result['success'] == true) {
          refreshCrops();
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to load crop details: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with existing crop data
  void populateFormWithCropData(Crop crop) {
    cropNameController.text = crop.cropName;
    // If there's an existing image, you might want to handle it
    // selectedImageFile.value = null; // Reset selected image
  }

// Enhanced getCropDetails method with better error handling
  Future<Crop?> getCropDetails(String cropId) async {
    try {
      print('Fetching crop details for ID: $cropId');

      final response = await CropService.getCropById(cropId);

      print('Get crop details response: $response');

      if (response['success'] == true && response['data'] != null) {
        return CropService.cropFromJson(response['data']);
      } else {
        String errorMessage = 'Failed to get crop details';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error fetching crop details: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error fetching crop details: ${e.toString()}');
    }
    return null;
  }

// Method to handle update from edit screen
  Future<void> handleUpdateCrop(
      String cropId, Map<String, dynamic> updatedData) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;
      print('Updating crop $cropId with data: $updatedData');

      // Validate crop data
      final validationErrors = CropService.validateCropData(updatedData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Call the update API
      final response = await CropService.updateCrop(
        cropId: cropId,
        cropData: updatedData,
        imageFile: selectedImageFile.value,
        removeImage: false,
      );

      print('Update crop response: $response');

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Crop updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshCrops();
        Get.back(result: {'success': true});
      } else {
        String errorMessage = 'Failed to update crop';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error updating crop: $e');
      CustomSnackbar.showError(
          title: 'Error', message: 'Error updating crop: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  // Clear form
  void clearForm() {
    cropNameController.clear();
    selectedImageFile.value = null;
  }

  // Refresh crops list
  Future<void> refreshCrops() async {
    print('Refreshing crops...');
    currentPage.value = 1;
    await loadCrops();
  }

  // Clear search filter
  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    currentPage.value = 1;
    loadCrops();
  }

  // Get summary text
  String getSummaryText() {
    return 'Total: ${totalCount.value} crops';
  }

  // Format timestamp
  String formatTimestamp(dynamic date) {
    if (date == null) {
      return 'No Date';
    }

    DateTime? dateTime;

    try {
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        if (date.isEmpty) {
          return 'No Date';
        }
        dateTime = DateTime.parse(date);
      } else if (date is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return 'Invalid Date';
      }

      if (dateTime == null) {
        return 'No Date';
      }

      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error parsing date: $date, Error: $e');
      return 'Invalid Date';
    }
  }
}
