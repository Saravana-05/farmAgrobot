import 'dart:async';
import 'dart:typed_data';
import 'package:farm_agrobot/app/global_widgets/custom_snackbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/services/expenses/expense_service.dart';
import '../../../routes/app_pages.dart';

class EditExpenseController extends GetxController {
  // Text Controllers
  final expNameController = TextEditingController();
  final dateController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final spentByController = TextEditingController();

  // Observable variables
  final selectedCategoryTypes = Rxn<String>();
  final selectedModeOfPayment = Rxn<String>();
  final image = Rxn<Uint8List>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploading = false.obs;
  final selectedIndex = 1.obs;

  // Expense ID
  final expenseId = Rxn<String>();

  // Original expense data for comparison
  ExpenseModel? originalExpense;

  // Current expense being edited
  final currentExpense = Rxn<ExpenseModel>();

  // Service instance
  final ExpenseService _expenseService = Get.find<ExpenseService>();

  // Dropdown options
  final categoryTypes = <String>[
    'Advance',
    'Food',
    'Transport',
    'Donation and Give Away',
    'Driver',
    'Miscellinious',
    'Machine and Motor Repairs',
    'Jeep Maintenance',
    'Eb/Phone/Admin Exp',
    'Fuel',
    'Tree Samplings',
    'Farm Maintenance',
    'Weekly Wages'
  ].obs;

  final modeOfPayment = <String>['Cash', 'Card', 'UPI', 'Bank', 'Cheque'].obs;

