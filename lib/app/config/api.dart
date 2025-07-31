const String baseUrl = 'http://192.168.0.114:8000/api/';
const String baseImgUrl = 'http://192.168.0.114:8000';

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
  if (url == null || url.isEmpty) return false;

  try {
    Uri? uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
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
