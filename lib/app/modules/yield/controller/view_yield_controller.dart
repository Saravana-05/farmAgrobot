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

  // ✅ NEW: Better state management for "show all"
  var showAllRecords = false.obs;
  var isLoadingAllRecords = false.obs;

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
            List<String> splitUrls = fieldValue
                .split(',')
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

  // ✅ IMPROVED: Load yields with proper pagination
  Future<void> loadYields() async {
    try {
      isLoading.value = true;

      print('=== LOAD YIELDS ===');
      print('Current Page: ${currentPage.value}');
      print('Items Per Page: $itemsPerPage');
      print('Show All Records: ${showAllRecords.value}');
      print('Search Keyword: "${searchKeyword.value}"');

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

      print('Response received: ${response['statusCode']}');

      if (response['success'] == true) {
        final data = response['data'];

        if (data != null && data is Map<String, dynamic>) {
          List<dynamic> yieldsData = [];

          // ✅ Extract yields list
          if (data.containsKey('data') && data['data'] is List) {
            yieldsData = data['data'];
          } else if (data.containsKey('results')) {
            yieldsData = data['results'];
          }

          // ✅ Extract pagination metadata (matching backend exactly)
          totalCount.value = data['total_count'] ?? yieldsData.length;
          totalPages.value = data['total_pages'] ?? 1;
          hasNext.value =
              data['has_next'] ?? (currentPage.value < totalPages.value);
          hasPrevious.value = data['has_previous'] ?? (currentPage.value > 1);

          print('Pagination Info:');
          print('  Total Count: ${totalCount.value}');
          print('  Total Pages: ${totalPages.value}');
          print('  Current Page: ${currentPage.value}');
          print('  Has Next: ${hasNext.value}');
          print('  Has Previous: ${hasPrevious.value}');

          // ✅ Convert to model objects
          List<YieldModel> yields = yieldsData
              .map((item) {
                try {
                  return YieldModel.fromJson(Map<String, dynamic>.from(item));
                } catch (e) {
                  print('Error parsing yield: $e');
                  return null;
                }
              })
              .whereType<YieldModel>()
              .toList();

          // ✅ Apply search filter locally
          if (searchKeyword.value.isNotEmpty) {
            yields = yields.where((currentYield) {
              final query = searchKeyword.value.toLowerCase();
              return currentYield.cropName.toLowerCase().contains(query) ||
                  currentYield.farmSegmentNames
                      .any((segment) => segment.toLowerCase().contains(query));
            }).toList();
          }

          filteredYields.value = yields;
          print('Loaded ${yields.length} yields for current page');
        } else {
          print('Response data is null or invalid');
          _resetYieldsData();
        }
      } else {
        print('API request failed');
        CustomSnackbar.showError(
          title: 'Error',
          message: response['data']?['message'] ?? 'Failed to load yields',
        );
        _resetYieldsData();
      }
    } catch (e) {
      print('Error loading yields: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading yields: ${e.toString()}',
      );
      _resetYieldsData();
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: Load ALL records (fetches all pages automatically)
  Future<void> loadAllYields() async {
    try {
      isLoadingAllRecords.value = true;

      print('=== LOADING ALL YIELDS ===');

      List<YieldModel> allLoadedYields = [];
      int page = 1;
      bool hasMore = true;
      int totalFetched = 0;

      while (hasMore) {
        print('Fetching page $page...');

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
          page: page,
          pageSize: itemsPerPage,
        );

        if (response['success'] != true) {
          print('Failed to fetch page $page');
          break;
        }

        final data = response['data'];
        List<dynamic> yieldsData = [];

        if (data is List) {
          yieldsData = data;
        } else if (data is Map) {
          yieldsData = data['yields'] ?? data['results'] ?? data['data'] ?? [];

          // Update total count from first page
          if (page == 1) {
            totalCount.value =
                data['count'] ?? data['total'] ?? data['total_count'] ?? 0;
            totalPages.value = data['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());
          }

          // Check if there are more pages
          hasMore = data['has_next'] ?? data['next'] != null ?? false;
        }

        // Parse yields for this page
        for (var yieldData in yieldsData) {
          try {
            if (yieldData is Map<String, dynamic>) {
              allLoadedYields.add(YieldModel.fromJson(yieldData));
            }
          } catch (e) {
            print('Error parsing yield: $e');
          }
        }

        totalFetched += yieldsData.length;
        print(
            'Fetched page $page: ${yieldsData.length} yields (Total: $totalFetched)');

        // Safety check
        if (page > 100) {
          print('Safety limit reached (100 pages)');
          break;
        }

        if (hasMore) {
          page++;
        }
      }

      print('Finished loading all yields: ${allLoadedYields.length} records');

      // Apply local search filter if needed
      if (searchKeyword.value.isNotEmpty) {
        allLoadedYields = allLoadedYields
            .where((currentYield) =>
                currentYield.cropName
                    .toLowerCase()
                    .contains(searchKeyword.value.toLowerCase()) ||
                currentYield.farmSegmentNames.any((segment) => segment
                    .toLowerCase()
                    .contains(searchKeyword.value.toLowerCase())))
            .toList();
      }

      allYields.value = allLoadedYields;
      filteredYields.value = allLoadedYields;

      // Update UI state for "show all" mode
      showAllRecords.value = true;
      currentPage.value = 1;
      hasNext.value = false;
      hasPrevious.value = false;

      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Loaded all ${allLoadedYields.length} yields',
      );
    } catch (e) {
      print('Error loading all yields: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading all yields: ${e.toString()}',
      );
    } finally {
      isLoadingAllRecords.value = false;
    }
  }

  // ✅ IMPROVED: Toggle between paginated and "show all" modes
  void toggleShowAll() async {
    if (showAllRecords.value) {
      // Switch back to paginated mode
      showAllRecords.value = false;
      currentPage.value = 1;
      allYields.value = [];
      await loadYields(); // Load first page
    } else {
      // Switch to "show all" mode
      await loadAllYields(); // Fetch all pages
    }
  }

  // Helper to reset yields data
  void _resetYieldsData() {
    filteredYields.value = [];
    allYields.value = [];
    totalCount.value = 0;
    totalPages.value = 1;
    hasNext.value = false;
    hasPrevious.value = false;
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
          .where((billImage) =>
              billImage.imageUrl != null && billImage.imageUrl!.isNotEmpty)
          .map((billImage) => processImageUrl(billImage.imageUrl!))
          .where((url) => url.isNotEmpty && isValidImageUrl(url))
          .toList();

      print('Processed URLs from billImages: $imageUrls');
      return imageUrls;
    }

    print('No bill URLs found for yield ${yield.id}');
    return [];
  }

  // Search yields
  void runFilter(String keyword) {
    print('Running yield filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1;

    if (showAllRecords.value) {
      // Re-filter the all yields list locally
      if (keyword.isEmpty) {
        filteredYields.value = allYields;
      } else {
        filteredYields.value = allYields
            .where((currentYield) =>
                currentYield.cropName
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                currentYield.farmSegmentNames.any((segment) =>
                    segment.toLowerCase().contains(keyword.toLowerCase())))
            .toList();
      }
    } else {
      // Reload from server with new search
      loadYields();
    }
  }

  // Set filters
  void setCropFilter(String? cropId) {
    selectedCropId.value = cropId;
    currentPage.value = 1;
    showAllRecords.value = false; // Reset to paginated mode
    loadYields();
  }

  void setFarmSegmentFilter(String? farmSegmentId) {
    selectedFarmSegmentId.value = farmSegmentId;
    currentPage.value = 1;
    showAllRecords.value = false;
    loadYields();
  }

  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    currentPage.value = 1;
    showAllRecords.value = false;
    loadYields();
  }

  void setBillsFilter(bool? hasBills) {
    filterHasBills.value = hasBills;
    currentPage.value = 1;
    showAllRecords.value = false;
    loadYields();
  }

  // ✅ IMPROVED: Pagination methods
  void nextPage() {
    if (showAllRecords.value) return;
    if (hasNext.value && currentPage.value < totalPages.value) {
      currentPage.value++;
      loadYields();
    }
  }

  void previousPage() {
    if (showAllRecords.value) return;
    if (hasPrevious.value && currentPage.value > 1) {
      currentPage.value--;
      loadYields();
    }
  }

  void goToPage(int page) {
    if (showAllRecords.value) return;

    if (page >= 1 && page <= totalPages.value && page != currentPage.value) {
      currentPage.value = page;
      loadYields();
    }
  }

  void goToFirstPage() {
    if (showAllRecords.value) return;
    goToPage(1);
  }

  void goToLastPage() {
    if (showAllRecords.value) return;
    goToPage(totalPages.value);
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
        final actualData = yieldData['data'] ?? yieldData;
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
      final List<File> files = imageFiles.map((f) {
        if (f is File) return f;
        if (f is XFile) return File(f.path);
        throw Exception("Unsupported file type: ${f.runtimeType}");
      }).toList();

      final response = await YieldService.addBillImages(
        yieldId: yieldId,
        imageFiles: files,
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

  void editYield(YieldModel editedYield) async {
    final result = await Get.toNamed(Routes.EDIT_YIELD, arguments: editedYield);

    if (result != null && result['success'] == true) {
      refreshYields();
    }
  }

  void addNewYield() async {
    final result = await Get.toNamed(Routes.ADD_YIELD);

    if (result != null && result['success'] == true) {
      refreshYields();
    }
  }

  // ✅ IMPROVED: Refresh yields
  Future<void> refreshYields() async {
    print('Refreshing yields...');
    currentPage.value = 1;

    if (showAllRecords.value) {
      await loadAllYields();
    } else {
      await loadYields();
    }
  }

  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    selectedCropId.value = null;
    selectedFarmSegmentId.value = null;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    filterHasBills.value = null;
    currentPage.value = 1;
    showAllRecords.value = false;
    loadYields();
  }

  // ✅ IMPROVED: Get summary text
  String getSummaryText() {
    if (showAllRecords.value) {
      return 'Showing all ${filteredYields.length} of ${totalCount.value} yields';
    }

    int startRecord = ((currentPage.value - 1) * itemsPerPage) + 1;
    int endRecord =
        (currentPage.value * itemsPerPage).clamp(0, totalCount.value);

    if (totalCount.value == 0) {
      return 'No yields found';
    }

    String summary =
        'Showing $startRecord-$endRecord of ${totalCount.value} yields';

    if (searchKeyword.value.isNotEmpty) {
      summary += ' (filtered)';
    }

    if (totalPages.value > 1) {
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

  String formatHarvestDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

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
        return YieldSummary.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error loading yield summary: $e');
      return null;
    }
  }

  double getTotalYieldQuantity(YieldModel yield) {
    return yield.totalQuantity;
  }

  String getYieldVariantsSummary(YieldModel yield) {
    if (yield.yieldVariants.isEmpty) return 'No variants';

    if (yield.yieldVariants.length == 1) {
      final variant = yield.yieldVariants.first;
      return '${variant.quantity} ${variant.unit}';
    }

    return '${yield.yieldVariants.length} variants';
  }

  bool yieldHasBills(YieldModel yield) {
    return yield.hasBills;
  }

  int getBillCount(YieldModel yield) {
    return yield.billCount;
  }

  String getFarmSegmentsText(YieldModel yield) {
    final segmentNames = yield.yieldFarmSegments
        .map((segment) => segment.farmSegmentName)
        .toList();

    if (segmentNames.isEmpty) return 'No segments';
    if (segmentNames.length == 1) return segmentNames.first;
    return '${segmentNames.length} segments';
  }

  String getVariantsText(YieldModel yield) {
    if (yield.yieldVariants.isEmpty) return 'No variants';

    List<String> variantTexts = yield.yieldVariants
        .map((variant) => '${variant.quantity} ${variant.unit}')
        .toList();

    return variantTexts.join(', ');
  }

  // ✅ IMPROVED: Export helper - get all yields for export
  Future<List<YieldModel>> getAllYieldsForExport() async {
    try {
      // If already in "show all" mode, return current data
      if (showAllRecords.value && allYields.isNotEmpty) {
        return allYields;
      }

      // Otherwise, fetch all yields
      print('Fetching all yields for export...');

      List<YieldModel> allExportYields = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
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
          page: page,
          pageSize: 100, // Use larger page size for export
        );

        if (response['success'] != true) break;

        final data = response['data'];
        List<dynamic> yieldsData = [];

        if (data is List) {
          yieldsData = data;
        } else if (data is Map) {
          yieldsData = data['yields'] ?? data['results'] ?? data['data'] ?? [];
          hasMore = data['has_next'] ?? false;
        }

        for (var yieldData in yieldsData) {
          if (yieldData is Map<String, dynamic>) {
            allExportYields.add(YieldModel.fromJson(yieldData));
          }
        }

        if (page > 100) break; // Safety limit
        if (hasMore) page++;
      }

      print('Export: Fetched ${allExportYields.length} yields');
      return allExportYields;
    } catch (e) {
      print('Error getting all yields for export: $e');
      return [];
    }
  }
}
