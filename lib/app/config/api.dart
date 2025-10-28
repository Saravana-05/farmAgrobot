// const String baseUrl = 'http://192.168.0.111:8000/api/';
// const String baseImgUrl = 'http://192.168.0.111:8000';

const String baseUrl = 'https://farmagrobot.ofal.in/api/';
const String baseImgUrl = 'https://farmagrobot.ofal.in';

// Expenses
const String addExpense = baseUrl + 'expenses/';
const String viewExpense = baseUrl + 'expenses/all/';
const String deleteExpenseUrl = baseUrl + 'expenses/{id}/delete/';
const String updateExpenseUrl = baseUrl + 'expenses/{id}/update/';
const String editExpenseUrl = baseUrl + 'expenses/{id}/';

// Employees
const String addEmployee = baseUrl + 'employees/';
const String viewEmployee = baseUrl + 'employees';
const String deleteEmployeeUrl = baseUrl + 'employees/{id}/delete';
const String updateEmployeeUrl = baseUrl + 'employees/{id}/edit';
const String editEmployeeUrl = baseUrl + 'employees/{id}/';
const String statusEmployeeUrl = baseUrl + 'employees/{id}/status';

/// Enhanced image URL handling with validation
String getFullImageUrl(String? relativePath) {
  try {
    // Handle null or empty paths
    if (relativePath == null || relativePath.isEmpty) {
      print('getFullImageUrl: Empty or null path provided');
      return '';
    }

    // Clean the path
    String cleanPath = relativePath.trim();

    if (cleanPath.isEmpty) {
      print('getFullImageUrl: Empty path after trimming');
      return '';
    }

    // If already a complete URL, validate and return
    if (cleanPath.startsWith('http')) {
      Uri? uri = Uri.tryParse(cleanPath);
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        print('getFullImageUrl: Valid complete URL: $cleanPath');
        return cleanPath;
      } else {
        print('getFullImageUrl: Invalid complete URL: $cleanPath');
        return '';
      }
    }

    // Build full URL
    String fullUrl;
    if (cleanPath.startsWith('/')) {
      fullUrl = '$baseImgUrl$cleanPath';
    } else {
      fullUrl = '$baseImgUrl/$cleanPath';
    }

    // Validate the constructed URL
    Uri? uri = Uri.tryParse(fullUrl);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      print(
          'getFullImageUrl: Successfully built URL: $fullUrl from path: $cleanPath');
      return fullUrl;
    } else {
      print('getFullImageUrl: Failed to build valid URL from path: $cleanPath');
      return '';
    }
  } catch (e) {
    print('getFullImageUrl: Error processing path "$relativePath": $e');
    return '';
  }
}

/// Employee specific image handling with enhanced validation
String getEmployeeImageUrl(String? profileImagePath) {
  try {
    final fullUrl = getFullImageUrl(profileImagePath);

    // Enhanced logging for debugging
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      // Additional validation
      if (fullUrl.isNotEmpty) {
        Uri? uri = Uri.tryParse(fullUrl);
        if (uri != null) {
          print(
              '  Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
        }
      }
    }

    return fullUrl;
  } catch (e) {
    print(
        'getEmployeeImageUrl: Error processing employee image path "$profileImagePath": $e');
    return '';
  }
}

/// Validate if a URL is properly formed
bool isValidImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    print('isValidImageUrl: URL is null or empty');
    return false;
  }

  try {
    Uri? uri = Uri.tryParse(url);
    bool isValid = uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    print('isValidImageUrl: URL "$url" is ${isValid ? "valid" : "invalid"}');
    return isValid;
  } catch (e) {
    print('isValidImageUrl: Error validating URL "$url": $e');
    return false;
  }
}

/// Get a safe image URL or return null
String? getSafeImageUrl(String? relativePath) {
  final url = getFullImageUrl(relativePath);
  return isValidImageUrl(url) ? url : null;
}

// Wages
const String addWage = baseUrl + 'wages/';
const String viewWage = baseUrl + 'wages/list/';
const String deleteWageUrl = baseUrl + 'wages/{id}/delete/';
const String updateWageUrl = baseUrl + 'wages/{id}/update/';
const String editWageUrl = baseUrl + 'wages/{id}/';

// ============= ATTENDANCE =============

// Daily Attendance
const String createDailyAttendanceUrl = baseUrl + 'mark-attendance/';
const String getAttendanceListUrl = baseUrl + 'weekly-data/';
const String getActiveEmployeesUrl = baseUrl + 'get-active-employees/';
// Additional Attendance URLs
const String getAttendanceUrl = baseUrl + 'attendance/{date_str}/';
const String updateAttendanceUrl = baseUrl + 'attendance/{date_str}/update/';
const String updateSingleAttendanceUrl = baseUrl + 'update-single-attendance/';
// ============= WAGE MANAGEMENT =============
const String payWagesUrl = baseUrl + 'pay-wages/';
const String wageSummaryUrl = baseUrl + 'wage-summary/';
// ============= EXPORT =============
const String exportAttendanceUrl = baseUrl + 'export-attendance/';
// ============= GENERATE PDF =============
const String pdfExport = baseUrl + 'wages/pdf/weekly/';
// ============= Employee Report =============
const String empReport = baseUrl + 'employee-report/';
const String singleEmployeeReportUrl = baseUrl + 'employee/{id}/report/';

