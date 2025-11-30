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

  // Static data
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

  /// ✅ Fixed: Always use overlay context for dialogs
  void selectImage() {
    final ctx = Get.overlayContext;
    if (ctx == null) {
      // Delay until overlay is ready
      WidgetsBinding.instance.addPostFrameCallback((_) => selectImage());
      return;
    }

    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return AlertDialog(
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
                const SizedBox(height: 10),
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
        );
      },
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
        CustomFlashMessage.showInfo(
          title: 'Info',
          message: 'No image selected',
        );
        return;
      }

      _imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();
      image.value = imageBytes;

      CustomFlashMessage.showInfo(
        title: 'Info',
        message: 'Image selected successfully',
      );
    } catch (e) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      isUploading.value = false;
    }
  }

  bool _validateForm() {
    if (expNameController.text.trim().isEmpty) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Expense name cannot be empty',
      );
      return false;
    }

    if (expNameController.text.trim().length < 2) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Expense name must be at least 2 characters',
      );
      return false;
    }

    if (dateController.text.trim().isEmpty) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Please select expense date',
      );
      return false;
    }

    if (selectedCategoryTypes.value == null ||
        selectedCategoryTypes.value!.isEmpty) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Please select expense category',
      );
      return false;
    }

    if (amountController.text.trim().isEmpty) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Please enter amount',
      );
      return false;
    }

    double? amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Please enter a valid amount greater than 0',
      );
      return false;
    }

    if (amount > 999999999.99) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Amount is too large',
      );
      return false;
    }

    if (selectedModeOfPayment.value == null ||
        selectedModeOfPayment.value!.isEmpty) {
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'Please select mode of payment',
      );
      return false;
    }

    return true;
  }

  /// ✅ Safe snackbar usage with overlay context
  bool validateDate(String dateText) {
    if (dateText.isEmpty) return false;

    try {
      DateTime selectedDate = DateTime.parse(
          DateFormat('dd-MM-yyyy').parse(dateText).toIso8601String());
      DateTime currentDate = DateTime.now();

      selectedDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      currentDate =
          DateTime(currentDate.year, currentDate.month, currentDate.day);

      if (selectedDate.isAfter(currentDate)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
        });
        return false;
      }

      return true;
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
      return false;
    }
  }

  Future<void> selectDate() async {
    final ctx = Get.overlayContext!;
    DateTime? selectedDate = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      String formattedDate =
          "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
      dateController.text = formattedDate;
    }
  }

  Future<void> saveExpense() async {
    if (isSaving.value) return;
    if (!_validateForm()) return;
    if (!validateDate(dateController.text)) return;

    try {
      isSaving.value = true;

      final expense = ExpenseModel(
        expenseName: expNameController.text.trim(),
        expenseDate: dateController.text.trim(),
        expenseCategory: selectedCategoryTypes.value!,
        description: descriptionController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        spentBy: spentByController.text.trim(),
        modeOfPayment: selectedModeOfPayment.value!,
      );

      final result = await _expenseService.saveExpense(
        expense: expense,
        imageFile: _imageFile,
        imageBytes: image.value,
        useDefaultImage: _imageFile == null && image.value == null,
      );

      isSaving.value = false;

      if (result['success']) {
        _clearForm();
        Get.offAllNamed(
          Routes.EXPENSES,
          arguments: {
            'refresh': true,
            'showSuccess': true,
            'message': result['message'] ?? 'Expense added successfully',
          },
        );
      } else {
        String errorMessage = result['message'] ?? 'Failed to save expense';
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          if (errors.containsKey('spent_by')) {
            errorMessage = errors['spent_by'][0];
          } else if (errors.containsKey('expense_name')) {
            errorMessage = errors['expense_name'][0];
          } else if (errors.containsKey('amount')) {
            errorMessage = errors['amount'][0];
          } else if (errors.containsKey('expense_date')) {
            errorMessage = errors['expense_date'][0];
          }
        }
        CustomFlashMessage.showError(title: 'Error', message: errorMessage);
      }
    } catch (e) {
      isSaving.value = false;
      CustomFlashMessage.showError(
        title: 'Error',
        message: 'An error occurred: ${e.toString()}',
      );
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

  void navigateToViewExpenses() => Get.toNamed(Routes.EXPENSES);

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
