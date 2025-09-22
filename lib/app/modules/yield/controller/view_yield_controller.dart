import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_handler/image_handler.dart';
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../../data/models/yield/yield_model.dart';
import '../../../data/services/yield/yield_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class YieldViewController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var filteredYields = <YieldModel>[].obs;
  var allYields = <YieldModel>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  // Filters
  var selectedCropId = Rxn<String>();
  var selectedFarmSegmentId = Rxn<String>();
  var selectedStartDate = Rxn<DateTime>();
  var selectedEndDate = Rxn<DateTime>();
  var filterHasBills = Rxn<bool>();

  // Form controllers
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadYields();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.YIELD) {
      refreshYields();
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  void onResume() {
    refreshYields();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Enhanced image URL processing for multiple images
  String processImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    print('processImageUrl: Empty or null URL');
    return '';
  }

  String cleanUrl = imageUrl.trim();
  print('processImageUrl: Processing URL: "$cleanUrl"');

  // If it's already a complete URL, return it
  if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
    print('processImageUrl: Complete URL found: $cleanUrl');
    return cleanUrl;
  }

  // If it starts with /, remove it to avoid double slashes
  if (cleanUrl.startsWith('/')) {
    cleanUrl = cleanUrl.substring(1);
  }

  // Construct full URL
  String fullUrl = '$baseImgUrl/$cleanUrl';

  print('processImageUrl: Constructed URL: $fullUrl from: $imageUrl');
  return fullUrl;
}

  // Process multiple image URLs (for arrays of images)
  List<String> processMultipleImageUrls(dynamic imageUrls) {
    List<String> processedUrls = [];

    if (imageUrls == null) {
      print('processMultipleImageUrls: imageUrls is null');
      return processedUrls;
    }

    // Handle different data types
    List<dynamic> urlList = [];

    if (imageUrls is String) {
      // Single URL as string
      if (imageUrls.isNotEmpty) {
        urlList.add(imageUrls);
      }
    } else if (imageUrls is List) {
      // Array of URLs
      urlList = imageUrls;
    } else if (imageUrls is Map) {
      // Handle case where it might be a map with URL values
      urlList = imageUrls.values.toList();
    }

    print('processMultipleImageUrls: Processing ${urlList.length} URLs');

    for (var url in urlList) {
      if (url != null && url.toString().isNotEmpty) {
        String processedUrl = processImageUrl(url.toString());
        if (processedUrl.isNotEmpty && isValidImageUrl(processedUrl)) {
          processedUrls.add(processedUrl);
          print('Added processed URL: $processedUrl');
        } else {
          print('Invalid URL after processing: $url -> $processedUrl');
        }
      }
    }

    print(
        'processMultipleImageUrls: Returning ${processedUrls.length} valid URLs');
    return processedUrls;
  }

  // Validate image URL
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      Uri? uri = Uri.tryParse(url);
      bool isValid = uri != null &&
          uri.hasScheme &&
          uri.host.isNotEmpty &&
          (uri.scheme == 'http' || uri.scheme == 'https');

      return isValid;
    } catch (e) {
      print('isValidImageUrl: Error validating URL "$url": $e');
      return false;
    }
  }

  // Get processed and validated image URL
  String? getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    String processedUrl = processImageUrl(imageUrl);
    return isValidImageUrl(processedUrl) ? processedUrl : null;
  }

  // Get multiple valid image URLs
  List<String> getValidImageUrls(dynamic imageUrls) {
    return processMultipleImageUrls(imageUrls);
  }

  // Extract bill URLs from yield data (handles multiple formats)
 List<String> extractBillUrls(Map<String, dynamic> yieldData) {
  List<String> billUrls = [];

  print('Extracting bill URLs from data: $yieldData');

  // Check different possible field names for bill URLs
  List<String> possibleFields = [
    'bill_urls',
    'billUrls', 
    'bill_url',
    'billUrl',
    'images',
    'bill_images',
    'billImages',
    'attachments',
    'files',
    'bill_image_urls'
  ];

  for (String field in possibleFields) {
    if (yieldData.containsKey(field) && yieldData[field] != null) {
      dynamic fieldValue = yieldData[field];
      print('Found field "$field" with value: $fieldValue');
      
      if (fieldValue is List) {
        // Handle array of URLs or objects
        for (var item in fieldValue) {
          if (item is String && item.isNotEmpty) {
            String processedUrl = processImageUrl(item);
            if (processedUrl.isNotEmpty && isValidImageUrl(processedUrl)) {
              billUrls.add(processedUrl);
            }
          } else if (item is Map && item.containsKey('image')) {
            // Handle bill image objects
            String? imageUrl = item['image'];
            if (imageUrl != null && imageUrl.isNotEmpty) {
              String processedUrl = processImageUrl(imageUrl);
              if (processedUrl.isNotEmpty && isValidImageUrl(processedUrl)) {
                billUrls.add(processedUrl);
              }
            }
          }
        }
      } else if (fieldValue is String && fieldValue.isNotEmpty) {
        // Handle single URL or comma-separated URLs
        if (fieldValue.contains(',')) {
          List<String> splitUrls = fieldValue.split(',')
              .map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .toList();
          
          for (String url in splitUrls) {
            String processedUrl = processImageUrl(url);
            if (processedUrl.isNotEmpty && isValidImageUrl(processedUrl)) {
              billUrls.add(processedUrl);
            }
          }
        } else {
          String processedUrl = processImageUrl(fieldValue);
          if (processedUrl.isNotEmpty && isValidImageUrl(processedUrl)) {
            billUrls.add(processedUrl);
          }
        }
      }
    }
  }

  // Remove duplicates
  billUrls = billUrls.toSet().toList();

  print('Final extracted URLs count: ${billUrls.length}');
  print('Final URLs: $billUrls');
  
  return billUrls;
}
  // Load yields from API with pagination and filters
  Future<void> loadYields() async {
    try {
      isLoading.value = true;

      print(
          'Loading yields - Page: ${currentPage.value}, Search: ${searchKeyword.value}');

      final response = await YieldService.getAllYields(
        cropId: selectedCropId.value,
        farmSegmentId: selectedFarmSegmentId.value,
        startDate: selectedStartDate.value != null
            ? YieldService.formatDateForApi(selectedStartDate.value!)
            : null,
        endDate: selectedEndDate.value != null
            ? YieldService.formatDateForApi(selectedEndDate.value!)
            : null,
        hasBills: filterHasBills.value,
        page: currentPage.value,
        pageSize: itemsPerPage,
      );

      print('Yields API Response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        print('Yields response data: $data');

        if (data != null) {
          List<dynamic> yieldsData = [];

          // Handle different API response structures
          if (data is List) {
            yieldsData = data;
            totalCount.value = yieldsData.length;
            print('Yields data is List with ${yieldsData.length} items');
          } else if (data is Map) {
            if (data.containsKey('yields')) {
              yieldsData = data['yields'] ?? [];
            } else if (data.containsKey('results')) {
              yieldsData = data['results'] ?? [];
            } else if (data.containsKey('data')) {
              if (data['data'] is List) {
                yieldsData = data['data'];
              } else {
                yieldsData = [data['data']];
              }
            } else {
              // Fallback - try to use the map data directly if it looks like yield data
              if (data.containsKey('harvest_date') || data.containsKey('id')) {
                yieldsData = [data];
              }
            }

            totalCount.value = data['count'] ??
                data['total'] ??
                data['total_count'] ??
                yieldsData.length;
            hasNext.value = data['has_next'] ?? false;
            hasPrevious.value = data['has_previous'] ?? false;
            totalPages.value = data['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());

            print(
                'Yields data is Map - yields count: ${yieldsData.length}, total: ${totalCount.value}');
          }

          // Convert to YieldModel objects using the model's fromJson factory
          List<YieldModel> yields = [];
          for (var yieldData in yieldsData) {
            try {
              if (yieldData is Map<String, dynamic>) {
                // Use the YieldModel's fromJson factory method instead of service method
                final yieldModel = YieldModel.fromJson(yieldData);
                yields.add(yieldModel);
                print(
                    'Parsed yield: ${yieldModel.cropName} - ${yieldModel.harvestDate}');
              } else {
                print('Invalid yield data format: $yieldData');
              }
            } catch (e) {
              print('Error parsing yield: $e');
              print('Yield data: $yieldData');
            }
          }

          // Apply search filter if needed
          if (searchKeyword.value.isNotEmpty) {
            yields = yields
                .where((currentYield) =>
                    currentYield.cropName
                        .toLowerCase()
                        .contains(searchKeyword.value.toLowerCase()) ||
                    // Fixed: Use farmSegmentNames instead of farmSegmentName
                    currentYield.farmSegmentNames.any((segment) => segment
                        .toLowerCase()
                        .contains(searchKeyword.value.toLowerCase())))
                .toList();
          }

          filteredYields.value = yields;
          allYields.value = yields;

          print('Final yields list count: ${filteredYields.length}');

          // Update pagination info if not already set
          if (totalPages.value <= 1) {
            totalPages.value = (totalCount.value / itemsPerPage).ceil();
          }
          hasPrevious.value = currentPage.value > 1;
          hasNext.value = currentPage.value < totalPages.value;
        } else {
          print('Yields response data is null');
          filteredYields.value = [];
          allYields.value = [];
          totalCount.value = 0;
        }
      } else {
        print('Yields API response not successful: $response');
        CustomSnackbar.showError(
          title: 'Error',
          message: response['data']?['message'] ?? 'Failed to load yields',
        );
        filteredYields.value = [];
        allYields.value = [];
        totalCount.value = 0;
      }
    } catch (e) {
      print('Error loading yields: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading yields: ${e.toString()}',
      );
      filteredYields.value = [];
      allYields.value = [];
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Get bill URLs for a specific yield using the model's billUrls getter
  List<String> getYieldBillUrls(YieldModel yield) {
  print('Getting bill URLs for yield ${yield.id}');
  
  // First, try to get URLs from the model's billUrls getter
  List<String> modelUrls = yield.billUrls;
  print('Model billUrls: $modelUrls');
  
  if (modelUrls.isNotEmpty) {
    // Process URLs to ensure they're complete
    List<String> processedUrls = modelUrls
        .where((url) => url.isNotEmpty)
        .map((url) => processImageUrl(url))
        .where((url) => url.isNotEmpty && isValidImageUrl(url))
        .toList();
    
    print('Processed URLs from model: $processedUrls');
    return processedUrls;
  }
  
  // Fallback: Try to extract from bill images directly
  if (yield.billImages.isNotEmpty) {
    List<String> imageUrls = yield.billImages
        .where((billImage) => billImage.imageUrl != null && billImage.imageUrl!.isNotEmpty)
        .map((billImage) => processImageUrl(billImage.imageUrl!))
        .where((url) => url.isNotEmpty && isValidImageUrl(url))
        .toList();
    
    print('Processed URLs from billImages: $imageUrls');
    return imageUrls;
  }
  
  // Last resort: Check if there are any raw image URLs in the data
  // This handles cases where the API might return URLs in unexpected formats
  if (yield.toJson().containsKey('bill_images') || 
      yield.toJson().containsKey('billUrls') || 
      yield.toJson().containsKey('images')) {
    
    Map<String, dynamic> yieldData = yield.toJson();
    List<String> extractedUrls = extractBillUrls(yieldData);
    print('Extracted URLs from raw data: $extractedUrls');
    return extractedUrls;
  }
  
  print('No bill URLs found for yield ${yield.id}');
  return [];
}

  // Search yields
  void runFilter(String keyword) {
    print('Running yield filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1;
    loadYields();
  }

  // Set filters
  void setCropFilter(String? cropId) {
    selectedCropId.value = cropId;
    currentPage.value = 1;
    loadYields();
  }

  void setFarmSegmentFilter(String? farmSegmentId) {
    selectedFarmSegmentId.value = farmSegmentId;
    currentPage.value = 1;
    loadYields();
  }

  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    currentPage.value = 1;
    loadYields();
  }

  void setBillsFilter(bool? hasBills) {
    filterHasBills.value = hasBills;
    currentPage.value = 1;
    loadYields();
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadYields();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadYields();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadYields();
    }
  }

  List<YieldModel> getPaginatedYields() {
    return filteredYields;
  }

  // Get yield details by ID using the model's fromJson method
  Future<YieldModel?> getYieldDetails(String yieldId) async {
    try {
      print('Fetching yield details for ID: $yieldId');

      final response = await YieldService.getYieldById(yieldId);

      print('Get yield details response: $response');

      if (response['success'] == true && response['data'] != null) {
        final yieldData = response['data'];

        // If the response has nested data structure
        final actualData = yieldData['data'] ?? yieldData;

        // Use YieldModel's fromJson factory method
        return YieldModel.fromJson(actualData);
      } else {
        String errorMessage = 'Failed to get yield details';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error fetching yield details: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error fetching yield details: ${e.toString()}');
    }
    return null;
  }

  // Delete yield
  Future<void> deleteYield(String yieldId) async {
    if (isDeleting.value) return;

    try {
      isDeleting.value = true;

      final response = await YieldService.deleteYield(yieldId);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Yield deleted successfully');
        refreshYields();
      } else {
        String errorMessage = 'Failed to delete yield';
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

  // Get bill images for a yield using the service
  Future<List<String>> getBillImagesForYield(String yieldId) async {
    try {
      final response = await YieldService.getBillImages(yieldId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Handle different response formats
        if (data['bill_images'] != null) {
          return processMultipleImageUrls(data['bill_images']);
        } else if (data['images'] != null) {
          return processMultipleImageUrls(data['images']);
        } else if (data['data'] != null) {
          return processMultipleImageUrls(data['data']);
        }
      }

      return [];
    } catch (e) {
      print('Error getting bill images: $e');
      return [];
    }
  }

  // Add bill images to yield - Fixed File import issue

  Future<void> addBillImagesToYield(
      String yieldId, List<dynamic> imageFiles) async {
    if (imageFiles.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select at least one image',
      );
      return;
    }

    try {
      // Convert List<dynamic> to List<File>
      final List<File> files = imageFiles.map((f) {
        if (f is File) return f;
        if (f is XFile) return File(f.path); // from image_picker
        throw Exception("Unsupported file type: ${f.runtimeType}");
      }).toList();

      final response = await YieldService.addBillImages(
        yieldId: yieldId,
        imageFiles: files, // ✅ Correct type
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Bill images added successfully',
        );
        refreshYields();
      } else {
        String errorMessage = 'Failed to add bill images';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  // Remove bill image from yield
  Future<void> removeBillImageFromYield(String yieldId, String imageId) async {
    try {
      final response = await YieldService.removeBillImage(
        yieldId: yieldId,
        imageId: imageId,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Bill image removed successfully',
        );
        refreshYields();
      } else {
        String errorMessage = 'Failed to remove bill image';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  // Replace all bill images for yield - Fixed File import issue

  Future<void> replaceBillImagesForYield(
      String yieldId, List<dynamic> imageFiles) async {
    if (imageFiles.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select at least one image',
      );
      return;
    }

    try {
      // Convert to List<File>
      final List<File> files = imageFiles.map((f) {
        if (f is File) return f;
        if (f is XFile) return File(f.path);
        throw Exception("Unsupported file type: ${f.runtimeType}");
      }).toList();

      final response = await YieldService.replaceBillImages(
        yieldId: yieldId,
        imageFiles: files,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Bill images replaced successfully',
        );
        refreshYields();
      } else {
        String errorMessage = 'Failed to replace bill images';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  // Bulk delete yields
  Future<void> bulkDeleteYields(List<String> yieldIds) async {
    if (yieldIds.isEmpty) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Please select yields to delete',
      );
      return;
    }

    try {
      isDeleting.value = true;

      final response = await YieldService.bulkDeleteYields(yieldIds);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: '${yieldIds.length} yields deleted successfully',
        );
        refreshYields();
      } else {
        String errorMessage = 'Failed to delete yields';
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

  // Navigate to edit yield
  void editYield(YieldModel editedYield) async {
    final result = await Get.toNamed(Routes.EDIT_YIELD, arguments: editedYield);

    if (result != null && result['success'] == true) {
      refreshYields();
    }
  }

  // Navigate to add yield
  void addNewYield() async {
    final result = await Get.toNamed(Routes.ADD_YIELD);

    if (result != null && result['success'] == true) {
      refreshYields();
    }
  }

  // Refresh yields list
  Future<void> refreshYields() async {
    print('Refreshing yields...');
    currentPage.value = 1;
    await loadYields();
  }

  // Clear all filters
  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    selectedCropId.value = null;
    selectedFarmSegmentId.value = null;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    filterHasBills.value = null;
    currentPage.value = 1;
    loadYields();
  }

  // Get summary text
  String getSummaryText() {
    String summary = 'Total: ${totalCount.value} yields';
    if (searchKeyword.value.isNotEmpty) {
      summary += ' (filtered)';
    }
    if (currentPage.value > 1 || hasNext.value) {
      summary += ' | Page ${currentPage.value} of ${totalPages.value}';
    }
    return summary;
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

      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error parsing date: $date, Error: $e');
      return 'Invalid Date';
    }
  }

  // Format harvest date for display
  String formatHarvestDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Get yield summary statistics
  Future<YieldSummary?> loadYieldSummary({
    String? cropId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await YieldService.getYieldSummary(
        cropId: cropId,
        startDate: startDate,
        endDate: endDate,
      );

      if (response['success'] == true) {
        print('Yield summary: ${response['data']}');
        // Use YieldSummary's fromJson factory method
        return YieldSummary.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error loading yield summary: $e');
      return null;
    }
  }

  // Helper method to get total quantity for a yield - Use model's getter
  double getTotalYieldQuantity(YieldModel yield) {
    return yield.totalQuantity; // Use the model's totalQuantity getter
  }

  // Helper method to get yield variants summary
  String getYieldVariantsSummary(YieldModel yield) {
    if (yield.yieldVariants.isEmpty) return 'No variants';

    if (yield.yieldVariants.length == 1) {
      final variant = yield.yieldVariants.first;
      return '${variant.quantity} ${variant.unit}';
    }

    return '${yield.yieldVariants.length} variants';
  }

  // Helper method to check if yield has bills - Use model's getter
  bool yieldHasBills(YieldModel yield) {
    return yield.hasBills; // Use the model's hasBills getter
  }

  // Helper method to get bill count - Use model's getter
  int getBillCount(YieldModel yield) {
    return yield.billCount; // Use the model's billCount getter
  }

  // Helper method to get farm segments names for a yield
  String getFarmSegmentsText(YieldModel yield) {
    // Use yieldFarmSegments and map to get farmSegmentName
    final segmentNames = yield.yieldFarmSegments
        .map((segment) => segment.farmSegmentName)
        .toList();

    if (segmentNames.isEmpty) return 'No segments';
    if (segmentNames.length == 1) return segmentNames.first;
    return '${segmentNames.length} segments';
  }

  // Helper method to get variants text
  String getVariantsText(YieldModel yield) {
    if (yield.yieldVariants.isEmpty) return 'No variants';

    List<String> variantTexts = yield.yieldVariants
        .map((variant) => '${variant.quantity} ${variant.unit}')
        .toList();

    return variantTexts.join(', ');
  }

  // Export helper - get all yields for export
  Future<List<YieldModel>> getAllYieldsForExport() async {
    try {
      final response = await YieldService.getAllYields();

      if (response['success'] == true && response['data'] != null) {
        // Parse the response data to YieldModel objects
        final data = response['data'];
        List<dynamic> yieldsData = [];

        if (data is List) {
          yieldsData = data;
        } else if (data is Map) {
          yieldsData = data['yields'] ?? data['results'] ?? data['data'] ?? [];
        }

        // Convert to YieldModel objects using the model's fromJson factory
        List<YieldModel> yields = [];
        for (var yieldData in yieldsData) {
          if (yieldData is Map<String, dynamic>) {
            yields.add(YieldModel.fromJson(yieldData));
          }
        }

        return yields;
      }

      return [];
    } catch (e) {
      print('Error getting all yields for export: $e');
      return [];
    }
  }
}