// ============= ATTENDANCE END =============

// Crop URLs
const String addCrop = baseUrl + 'crops/';
const String viewCrop = baseUrl + 'crops/all/';
const String deleteCropUrl = baseUrl + 'crops/{id}/delete/';
const String updateCropUrl = baseUrl + 'crops/{id}/update/';
const String editCropUrl = baseUrl + 'crops/{id}/';

// Crop Variant URLs
const String addCropVariant = baseUrl + 'crop-variants/create/';
const String viewCropVariants = baseUrl + 'crop-variants/';
const String deleteCropVariantUrl = baseUrl + 'crop-variants/{id}/delete/';
const String updateCropVariantUrl = baseUrl + 'crop-variants/{id}/update/';
const String editCropVariantUrl = baseUrl + 'crop-variants/{id}/';
const String cropVariantsByCropUrl = baseUrl + 'crops/{crop_id}/variants/';
const String unitsByCropVariantUrl = baseUrl + 'crops/{crop_id}/variants/';

// Merchant URLs
const String addMerchant = baseUrl + 'merchants/';
const String viewMerchant = baseUrl + 'merchants/all/';
const String deleteMerchantUrl = baseUrl + 'merchants/{id}/delete/';
const String updateMerchantUrl = baseUrl + 'merchants/{id}/update/';
const String editMerchantUrl = baseUrl + 'merchants/{id}/';

// Farm Segment URLs
const String addFarmSegment = baseUrl + 'farm-segments/';
const String viewFarmSegment = baseUrl + 'farm-segments/all/';
const String deleteFarmSegmentUrl = baseUrl + 'farm-segments/{id}/delete/';
const String updateFarmSegmentUrl = baseUrl + 'farm-segments/{id}/update/';
const String editFarmSegmentUrl = baseUrl + 'farm-segments/{id}/';
const String searchFarmSegmentUrl = baseUrl + 'farm-segments/search/';

// Yield URLs
const String addYield = baseUrl + 'yields/create/';
const String viewYields = baseUrl + 'yields/';
const String getYieldByIdUrl = baseUrl + 'yields/';
const String updateYieldUrl = baseUrl + 'yields/update-with-options';
const String deleteYieldUrl = baseUrl + 'yields/delete/';
const String yieldSummaryUrl = baseUrl + 'yields/summary/';
const String addBillUrl = baseUrl + 'yields/add-bill-image';

// Sales URLs - START
const String saveSaleUrl = baseUrl + 'sales/';
const String getAllSalesUrl = baseUrl + 'sales/all/';
const String getSaleByIdUrl = baseUrl + 'sales/';
const String updateSaleUrl = baseUrl + 'sales/';
const String deleteSaleUrl = baseUrl + 'sales/delete/';
const String updateSaleStatusUrl = baseUrl + 'sales/';
const String salesByMerchantUrl = baseUrl + 'sales/merchant/';
const String salesSummaryUrl = baseUrl + 'sales/summary/';
const String salesAnalyticsUrl = baseUrl + 'sales/analytics/';

// Payment URLs
const String addPaymentUrl = baseUrl + 'sales/';
const String paymentHistoryUrl = baseUrl + 'sales/';
const String getPaymentModesUrl = baseUrl + 'sales/payment-modes/';

// Image URLs
const String saleImagesUrl = baseUrl + 'sales/';
const String addSaleImagesUrl = baseUrl + 'sales/';
const String updateSaleImageUrl = baseUrl + 'sales/';
const String deleteSaleImageUrl = baseUrl + 'sales/';

// Utility URLs
const String availableYieldsUrl = baseUrl + 'yields/available/';
const String yieldVariantsByYieldUrl = baseUrl + 'yields/{yield_id}/variants/';
const String advancedSearchUrl = '$baseUrl/search/';
const String searchSuggestionsUrl = '$baseUrl/search/suggestions/';

// Report URLs
const String excelReportUrl = baseUrl + 'reports/excel/';
const String pdfBillUrl = baseUrl + 'reports/pdf/';
const String bulkPdfReportUrl = baseUrl + 'reports/bulk-pdf/';

// Sales URLs - END

// Dashboard API endpoints
const String dashboardExpenseStatsUrl = baseUrl + 'dashboard/stats/';
const String monthlyExpenseTrendUrl = baseUrl + 'dashboard/monthly-trend/';
const String comparisonExpenseStatsUrl = baseUrl + 'dashboard/comparison/';
const String summaryExpenseByPeriodUrl = baseUrl + 'dashboard/summary/';

// Revenue Dashboard API endpoints
const String dashboardRevenueUrl = baseUrl + 'dashboard/revenue/';
const String dashboardQuickStatsUrl = baseUrl + 'dashboard/quick-stats/';
const String dashboardRevenueByPeriodUrl = baseUrl + 'dashboard/revenue/';

// Crop Dashboard API endpoints
const String cropDashboardUrl = baseUrl + 'crop-dashboard/';
const String cropComparisonDashboardUrl =
    baseUrl + 'crop-comparison-dashboard/';
const String cropPerformanceMetricsUrl = baseUrl + 'crop-performance-metrics/';