  @override
  void onInit() {
    super.onInit();

    // Get expense ID from arguments with null safety
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map && arguments.containsKey('id')) {
      final id = arguments['id'];
      if (id != null) {
        expenseId.value = id.toString();
        loadExpenseData();
      } else {
        _showErrorAndGoBack('Expense ID is null');
      }
    } else {
      _showErrorAndGoBack('Expense ID not found in arguments');
    }
  }

  @override
  void onClose() {
    expNameController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    spentByController.dispose();
    super.onClose();
  }

  // Helper method to show error and navigate back
  void _showErrorAndGoBack(String message) {
    CustomSnackbar.showError(title: 'Error', message: message);
    Get.back();
  }

  // Load expense data using service
  Future<void> loadExpenseData() async {
    final id = expenseId.value;
    if (id == null || id.isEmpty) {
      _showErrorAndGoBack('Invalid expense ID');
      return;
    }

    try {
      isLoading.value = true;

      final result = await _expenseService.getExpenseById(id);

      if (result['success'] == true) {
        final expenseData = result['data'];

        if (expenseData != null) {
          final expense = ExpenseModel.fromJson(expenseData);

          currentExpense.value = expense;
          populateFormFields(expense);
        } else {
          _showErrorAndGoBack('No expense data received');
        }
      } else {
        final errorMessage = result['message'] ?? 'Failed to load expense data';
        _showErrorAndGoBack(errorMessage);
      }
    } catch (e) {
      print('Error in loadExpenseData: $e'); // Debug log
      _showErrorAndGoBack('Failed to load expense: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Populate form fields with expense data
  void populateFormFields(ExpenseModel expense) {
    print('Populating fields with: ${expense.toJson()}');
    try {
      // Populate text controllers with null safety
      expNameController.text = expense.expenseName ?? '';
      dateController.text = expense.expenseDate ?? '';
      descriptionController.text = expense.description ?? '';
      amountController.text = expense.amount?.toString() ?? '0';
      spentByController.text = expense.spentBy ?? '';

      // Set dropdown values with null checks
      final category = expense.expenseCategory;
      if (category != null &&
          category.isNotEmpty &&
          categoryTypes.contains(category)) {
        selectedCategoryTypes.value = category;
      }

      final paymentMode = expense.modeOfPayment;
      if (paymentMode != null &&
          paymentMode.isNotEmpty &&
          modeOfPayment.contains(paymentMode)) {
        selectedModeOfPayment.value = paymentMode;
      }

      // Handle image if exists
      final imageUrl = expense.expenseImageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _loadImageFromUrl(imageUrl);
      }

      // Store original expense data for comparison
      originalExpense = expense;
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  // Load image from URL using service (enhanced to use full URL)
  Future<void> _loadImageFromUrl(String imageUrl) async {
    try {
      // Use the full image URL for loading
      final fullImageUrl = getFullImageUrl(imageUrl);
      if (fullImageUrl.isEmpty) {
        print('Empty image URL, skipping image load');
        return;
      }

      final imageBytes = await _expenseService.loadImageFromUrl(fullImageUrl);
      if (imageBytes != null) {
        image.value = imageBytes;
      }
    } catch (e) {}
  }

  // Date picker
  Future<void> selectDate() async {
    final context = Get.context;
    if (context == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Image picker
  Future<void> selectImage() async {
    try {
      isUploading.value = true;

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        image.value = bytes;
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  // Validation with proper null checks
  bool validateForm() {
    final expenseName = expNameController.text.trim();
    if (expenseName.isEmpty) {
      _showValidationError('Please enter expense name');
      return false;
    }

    final date = dateController.text.trim();
    if (date.isEmpty) {
      _showValidationError('Please select expense date');
      return false;
    }

    final category = selectedCategoryTypes.value;
    if (category == null || category.isEmpty) {
      _showValidationError('Please select expense category');
      return false;
    }

    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      _showValidationError('Please enter amount');
      return false;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showValidationError('Please enter a valid amount');
      return false;
    }

    final spentBy = spentByController.text.trim();
    if (spentBy.isEmpty) {
      _showValidationError('Please enter spent by');
      return false;
    }

    final paymentMode = selectedModeOfPayment.value;
    if (paymentMode == null || paymentMode.isEmpty) {
      _showValidationError('Please select mode of payment');
      return false;
    }

    return true;
  }

  // Helper method for validation errors
  void _showValidationError(String message) {
    CustomSnackbar.showError(title: 'Error', message: message);
  }

  // Update expense using service
  Future<void> updateExpense() async {
    if (!validateForm()) return;

    final id = expenseId.value;
    final currentExp = currentExpense.value;

    if (id == null || id.isEmpty) {
      _showValidationError('Invalid expense ID');
      return;
    }

    if (currentExp == null) {
      _showValidationError('Current expense data not available');
      return;
    }

    try {
      isSaving.value = true;

      // Create updated expense model with null safety
      final updatedExpense = ExpenseModel(
        id: currentExp.id,
        expenseName: expNameController.text.trim(),
        expenseDate: dateController.text.trim(),
        expenseCategory: selectedCategoryTypes.value ?? '',
        description: descriptionController.text.trim(),
        amount: double.tryParse(amountController.text.trim()) ?? 0.0,
        spentBy: spentByController.text.trim(),
        modeOfPayment: selectedModeOfPayment.value ?? '',
        expenseImageUrl: currentExp.expenseImageUrl,
      );

      // Call service method to update expense
      final result = await _expenseService.updateExpense(
        id: id,
        expense: updatedExpense,
        imageBytes: image.value,
      );

      print('Service response: $result');

      // Check for success with multiple possible formats
      bool isSuccess = false;
      if (result != null) {
        if (result['success'] == true ||
            result['success'] == 'true' ||
            result['status'] == 'success' ||
            result['status'] == true) {
          isSuccess = true;
        }
      }

      isSaving.value = false;

      if (isSuccess) {
        // Update current expense with response data if available
        final responseData = result['data'];
        if (responseData != null) {
          currentExpense.value = ExpenseModel.fromJson(responseData);
        }

        // ✅ Navigate back with success arguments - let the expenses page show the message
        Get.offAllNamed(
          Routes.EXPENSES,
          arguments: {
            'refresh': true,
            'showSuccess': true,
            'message': result['message'] ?? 'Expense updated successfully',
          },
        );
      } else {
        // ✅ Only show error messages here
        CustomSnackbar.showError(
          title: 'Error',
          message: result['message'] ?? 'Failed to update expense',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to update expense: ${e.toString()}',
      );
    } finally {
      isSaving.value = false;
    }
  }

  // Check if form data has changed
  bool hasDataChanged() {
    if (originalExpense == null) return false;

    return expNameController.text.trim() !=
            (originalExpense!.expenseName ?? '') ||
        dateController.text.trim() != (originalExpense!.expenseDate ?? '') ||
        descriptionController.text.trim() !=
            (originalExpense!.description ?? '') ||
        amountController.text.trim() !=
            (originalExpense!.amount.toString() ?? '') ||
        spentByController.text.trim() != (originalExpense!.spentBy) ||
        selectedCategoryTypes.value != originalExpense!.expenseCategory ||
        selectedModeOfPayment.value != originalExpense!.modeOfPayment ||
        image.value != null; // New image selected
  }

  // Navigation methods
  void navigateToViewExpenses() {
    Get.back();
  }

  void navigateToTab(int index) {
    selectedIndex.value = index;
    // Add your tab navigation logic here
  }

  // Clear form data
  void clearForm() {
    expNameController.clear();
    dateController.clear();
    descriptionController.clear();
    amountController.clear();
    spentByController.clear();
    selectedCategoryTypes.value = null;
    selectedModeOfPayment.value = null;
    image.value = null;
  }

  // Refresh expense data
  Future<void> refreshData() async {
    await loadExpenseData();
  }
}
