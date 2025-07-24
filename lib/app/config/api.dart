const String baseUrl = 'http://192.168.0.114:8000/api/';
const String baseImgUrl = 'http://192.168.0.114:8000';

const String addExpense = baseUrl + 'expenses/';
const String viewExpense = baseUrl + 'expenses/all/';
const String deleteExpenseUrl = baseUrl + 'expenses/{id}/delete/';
const String updateExpenseUrl = baseUrl + 'expenses/{id}/update/';
const String editExpenseUrl = baseUrl + 'expenses/{id}/';

String getFullImageUrl(String? relativePath) {
  if (relativePath == null || relativePath.isEmpty) {
    return '';
  }

  // If already a complete URL, return as is
  if (relativePath.startsWith('http')) {
    return relativePath;
  }

  // If starts with /, combine with base URL
  if (relativePath.startsWith('/')) {
    return '$baseImgUrl$relativePath';
  }

  // Otherwise, add both / and base URL
  return '$baseImgUrl/$relativePath';
}
