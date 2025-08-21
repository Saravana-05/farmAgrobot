import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../data/services/employee/emp_service.dart';
import '../../../data/services/messages/message_service.dart';
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
    joiningDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
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
        MessageService.to.showInfo('info_no_image');
        return;
      }

      _imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();
      image.value = imageBytes;

      MessageService.to.showSuccess('success_image_selected');
    } catch (e) {
      MessageService.to.showError(
          'error_image_selection', 'Failed to load image: ${e.toString()}');
    } finally {
      isUploading.value = false;
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      MessageService.to.showValidationError('name');
      return false;
    }

    if (tamilNameController.text.trim().isEmpty) {
      MessageService.to.showValidationError('tamil_name');
      return false;
    }

    // Validate Tamil text contains valid characters
    if (!_isValidTamilText(tamilNameController.text.trim())) {
      MessageService.to.showError('error_tamil_validation', 
          'Tamil name contains invalid characters');
      return false;
    }

    if (selectedEmployeeType.value == null ||
        selectedEmployeeType.value!.isEmpty) {
      MessageService.to.showValidationError('employee_type');
      return false;
    }

    if (selectedGender.value == null || selectedGender.value!.isEmpty) {
      MessageService.to.showValidationError('gender');
      return false;
    }

    if (contactController.text.trim().isEmpty) {
      MessageService.to.showValidationError('contact');
      return false;
    }

    if (contactController.text.trim().length < 10) {
      MessageService.to.showWarning('validation_contact_invalid');
      return false;
    }

    if (joiningDateController.text.trim().isEmpty) {
      MessageService.to.showValidationError('joining_date');
      return false;
    }

    return true;
  }

  // Helper method to validate Tamil text
  bool _isValidTamilText(String text) {
    if (text.isEmpty) return false;
    
    try {
      // Try to encode the text as UTF-8 to check if it's valid
      utf8.encode(text);
      return true;
    } catch (e) {
      print('Tamil text validation failed: $e');
      return false;
    }
  }

  // Helper method to safely encode Tamil text
  String _safeTamilEncode(String text) {
    try {
      // Ensure proper UTF-8 encoding
      List<int> utf8Bytes = utf8.encode(text);
      return utf8.decode(utf8Bytes);
    } catch (e) {
      print('Tamil encoding error: $e');
      // Return the original text if encoding fails
      return text;
    }
  }

  Map<String, dynamic> _employeeToRequestData() {
    Map<String, dynamic> data = {};

    // Safely encode text fields, especially Tamil name
    data['name'] = nameController.text.trim();
    data['tamil_name'] = _safeTamilEncode(tamilNameController.text.trim());
    data['emp_type'] = selectedEmployeeType.value!;
    data['gender'] = selectedGender.value!;
    data['contact'] = contactController.text.trim();
    data['joining_date'] = joiningDateController.text.trim();
    data['status'] = selectedStatus.value;

    // Remove null or empty values
    data.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty));

    // Debug print to check the data
    print('Employee data being sent: ${jsonEncode(data)}');

    return data;
  }

  void saveEmployee() async {
    if (isSaving.value) return;

    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Create employee object with properly encoded Tamil name
      Employee employee = Employee(
        id: '',
        name: nameController.text.trim(),
        tamilName: _safeTamilEncode(tamilNameController.text.trim()),
        empType: selectedEmployeeType.value!,
        gender: selectedGender.value!,
        contact: contactController.text.trim(),
        joiningDate: DateTime.parse(joiningDateController.text.trim()),
        status: selectedStatus.value,
      );

      Map<String, dynamic> employeeData = _employeeToRequestData();

      // Debug: Print the data before sending
      print('Sending employee data: ${jsonEncode(employeeData)}');

      Map<String, dynamic> result = await EmployeeService.saveEmployee(
        employee: employee,
        imageFile: _imageFile,
        imageBytes: image.value,
        useDefaultImage: _imageFile == null && image.value == null,
        employeeData: employeeData,
      );

      if (result['success']) {
        String message = result['message'] ??
            result['data']?['message'] ??
            'Employee saved successfully';

        MessageService.to.showSuccess('success_employee_saved', message);

        _clearForm();
        await Future.delayed(Duration(milliseconds: 1000));
        Get.offAllNamed(Routes.EMPLOYEE, arguments: true);
      } else {
        String errorMessage = result['message'] ??
            result['data']?['message'] ??
            'Failed to save employee';

        if (result['data'] != null && result['data']['errors'] != null) {
          Map<String, dynamic> errors = result['data']['errors'];
          String errorDetails = errors.entries
              .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
              .join('\n');
          errorMessage = '$errorMessage\n$errorDetails';
        }

        MessageService.to.showError('error_employee_save', errorMessage);
      }
    } catch (e) {
      print('Error in saveEmployee: $e');
      
      // Check if it's an encoding error
      if (e.toString().contains('ascii') || e.toString().contains('encode')) {
        MessageService.to.showError('error_tamil_encoding', 
            'Tamil text encoding error. Please try typing the Tamil name again.');
      } else {
        MessageService.to.showNetworkError(
            'Network error: Please check your connection and try again');
      }
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    nameController.clear();
    tamilNameController.clear();
    contactController.clear();
    joiningDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
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