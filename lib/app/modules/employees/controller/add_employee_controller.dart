import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/services/employee/emp_service.dart';
import '../../../routes/app_pages.dart';

class AddEmployeeController extends GetxController {
  // Observable variables
  var isSaving = false.obs;
  var image = Rxn<Uint8List>();
  var selectedIndex = 0.obs;
  var isUploading = false.obs;
  var selectedEmployeeType = Rxn<String>();
  var selectedGender = Rxn<String>();
  var selectedStatus = true.obs;

  // Text controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tamilNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController joiningDateController = TextEditingController();

  // Service
  final EmployeeService _employeeService = Get.put(EmployeeService());

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  // Static data
  final List<String> employeeTypes = ['Regular', 'Contract', 'Others'];
  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  void onInit() {
    super.onInit();
    // Set current date as default
    joiningDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void onClose() {
    nameController.dispose();
    tamilNameController.dispose();
    contactController.dispose();
    joiningDateController.dispose();
    super.onClose();
  }

  Future<void> selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      joiningDateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
        Get.snackbar(
          'Info',
          'No image selected',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      _imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();

      // Set the image directly
      image.value = imageBytes;

      Get.snackbar(
        'Success',
        'Image selected successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter employee name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (tamilNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter Tamil name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedEmployeeType.value == null ||
        selectedEmployeeType.value!.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select employee type',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedGender.value == null ||
        selectedGender.value!.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select gender',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (contactController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter contact number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (contactController.text.trim().length < 10) {
      Get.snackbar(
        'Validation Error',
        'Please enter valid contact number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (joiningDateController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select joining date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  void saveEmployee() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Create employee model
      Employee employee = Employee(
        id: '', // Will be set by the backend
        name: nameController.text.trim(),
        tamilName: tamilNameController.text.trim(),
        empType: selectedEmployeeType.value!.toLowerCase(),
        gender: selectedGender.value!.toLowerCase(),
        contact: contactController.text.trim(),
        joiningDate: DateTime.parse(joiningDateController.text.trim()),
        status: selectedStatus.value,
      );

      // Save employee to API
      Map<String, dynamic> result = await EmployeeService.saveEmployee(
        employee: employee,
        imageFile: _imageFile,
        imageBytes: image.value,
        useDefaultImage: _imageFile == null && image.value == null, employeeData: {},
      );

      if (result['success']) {
        Get.snackbar(
          'Success',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Clear form
        _clearForm();
        // Wait for snackbar to show
        await Future.delayed(Duration(milliseconds: 1000));
        // Navigate back with success result
        Get.offAllNamed(Routes.EMPLOYEE, arguments: true);
      } else {
        Get.snackbar(
          'Error',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save employee: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    nameController.clear();
    tamilNameController.clear();
    contactController.clear();
    joiningDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    selectedEmployeeType.value = null;
    selectedGender.value = null;
    selectedStatus.value = true;
    image.value = null;
    _imageFile = null;
  }

  void navigateToViewEmployees() {
    Get.toNamed(Routes.EMPLOYEE);
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