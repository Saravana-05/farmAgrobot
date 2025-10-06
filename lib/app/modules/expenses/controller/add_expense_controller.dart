import 'dart:io';
import 'dart:typed_data';
import '../../../core/values/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/services/expenses/expense_service.dart';
import '../../../global_widgets/custom_snackbar/flash_message.dart';
import '../../../routes/app_pages.dart';

class AddExpensesController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var image = Rxn<Uint8List>();
  var selectedIndex = 0.obs;
  var isUploading = false.obs;
  var selectedCategoryTypes = Rxn<String>();
  var selectedModeOfPayment = Rxn<String>();

  // Text controllers
  final TextEditingController expNameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController spentByController = TextEditingController();

  // Service
  final ExpenseService _expenseService = Get.put(ExpenseService());

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  // Static data (replacing Firebase data)
  final List<String> modeOfPayment = ['Cash', 'Card', 'UPI', 'Bank', 'Cheque'];
  final List<String> categoryTypes = [
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
  ];

  @override
  void onInit() {
    super.onInit();
    // Set current date as default
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

  void selectImage() {
    Get.dialog(
      AlertDialog(
        title: const Text('Choose an option'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              GestureDetector(
                child: const Text('Camera'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.camera);
                },
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              GestureDetector(
                child: const Text('Gallery'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      isUploading.value = true;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        CustomFlashMessage.showInfo(title: 'Info', message: 'No image selected');
        return;
      }

      _imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();

      // Set the image directly
      image.value = imageBytes;

      CustomFlashMessage.showInfo(
          title: 'Info', message: 'Image selected successfully');
    } catch (e) {
      CustomFlashMessage.showError(title: 'Error', message: e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  bool _validateForm() {
    // Expense name validation (matches backend: not empty, min 2 chars)
    if (expNameController.text.trim().isEmpty) {
      CustomFlashMessage.showError(
          title: 'Error', message: 'Expense name cannot be empty');
      return false;
    }

    if (expNameController.text.trim().length < 2) {
      CustomFlashMessage.showError(
          title: 'Error',
          message: 'Expense name must be at least 2 characters');
      return false;
    }

    // Date validation
    if (dateController.text.trim().isEmpty) {
      CustomFlashMessage.showError(
          title: 'Error', message: 'Please select expense date');
      return false;
    }

    // Category validation
    if (selectedCategoryTypes.value == null ||
        selectedCategoryTypes.value!.isEmpty) {
      CustomFlashMessage.showError(
          title: 'Error', message: 'Please select expense category');
      return false;
    }

    // Amount validation (matches backend: > 0, not too large)
    if (amountController.text.trim().isEmpty) {
      CustomFlashMessage.showError(title: 'Error', message: 'Please enter amount');
      return false;
    }

    double? amount = double.tryParse(amountController.text.trim());
    if (amount == null) {
      CustomFlashMessage.showError(
          title: 'Error', message: 'Please enter a valid amount');
      return false;
    }

    if (amount <= 0) {
      CustomFlashMessage.showError(
          title: 'Error', message: 'Amount must be greater than 0');
      return false;
    }

    if (amount > 999999999.99) {
      CustomFlashMessage.showError(title: 'Error', message: 'Amount is too large');
      return false;
    }

    // Mode of payment validation
    if (selectedModeOfPayment.value == null ||
        selectedModeOfPayment.value!.isEmpty) {
      CustomFlashMessage.showError(
          title: 'Error', message: 'Please select mode of payment');
      return false;
    }

    return true;
  }

  // Date validation method (restrict future dates)
  bool validateDate(String dateText) {
    if (dateText.isEmpty) return false;

    try {
      // Parse the date from the dateController text
      // Adjust the format based on how you format the date in your selectDate method
      DateTime selectedDate =
          DateTime.parse(dateText); // Modify this based on your date format
      DateTime currentDate = DateTime.now();

      // Remove time component for comparison
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      currentDate =
          DateTime(currentDate.year, currentDate.month, currentDate.day);

      if (selectedDate.isAfter(currentDate)) {
        Get.snackbar(
          'Invalid Date',
          'Future dates are not allowed for expenses',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
          icon: const Icon(Icons.calendar_today, color: Colors.orange),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
          borderRadius: 8,
        );
        return false;
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Invalid Date Format',
        'Please select a valid date',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.red),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
      );
      return false;
    }
  }

// Updated selectDate method with future date restriction
  Future<void> selectDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Restrict to current date and earlier
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Format the date as needed (adjust format as per your requirement)
      String formattedDate =
          "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
      dateController.text = formattedDate;
    }
  }

  void saveExpense() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    // Validate date before sending to server
    if (!validateDate(dateController.text)) return;

    try {
      isSaving.value = true;

      // Create expense model
      ExpenseModel expense = ExpenseModel(
        expenseName: expNameController.text.trim(),
        expenseDate: dateController.text.trim(),
        expenseCategory: selectedCategoryTypes.value!,
        description: descriptionController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        spentBy: spentByController.text
            .trim(), // Send even if empty - let backend handle
        modeOfPayment: selectedModeOfPayment.value!,
      );

      // Save expense to API
      Map<String, dynamic> result = await _expenseService.saveExpense(
        expense: expense,
        imageFile: _imageFile,
        imageBytes: image.value,
        useDefaultImage: _imageFile == null && image.value == null,
      );

      if (result['success']) {
        CustomFlashMessage.showSuccess(
          title: 'Success',
          message: result['message'],
        );

        // Clear form
        _clearForm();
        // Wait for snackbar to show
        await Future.delayed(Duration(milliseconds: 1000));
        // Navigate back with success result
        Get.offAllNamed(Routes.EXPENSES, arguments: true);
      } else {
        // Handle backend validation errors
        String errorMessage = result['message'];

        // Check if there are specific field errors from backend
        if (result.containsKey('errors') && result['errors'] != null) {
          Map<String, dynamic> errors = result['errors'];

          // Handle specific backend validation errors
          if (errors.containsKey('spent_by')) {
            errorMessage =
                errors['spent_by'][0]; // Django returns array of errors
          } else if (errors.containsKey('expense_name')) {
            errorMessage = errors['expense_name'][0];
          } else if (errors.containsKey('amount')) {
            errorMessage = errors['amount'][0];
          }
        }

        CustomFlashMessage.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      CustomFlashMessage.showError(title: 'Error', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    expNameController.clear();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    selectedCategoryTypes.value = null;
    descriptionController.clear();
    amountController.clear();
    spentByController.clear();
    selectedModeOfPayment.value = null;
    image.value = null;
    _imageFile = null;
  }

  void navigateToViewExpenses() {
    Get.toNamed(Routes.EXPENSES);
  }

  void navigateToTab(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.offAllNamed('/home');
        break;
      case 1:
        Get.offAllNamed('/dashboard');
        break;
      case 2:
        Get.offAllNamed('/settings');
        break;
    }
  }
}
