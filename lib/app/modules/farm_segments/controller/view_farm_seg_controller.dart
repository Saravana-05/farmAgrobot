import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/farm_segments/farm_seg_models.dart';
import '../../../data/services/farm_segment/farm_seg_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';
import '../views/farm_seg_screen.dart';

class FarmSegmentViewController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var filteredFarmSegments = <FarmSegment>[].obs;
  var allFarmSegments = <FarmSegment>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  // Form controllers for add/edit farm segment
  final farmNameController = TextEditingController();
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadFarmSegments();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.FARM_SEGMENT) {
      refreshFarmSegments();
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  void onResume() {
    refreshFarmSegments();
  }

  @override
  void onClose() {
    farmNameController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // Load farm segments from API with pagination
  Future<void> loadFarmSegments() async {
    try {
      isLoading.value = true;

      print(
          'Loading farm segments - Page: ${currentPage.value}, Search: ${searchKeyword.value}');

      final response = await FarmSegmentService.getAllFarmSegments(
        page: currentPage.value,
        limit: itemsPerPage,
        search: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
      );

      print('API Response: ${response}'); // Debug log

      if (response['success'] == true) {
        final data = response['data'];
        print('Response data: $data'); // Debug log

        if (data != null) {
          List<dynamic> farmSegmentsData = [];

          // Handle different API response structures
          if (data is List) {
            // Data is directly a list of farm segments
            farmSegmentsData = data;
            totalCount.value = farmSegmentsData.length;
            print('Data is List with ${farmSegmentsData.length} items');
          } else if (data is Map) {
            // Data contains pagination info or nested structure
            if (data.containsKey('farm_segments')) {
              farmSegmentsData = data['farm_segments'] ?? [];
            } else if (data.containsKey('results')) {
              farmSegmentsData = data['results'] ?? [];
            } else if (data.containsKey('data')) {
              farmSegmentsData = data['data'] ?? [];
            } else {
              // Fallback - try to use the map data directly if it looks like farm segment data
              if (data.containsKey('farm_name') || data.containsKey('id')) {
                farmSegmentsData = [data];
              }
            }

            totalCount.value =
                data['total'] ?? data['count'] ?? farmSegmentsData.length;
            hasNext.value = data['has_next'] ?? false;
            hasPrevious.value = data['has_previous'] ?? false;
            totalPages.value = data['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());

            print(
                'Data is Map - farm segments count: ${farmSegmentsData.length}, total: ${totalCount.value}');
          }

          // Convert to FarmSegment objects
          List<FarmSegment> farmSegments = [];
          for (var farmSegmentData in farmSegmentsData) {
            try {
              if (farmSegmentData is Map<String, dynamic>) {
                final farmSegment =
                    FarmSegmentService.farmSegmentFromJson(farmSegmentData);
                farmSegments.add(farmSegment);
                print('Parsed farm segment: ${farmSegment.farmName}');
              } else {
                print('Invalid farm segment data format: ${farmSegmentData}');
              }
            } catch (e) {
              print('Error parsing farm segment: $e');
              print('Farm segment data: $farmSegmentData');
            }
          }

          filteredFarmSegments.value = farmSegments;
          allFarmSegments.value = farmSegments;

          print(
              'Final farm segments list count: ${filteredFarmSegments.length}');

          // Update pagination info if not already set
          if (totalPages.value <= 1) {
            totalPages.value = (totalCount.value / itemsPerPage).ceil();
          }
          hasPrevious.value = currentPage.value > 1;
          hasNext.value = currentPage.value < totalPages.value;
        } else {
          print('Response data is null');
          filteredFarmSegments.value = [];
          allFarmSegments.value = [];
          totalCount.value = 0;
        }
      } else {
        print('API response not successful: ${response}');
        CustomSnackbar.showError(
          title: 'Error',
          message:
              response['data']?['message'] ?? 'Failed to load farm segments',
        );
        filteredFarmSegments.value = [];
        allFarmSegments.value = [];
        totalCount.value = 0;
      }
    } catch (e) {
      print('Error loading farm segments: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading farm segments: ${e.toString()}',
      );
      filteredFarmSegments.value = [];
      allFarmSegments.value = [];
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Search farm segments
  void runFilter(String keyword) {
    print('Running filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1;

    // If keyword is empty, load all farm segments
    if (keyword.trim().isEmpty) {
      loadFarmSegments();
    } else {
      // Use the search API
      searchFarmSegments();
    }
  }

  Future<void> searchFarmSegments() async {
    try {
      isLoading.value = true;

      print('Searching farm segments with keyword: ${searchKeyword.value}');

      final response = await FarmSegmentService.searchFarmSegments(
        query: searchKeyword.value,
        page: currentPage.value,
        limit: itemsPerPage,
      );

      print('Search API Response: ${response}');

      if (response['success'] == true) {
        final data = response['data'];

        if (data != null) {
          List<dynamic> farmSegmentsData = [];

          // Handle different API response structures
          if (data is List) {
            farmSegmentsData = data;
            totalCount.value = response['count'] ?? farmSegmentsData.length;
          } else if (data is Map) {
            if (data.containsKey('farm_segments')) {
              farmSegmentsData = data['farm_segments'] ?? [];
            } else if (data.containsKey('results')) {
              farmSegmentsData = data['results'] ?? [];
            } else {
              farmSegmentsData = [data];
            }

            totalCount.value = response['count'] ?? farmSegmentsData.length;
          }

          // Convert to FarmSegment objects
          List<FarmSegment> farmSegments = [];
          for (var farmSegmentData in farmSegmentsData) {
            try {
              if (farmSegmentData is Map<String, dynamic>) {
                final farmSegment =
                    FarmSegmentService.farmSegmentFromJson(farmSegmentData);
                farmSegments.add(farmSegment);
              }
            } catch (e) {
              print('Error parsing farm segment: $e');
            }
          }

          filteredFarmSegments.value = farmSegments;
          allFarmSegments.value = farmSegments;

          // Update pagination
          totalPages.value = (totalCount.value / itemsPerPage).ceil();
          hasPrevious.value = currentPage.value > 1;
          hasNext.value = currentPage.value < totalPages.value;

          print(
              'Search results: ${filteredFarmSegments.length} farm segments found');
        } else {
          filteredFarmSegments.value = [];
          allFarmSegments.value = [];
          totalCount.value = 0;
        }
      } else {
        CustomSnackbar.showError(
          title: 'Error',
          message:
              response['data']?['message'] ?? 'Failed to search farm segments',
        );
        filteredFarmSegments.value = [];
        allFarmSegments.value = [];
        totalCount.value = 0;
      }
    } catch (e) {
      print('Error searching farm segments: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error searching farm segments: ${e.toString()}',
      );
      filteredFarmSegments.value = [];
      allFarmSegments.value = [];
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      // Use search if there's a search keyword, otherwise load all
      if (searchKeyword.value.isNotEmpty) {
        searchFarmSegments();
      } else {
        loadFarmSegments();
      }
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      // Use search if there's a search keyword, otherwise load all
      if (searchKeyword.value.isNotEmpty) {
        searchFarmSegments();
      } else {
        loadFarmSegments();
      }
    }
  }

  List<FarmSegment> getPaginatedFarmSegments() {
    return filteredFarmSegments;
  }

  // Add new farm segment
  Future<void> addFarmSegment() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare farm segment data
      Map<String, dynamic> farmSegmentData = {
        'farm_name': farmNameController.text.trim(),
      };

      // Validate farm segment data
      final validationErrors =
          FarmSegmentService.validateFarmSegmentData(farmSegmentData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Save farm segment
      final response = await FarmSegmentService.saveFarmSegment(
        farmSegmentData: farmSegmentData,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Farm segment added successfully');

        // Clear form and refresh list
        clearForm();
        refreshFarmSegments();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to add farm segment';
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

  // Update existing farm segment
  Future<void> updateFarmSegment(String farmSegmentId) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      // Prepare farm segment data
      Map<String, dynamic> farmSegmentData = {
        'farm_name': farmNameController.text.trim(),
      };

      // Validate farm segment data
      final validationErrors =
          FarmSegmentService.validateFarmSegmentData(farmSegmentData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Update farm segment
      final response = await FarmSegmentService.updateFarmSegment(
        farmSegmentId: farmSegmentId,
        farmSegmentData: farmSegmentData,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Farm segment updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshFarmSegments();
        Get.back(); // Close dialog/form
      } else {
        String errorMessage = 'Failed to update farm segment';
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

  // Delete farm segment
  Future<void> deleteFarmSegment(String farmSegmentId) async {
    if (isDeleting.value) return;

    try {
      isDeleting.value = true;

      final response = await FarmSegmentService.deleteFarmSegment(
          farmSegmentId: farmSegmentId);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Farm segment deleted successfully');
        refreshFarmSegments();
      } else {
        String errorMessage = 'Failed to delete farm segment';
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

  // View farm segment details
  void viewFarmSegment(FarmSegment farmSegment) {
    Get.dialog(
      AlertDialog(
        title: Text(farmSegment.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${farmSegment.id}'),
              SizedBox(height: 8),
              Text('Name: ${farmSegment.displayName}'),
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

  // Edit farm segment - populate form with existing data
  Future<void> editFarmSegment(FarmSegment farmSegment) async {
    final result = await Get.to(() => FarmSegScreen(), arguments: farmSegment);

    if (result != null && result['success'] == true) {
      // Refresh the farm segments list
      refreshFarmSegments();
    }
  }

  Future<void> handleEditFarmSegment(FarmSegment farmSegment) async {
    print('DEBUG: handleEditFarmSegment called');
    print('DEBUG: Farm Segment ID: "${farmSegment.id}"');
    print('DEBUG: Farm Segment Name: "${farmSegment.farmName}"');
    print('DEBUG: Full farm segment object: $farmSegment');
    try {
      isLoading.value = true;

      // First, fetch the latest farm segment details from API
      final farmSegmentDetails =
          await getFarmSegmentDetails(farmSegment.id.toString());

      if (farmSegmentDetails != null) {
        // Populate the form with existing data
        populateFormWithFarmSegmentData(farmSegmentDetails);

        // Navigate to edit screen with the farm segment data
        final result = await Get.toNamed(Routes.EDIT_FARM_SEGMENT,
            arguments: {'farmSegment': farmSegmentDetails, 'mode': 'edit'});

        // If edit was successful, refresh the list
        if (result != null && result['success'] == true) {
          refreshFarmSegments();
        }
      }
    } catch (e) {
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to load farm segment details: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to populate form with existing farm segment data
  void populateFormWithFarmSegmentData(FarmSegment farmSegment) {
    farmNameController.text = farmSegment.farmName;
  }

  // Enhanced getFarmSegmentDetails method with better error handling
  Future<FarmSegment?> getFarmSegmentDetails(String farmSegmentId) async {
    try {
      print('Fetching farm segment details for ID: $farmSegmentId');

      final response =
          await FarmSegmentService.getFarmSegmentById(farmSegmentId);

      print('Get farm segment details response: $response');

      if (response['success'] == true && response['data'] != null) {
        return FarmSegmentService.farmSegmentFromJson(response['data']);
      } else {
        String errorMessage = 'Failed to get farm segment details';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error fetching farm segment details: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error fetching farm segment details: ${e.toString()}');
    }
    return null;
  }

  // Method to handle update from edit screen
  Future<void> handleUpdateFarmSegment(
      String farmSegmentId, Map<String, dynamic> updatedData) async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;
      print('Updating farm segment $farmSegmentId with data: $updatedData');

      // Validate farm segment data
      final validationErrors =
          FarmSegmentService.validateFarmSegmentData(updatedData);
      if (validationErrors != null) {
        String errorMessage =
            validationErrors.entries.map((entry) => entry.value).join('\n');
        CustomSnackbar.showError(
            title: 'Validation Error', message: errorMessage);
        return;
      }

      // Call the update API
      final response = await FarmSegmentService.updateFarmSegment(
        farmSegmentId: farmSegmentId,
        farmSegmentData: updatedData,
      );

      print('Update farm segment response: $response');

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Farm segment updated successfully');

        // Clear form and refresh list
        clearForm();
        refreshFarmSegments();
        Get.back(result: {'success': true});
      } else {
        String errorMessage = 'Failed to update farm segment';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error updating farm segment: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error updating farm segment: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

  // Clear form
  void clearForm() {
    farmNameController.clear();
  }

  // Refresh farm segments list
  Future<void> refreshFarmSegments() async {
    print('Refreshing farm segments...');
    currentPage.value = 1;
    await loadFarmSegments();
  }

  // Clear search filter
  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    currentPage.value = 1;
    loadFarmSegments();
  }

  // Get summary text
  String getSummaryText() {
    return 'Total: ${totalCount.value} farm segments';
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
