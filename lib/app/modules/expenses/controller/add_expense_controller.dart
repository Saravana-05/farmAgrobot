import 'dart:io';
import 'dart:typed_data';
import 'package:farm_agrobot/app/global_widgets/custom_snackbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/services/expenses/expense_service.dart';
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

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
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
        CustomSnackbar.showInfo(title: 'Info', message: 'No image selected');
        return;
      }

      _imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();

      // Set the image directly
      image.value = imageBytes;

      CustomSnackbar.showInfo(
          title: 'Info', message: 'Image selected successfully');
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  bool _validateForm() {
    if (expNameController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter expense name');
      return false;
    }

    if (dateController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please select expense date');
      return false;
    }

    if (selectedCategoryTypes.value == null ||
        selectedCategoryTypes.value!.isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please select expense category');

      return false;
    }

    if (amountController.text.trim().isEmpty) {
      CustomSnackbar.showError(title: 'Error', message: 'Please enter amount');
      return false;
    }

    if (double.tryParse(amountController.text.trim()) == null) {
      CustomSnackbar.showError(title: 'Error', message: 'Please enter amount');
      return false;
    }

    if (spentByController.text.trim().isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please enter spent by');
      return false;
    }

    if (selectedModeOfPayment.value == null ||
        selectedModeOfPayment.value!.isEmpty) {
      CustomSnackbar.showError(
          title: 'Error', message: 'Please select mode of payment');

      return false;
    }

    return true;
  }

  void saveExpense() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Create expense model
      ExpenseModel expense = ExpenseModel(
        expenseName: expNameController.text.trim(),
        expenseDate: dateController.text.trim(),
        expenseCategory: selectedCategoryTypes.value!,
        description: descriptionController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        spentBy: spentByController.text.trim(),
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
        CustomSnackbar.showSuccess(
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
        CustomSnackbar.showError(title: 'Error', message: result['message']);
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: e.toString());
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
