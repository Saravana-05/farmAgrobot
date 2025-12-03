
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../../data/models/sales/sales_model.dart';
import '../../../data/services/sales/sales_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../routes/app_pages.dart';

class ViewSalesController extends GetxController {
  var searchKeyword = ''.obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var currentPage = 1.obs;
  var itemsPerPage = 10;
  var totalPages = 1.obs;
  var totalCount = 0.obs;
  var filteredSales = <SaleModel>[].obs;
  var allSales = <SaleModel>[].obs;
  var hasNext = false.obs;
  var hasPrevious = false.obs;

  // Filters
  var selectedMerchantId = Rxn<String>();
  var selectedYieldId = Rxn<String>();
  var selectedPaymentMode = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var selectedPaymentStatus = Rxn<String>();
  var selectedStartDate = Rxn<DateTime>();
  var selectedEndDate = Rxn<DateTime>();
  var minAmount = Rxn<double>();
  var maxAmount = Rxn<double>();

  // Available yields for dropdown - Fixed: Using AvailableYield instead of YieldModel
  var availableYields = <AvailableYield>[].obs;

  // Form controllers
  final searchController = TextEditingController();
  final minAmountController = TextEditingController();
  final maxAmountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAvailableYields();
    loadSales();
  }

  void onRouteBack() {
    if (Get.currentRoute == Routes.SALES) {
      refreshSales();
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  void onResume() {
    refreshSales();
  }

  @override
  void onClose() {
    searchController.dispose();
    minAmountController.dispose();
    maxAmountController.dispose();
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

    // If it doesn't start with media, add it
    if (!cleanUrl.startsWith('media/')) {
      cleanUrl = 'media/$cleanUrl';
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
    if (url == null || url.isEmpty) {
      print('isValidImageUrl: URL is null or empty');
      return false;
    }

    try {
      Uri? uri = Uri.tryParse(url);
      if (uri == null) {
        print('isValidImageUrl: Failed to parse URI from "$url"');
        return false;
      }

      bool hasScheme = uri.hasScheme;
      bool hasHost = uri.host.isNotEmpty;
      bool isHttpOrHttps = uri.scheme == 'http' || uri.scheme == 'https';

      print('isValidImageUrl: URL "$url"');
      print('  - Has Scheme: $hasScheme (${uri.scheme})');
      print('  - Has Host: $hasHost (${uri.host})');
      print('  - Is HTTP/HTTPS: $isHttpOrHttps');

      bool isValid = hasScheme && hasHost && isHttpOrHttps;
      print('  - Final Result: $isValid');

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

  // Load available yields for dropdown - Fixed: Using correct model
  Future<void> loadAvailableYields() async {
    try {
      final response = await SalesService.getAvailableYields();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> yieldsData = [];

        if (data is List) {
          yieldsData = data;
        } else if (data is Map) {
          yieldsData = data['data'] ?? data['yields'] ?? data['results'] ?? [];
        }

        List<AvailableYield> yields = [];
        for (var yieldData in yieldsData) {
          if (yieldData is Map<String, dynamic>) {
            yields.add(AvailableYield.fromJson(yieldData));
          }
        }

        availableYields.value = yields;
        print('Loaded ${yields.length} available yields');
      }
    } catch (e) {
      print('Error loading available yields: $e');
    }
  }

  // Load sales from API with pagination and filters
  Future<void> loadSales() async {
    try {
      isLoading.value = true;

      print(
          '🔍 Loading sales - Page: ${currentPage.value}, Search: ${searchKeyword.value}');

      final response = await SalesService.getAllSales(
        merchantId: selectedMerchantId.value,
        yieldId: selectedYieldId.value,
        paymentMode: selectedPaymentMode.value,
        status: selectedStatus.value,
        paymentStatus: selectedPaymentStatus.value,
        startDate: selectedStartDate.value != null
            ? SalesService.formatDateForApi(selectedStartDate.value!)
            : null,
        endDate: selectedEndDate.value != null
            ? SalesService.formatDateForApi(selectedEndDate.value!)
            : null,
        minAmount: minAmount.value?.toString(),
        maxAmount: maxAmount.value?.toString(),
        page: currentPage.value,
        pageSize: itemsPerPage,
      );

      print('📥 Sales API Response: $response');

      if (response['success'] == true) {
        final responseData =
            response['data']; // This is the outer 'data' from Django
        print('📦 Response data: $responseData');

        if (responseData != null && responseData is Map) {
          // CORRECTED: Access nested 'data' object from Django response
          final nestedData =
              responseData['data']; // This contains sales, count, etc.

          if (nestedData != null && nestedData is Map) {
            // Extract sales array from nested data
            List<dynamic> salesData = nestedData['sales'] ?? [];

            print('🔍 Found ${salesData.length} sales in response');

            // Extract pagination metadata from nested data
            totalCount.value = nestedData['count'] ??
                nestedData['total_count'] ??
                salesData.length;

            totalPages.value = nestedData['total_pages'] ??
                ((totalCount.value / itemsPerPage).ceil());

            // Ensure totalPages is at least 1
            if (totalPages.value < 1) {
              totalPages.value = 1;
            }

            // Extract current page info
            int currentPageFromApi =
                nestedData['current_page'] ?? currentPage.value;

            // Set pagination flags
            hasNext.value = nestedData['has_next'] ?? false;
            hasPrevious.value = nestedData['has_previous'] ?? false;

            print('✅ Pagination Info:');
            print('  - Current Page: $currentPageFromApi');
            print('  - Total Pages: ${totalPages.value}');
            print('  - Total Count: ${totalCount.value}');
            print('  - Items Per Page: $itemsPerPage');
            print('  - Has Next: ${hasNext.value}');
            print('  - Has Previous: ${hasPrevious.value}');
            print('  - Sales in current page: ${salesData.length}');

            // Convert to SaleModel objects
            List<SaleModel> sales = [];
            for (var saleData in salesData) {
              try {
                if (saleData is Map<String, dynamic>) {
                  final saleModel = SaleModel.fromJson(saleData);
                  sales.add(saleModel);
                  print(
                      '✅ Parsed sale: ${saleModel.id} - ${saleModel.totalCalculatedAmount}');
                }
              } catch (e) {
                print('❌ Error parsing sale: $e');
                print('🔍 Problem sale data: $saleData');
              }
            }

            // Update observable lists
            filteredSales.value = sales;
            allSales.value = sales;

            print('✅ Final sales list count: ${filteredSales.length}');
          } else {
            print('❌ Nested data is null or not a Map');
            _resetSalesData();
          }
        } else {
          print('❌ Response data is null or not a Map');
          _resetSalesData();
        }
      } else {
        print('❌ Sales API response not successful: $response');
        CustomSnackbar.showError(
          title: 'Error',
          message: response['data']?['message'] ?? 'Failed to load sales',
        );
        _resetSalesData();
      }
    } catch (e, stackTrace) {
      print('❌ Error loading sales: $e');
      print('📍 Stack trace: $stackTrace');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error loading sales: ${e.toString()}',
      );
      _resetSalesData();
    } finally {
      isLoading.value = false;
    }
  }

// Helper method to reset sales data
  void _resetSalesData() {
    filteredSales.value = [];
    allSales.value = [];
    totalCount.value = 0;
    totalPages.value = 1;
    hasNext.value = false;
    hasPrevious.value = false;
  }

  // Get sale images for a specific sale
  List<String> getSaleImageUrls(SaleModel sale) {
    print('\n=== Processing Sale Images for Sale ${sale.id} ===');
    print('Sale images count from model: ${sale.saleImages.length}');

    // Debug: Print each sale image details
    for (int i = 0; i < sale.saleImages.length; i++) {
      final saleImage = sale.saleImages[i];
      print('1.Sale Image $i:');
      print('  - 2.ID: ${saleImage.id}');
      print('  - 3.Raw URL: "${saleImage.imageUrl}"');
      print('  - 4.Image Name: "${saleImage.imageName}"');
      print('  - 5.Is Primary: ${saleImage.isPrimary}');
    }

    List<String> validImageUrls = [];

    // Process each sale image
    for (int i = 0; i < sale.saleImages.length; i++) {
      final saleImage = sale.saleImages[i];
      final rawUrl = saleImage.imageUrl;

      print('Processing image $i: "$rawUrl"');

      if (rawUrl.isEmpty) {
        print('  → SKIPPED: Empty URL');
        continue;
      }

      // Process the URL
      String processedUrl = processImageUrl(rawUrl);
      print('  → Processed URL: "$processedUrl"');

      // Validate the URL
      bool isValid = isValidImageUrl(processedUrl);
      print('  → Is Valid: $isValid');

      if (isValid) {
        validImageUrls.add(processedUrl);
        print('  → ADDED to final list ✓');
      } else {
        print('  → REJECTED: Invalid URL ✗');
      }
    }

    print('Final valid image URLs (${validImageUrls.length}): $validImageUrls');
    print('=== End Processing Sale Images ===\n');

    return validImageUrls;
  }

  // Search sales
  void runFilter(String keyword) {
    print('Running sale filter with keyword: $keyword');
    searchKeyword.value = keyword;
    currentPage.value = 1; // Reset to first page
    loadSales();
  }

  // Set filters
  void setMerchantFilter(String? merchantId) {
    selectedMerchantId.value = merchantId;
    currentPage.value = 1;
    loadSales();
  }

  void setYieldFilter(String? yieldId) {
    selectedYieldId.value = yieldId;
    currentPage.value = 1;
    loadSales();
  }

  void setPaymentModeFilter(String? paymentMode) {
    selectedPaymentMode.value = paymentMode;
    currentPage.value = 1;
    loadSales();
  }

  void setStatusFilter(String? status) {
    selectedStatus.value = status;
    currentPage.value = 1;
    loadSales();
  }

  void setPaymentStatusFilter(String? paymentStatus) {
    selectedPaymentStatus.value = paymentStatus;
    currentPage.value = 1;
    loadSales();
  }

  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    currentPage.value = 1;
    loadSales();
  }

  void setAmountRangeFilter(double? minAmt, double? maxAmt) {
    minAmount.value = minAmt;
    maxAmount.value = maxAmt;
    currentPage.value = 1;
    loadSales();
  }

  // Pagination
  void nextPage() {
    if (hasNext.value) {
      currentPage.value++;
      loadSales();
    }
  }

  void previousPage() {
    if (hasPrevious.value) {
      currentPage.value--;
      loadSales();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadSales();
    }
  }

  List<SaleModel> getPaginatedSales() {
    return filteredSales;
  }

  // Get sale details by ID
  Future<SaleModel?> getSaleDetails(String saleId) async {
    try {
      print('Fetching sale details for ID: $saleId');

      final response = await SalesService.getSaleById(saleId);

      print('Get sale details response: $response');

      if (response['success'] == true && response['data'] != null) {
        final saleData = response['data'];

        // If the response has nested data structure
        final actualData = saleData['data'] ?? saleData;

        return SaleModel.fromJson(actualData);
      } else {
        String errorMessage = 'Failed to get sale details';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      print('Error fetching sale details: $e');
      CustomSnackbar.showError(
          title: 'Error',
          message: 'Error fetching sale details: ${e.toString()}');
    }
    return null;
  }

  // Delete sale
  Future<void> deleteSale(String saleId) async {
    if (isDeleting.value) return;

    try {
      isDeleting.value = true;

      final response = await SalesService.deleteSale(saleId);

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
            title: 'Success', message: 'Sale deleted successfully');
        refreshSales();
      } else {
        String errorMessage = 'Failed to delete sale';
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

  // Update sale status
  Future<void> updateSaleStatus(String saleId, String status) async {
    try {
      final response = await SalesService.updateSaleStatus(
        saleId: saleId,
        status: status,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Sale status updated successfully',
        );
        refreshSales();
      } else {
        String errorMessage = 'Failed to update sale status';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  String mapPaymentMethodToBackend(String frontendMethod) {
    final Map<String, String> paymentMethodMapping = {
      'cash': 'Cash',
      'bank_transfer': 'Bank Transfer',
      'upi': 'UPI',
      'cheque': 'Cheque',
      'card': 'Card',
      'online': 'Online',
      // Add more mappings as needed based on your backend
    };

    return paymentMethodMapping[frontendMethod] ?? frontendMethod;
  }

  // Add payment to sale
  Future<void> addPaymentToSale({
    required String saleId,
    required double paymentAmount,
    required String paymentMethod,
    String? paymentReference,
    String? notes,
  }) async {
    try {
      // Map the payment method to the expected backend format
      String backendPaymentMethod = mapPaymentMethodToBackend(paymentMethod);

      final response = await SalesService.addPayment(
        saleId: saleId,
        paymentAmount: paymentAmount,
        paymentMethod: backendPaymentMethod, // Use mapped method
        paymentReference: paymentReference,
        notes: notes,
      );

      if (response['success'] == true) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Payment added successfully',
        );
        refreshSales();
      } else {
        String errorMessage = 'Failed to add payment';
        if (response['data'] != null && response['data']['message'] != null) {
          errorMessage = response['data']['message'];
        }
        CustomSnackbar.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  // Get payment history for sale
  Future<List<dynamic>> getPaymentHistory(String saleId) async {
    try {
      final response = await SalesService.getPaymentHistory(saleId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        return data['payments'] ?? data['data'] ?? [];
      }

      return [];
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  // Navigate to edit sale
  void editSale(SaleModel sale) async {
    final result = await Get.toNamed(Routes.EDIT_SALES, arguments: sale);

    if (result != null && result['success'] == true) {
      refreshSales();
    }
  }

  // Navigate to add sale
  void addNewSale() async {
    final result = await Get.toNamed(Routes.ADD_SALES);

    if (result != null && result['success'] == true) {
      refreshSales();
    }
  }

  // Refresh sales list
  Future<void> refreshSales() async {
    print('Refreshing sales...');
    currentPage.value = 1;
    await loadSales();
  }

  // Clear all filters
  void clearFilters() {
    searchKeyword.value = '';
    searchController.clear();
    selectedMerchantId.value = null;
    selectedYieldId.value = null;
    selectedPaymentMode.value = null;
    selectedStatus.value = null;
    selectedPaymentStatus.value = null;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    minAmount.value = null;
    maxAmount.value = null;
    minAmountController.clear();
    maxAmountController.clear();
    currentPage.value = 1;
    loadSales();
  }

  // Get summary text
  String getSummaryText() {
    String summary = 'Total: ${totalCount.value} sales';
    if (searchKeyword.value.isNotEmpty) {
      summary += ' (filtered)';
    }
    if (currentPage.value > 1 || hasNext.value) {
      summary += ' | Page ${currentPage.value} of ${totalPages.value}';
    }
    return summary;
  }

  // Format currency
  String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(amount);
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

  // Get yield name for dropdown - Fixed: Using AvailableYield instead of YieldModel
  String getYieldName(AvailableYield yield) {
    return '${yield.cropName} - ${formatHarvestDate(yield.harvestDate)}';
  }

  // Get payment status color
  Color getPaymentStatusColor(String? paymentStatus) {
    switch (paymentStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get sale status color
  Color getSaleStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Get sale variants summary - Fixed: Using saleVariants instead of variants
  String getSaleVariantsSummary(SaleModel sale) {
    if (sale.saleVariants.isEmpty) return 'No variants';

    if (sale.saleVariants.length == 1) {
      final variant = sale.saleVariants.first;
      return '${variant.quantity} ${variant.unit}';
    }

    return '${sale.saleVariants.length} variants';
  }

  // Helper method to check if sale has images
  bool saleHasImages(SaleModel sale) {
    return sale.saleImages.isNotEmpty;
  }

  // Helper method to get image count
  int getImageCount(SaleModel sale) {
    return sale.saleImages.length;
  }

  // Export helper - get all sales for export
  Future<List<SaleModel>> getAllSalesForExport() async {
    try {
      final response = await SalesService.getAllSales();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> salesData = [];

        if (data is List) {
          salesData = data;
        } else if (data is Map) {
          salesData = data['sales'] ?? data['results'] ?? data['data'] ?? [];
        }

        List<SaleModel> sales = [];
        for (var saleData in salesData) {
          if (saleData is Map<String, dynamic>) {
            sales.add(SaleModel.fromJson(saleData));
          }
        }

        return sales;
      }

      return [];
    } catch (e) {
      print('Error getting all sales for export: $e');
      return [];
    }
  }
}
