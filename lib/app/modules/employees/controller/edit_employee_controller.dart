import 'dart:io';
import 'dart:typed_data';
import 'package:farm_agrobot/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/utils/tamil_text_handler.dart';
import '../../../data/services/employee/emp_service.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import 'emp_view_controller.dart';

class EditEmployeeController extends GetxController {
  // Text Controllers
  final nameController = TextEditingController();
  final tamilNameController = TextEditingController();
  final contactController = TextEditingController();
  final joiningDateController = TextEditingController();

  // Observable variables
  var selectedEmployeeType = Rxn<String>();
  var selectedGender = Rxn<String>();
  var selectedStatus = true.obs;
  var selectedIndex = 2.obs;
  var isSaving = false.obs;
  var isLoading = true.obs;
  var isUploading = false.obs;
  var image = Rxn<Uint8List>();
  var currentImageUrl = ''.obs;
  var imageFile = Rxn<File>();

  // Dropdown options
  final List<String> employeeTypes = ['Regular', 'Contract', 'Others'];
  final List<String> genders = ['Male', 'Female', 'Other'];

  // Employee ID
  String? employeeId;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    // Get employee ID from arguments
    employeeId = Get.arguments['id']?.toString();
    print('Employee ID received: $employeeId');
    if (employeeId != null) {
      loadEmployeeData();
    } else {
      print('No employee ID found in arguments');
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    tamilNameController.dispose();
    contactController.dispose();
    joiningDateController.dispose();
    super.onClose();
  }

  /// Load existing employee data using service
  Future<void> loadEmployeeData() async {
    try {
      isLoading.value = true;

      final result = await EmployeeService.getEmployeeDetail(employeeId!);

      if (result['success'] && result['data']['status'] == 'success') {
        final employeeData = result['data']['data'];

        // Parse employee data with proper Tamil text encoding
        final processedData = _parseEmployeeWithProperEncoding(employeeData);

        // Populate form fields
        nameController.text = processedData['name']?.toString() ?? '';
        tamilNameController.text =
            processedData['tamil_name']?.toString() ?? '';
        contactController.text = processedData['contact']?.toString() ?? '';
        joiningDateController.text =
            processedData['joining_date']?.toString() ?? '';

        // Set dropdown values
        if (processedData['emp_type'] != null &&
            employeeTypes.contains(processedData['emp_type'])) {
          selectedEmployeeType.value = processedData['emp_type'];
        }

        if (processedData['gender'] != null &&
            genders.contains(processedData['gender'])) {
          selectedGender.value = processedData['gender'];
        }

        // Handle status
        _setStatusFromData(processedData['status']);

        // Handle image
        if (processedData['image_url'] != null &&
            processedData['image_url'].toString().isNotEmpty) {
          currentImageUrl.value = processedData['image_url'].toString();
          await _loadImageFromUrl(processedData['image_url'].toString());
        }

        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Employee data loaded successfully',
        );
      } else {
        throw Exception(
            result['data']['message'] ?? 'Failed to load employee data');
      }
    } catch (e) {
      print('Error loading employee data: $e');

      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load employee data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set status from various data types
  void _setStatusFromData(dynamic statusData) {
    if (statusData != null) {
      if (statusData is bool) {
        selectedStatus.value = statusData;
      } else if (statusData is String) {
        selectedStatus.value = statusData.toLowerCase() == 'true' ||
            statusData == '1' ||
            statusData.toLowerCase() == 'active';
      } else if (statusData is int) {
        selectedStatus.value = statusData == 1;
      }
    }
  }

  /// Load image from URL
  Future<void> _loadImageFromUrl(String imageUrl) async {
    try {
      // You can implement this using your existing URL validation logic
      // or use a network image loader
      print('Loading image from: $imageUrl');
      // For now, just store the URL - you can enhance this later
    } catch (e) {
      print('Failed to load image from URL: $e');
    }
  }

  /// Parse employee data with Tamil text encoding
  Map<String, dynamic> _parseEmployeeWithProperEncoding(
      Map<String, dynamic> json) {
    try {
      Map<String, dynamic> processedData = Map<String, dynamic>.from(json);

      // Handle Tamil name field
      if (processedData['tamil_name'] != null) {
        String originalTamilName = processedData['tamil_name'].toString();
        String decodedTamilName =
            TamilTextHandler.decodeTamilText(originalTamilName);
        processedData['tamil_name'] = decodedTamilName;

        if (originalTamilName != decodedTamilName) {
          print(
              'Tamil name decoded: "$originalTamilName" -> "$decodedTamilName"');
        }
      }

      // Handle regular name field
      if (processedData['name'] != null) {
        String originalName = processedData['name'].toString();
        String decodedName = TamilTextHandler.decodeTamilText(originalName);
        processedData['name'] = decodedName;

        if (originalName != decodedName) {
          print('Name decoded: "$originalName" -> "$decodedName"');
        }
      }

      return processedData;
    } catch (e) {
      print('Error parsing employee data with Tamil text: $e');
      return json;
    }
  }

  /// Select and upload image
  Future<void> selectImage() async {
    try {
      isUploading.value = true;

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        image.value = bytes;
        imageFile.value = File(pickedFile.path);

        // Show success message
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Image selected successfully',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to select image: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUploading.value = false;
    }
  }

  /// Select joining date
  Future<void> selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: _parseDate(joiningDateController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      joiningDateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  /// Parse date string to DateTime
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Update employee using service
  Future<void> updateEmployee() async {
    if (!_validateForm()) return;

    try {
      isSaving.value = true;

      // Prepare employee data
      final employeeData = {
        'name': nameController.text.trim(),
        'tamil_name': tamilNameController.text.trim(),
        'contact': contactController.text.trim(),
        'joining_date': joiningDateController.text,
        'emp_type': selectedEmployeeType.value ?? 'Regular',
        'gender': selectedGender.value ?? 'Male',
        'status': selectedStatus.value,
      };

      // Debug logging for Tamil text being sent
      if (tamilNameController.text.trim().isNotEmpty) {
        print('Sending Tamil name: "${tamilNameController.text.trim()}"');
      }

      print('Updating employee with data: $employeeData');

      // Use the service to update employee
      final result = await EmployeeService.editEmployee(
        employeeId: employeeId!,
        employeeData: employeeData,
        imageFile: imageFile.value,
        useDefaultAvatar: false,
        removeImage: image.value == null && currentImageUrl.value.isEmpty,
      );

      print('Update result: $result');

      if (result['success']) {
        final data = result['data'];

        if (data['status'] == 'success') {
          // Refresh employee list for real-time updates first
          await _refreshEmployeeList();

          // Show success message and navigate back immediately
          Get.back(result: {
            'updated': true,
            'employee_id': employeeId,
            'message': 'Employee updated successfully'
          });

          // Show success snackbar after navigation
          CustomSnackbar.showSuccess(
            title: 'Success',
            message: data['message'] ?? 'Employee updated successfully!',
            duration: const Duration(seconds: 2),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to update employee');
        }
      } else {
        throw Exception(
            result['data']['message'] ?? 'Failed to update employee');
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to update employee: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Refresh employee list for real-time updates
  Future<void> _refreshEmployeeList() async {
    try {
      // Try to find and refresh the employee controller
      if (Get.isRegistered<EmployeeViewController>()) {
        final employeeController = Get.find<EmployeeViewController>();
        await employeeController.refreshEmployees();
        print('Employee list refreshed successfully');
      } else {
        print('EmployeeController not found, skipping refresh');
      }
    } catch (e) {
      print('Error refreshing employee list: $e');
    }
  }

  /// Remove current image
  void removeImage() {
    image.value = null;
    imageFile.value = null;
    currentImageUrl.value = '';
    // Show success snackbar
    CustomSnackbar.showSuccess(
      title: 'Success',
      message: 'Image removed',
      duration: const Duration(seconds: 2),
    );
  }

  /// Get display text for form fields with Tamil support
  String getDisplayText(String text) {
    if (text.isEmpty) return text;
    return TamilTextHandler.decodeTamilText(text);
  }

  /// Validate Tamil text input
  bool isValidTamilText(String text) {
    if (text.isEmpty) return true;

    // Tamil Unicode range: U+0B80 to U+0BFF
    final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
    return tamilRegex.hasMatch(text) || text.trim().isNotEmpty;
  }

  /// Validate form fields
  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showValidationError('Employee name is required');
      return false;
    }

    if (contactController.text.trim().isEmpty) {
      _showValidationError('Contact number is required');
      return false;
    }

    // Validate contact number format (basic validation)
    if (!RegExp(r'^\d{10}$').hasMatch(contactController.text.trim())) {
      _showValidationError('Please enter a valid 10-digit contact number');
      return false;
    }

    if (joiningDateController.text.isEmpty) {
      _showValidationError('Joining date is required');
      return false;
    }

    if (selectedEmployeeType.value == null) {
      _showValidationError('Employee type is required');
      return false;
    }

    if (selectedGender.value == null) {
      _showValidationError('Gender is required');
      return false;
    }

    // Validate Tamil name if provided
    if (tamilNameController.text.trim().isNotEmpty &&
        !isValidTamilText(tamilNameController.text.trim())) {
      _showValidationError('Please enter valid Tamil text');
      return false;
    }

    return true;
  }

  /// Show validation error
  void _showValidationError(String message) {
    CustomSnackbar.showError(
      title: 'Error',
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  /// Navigate to different tabs
  void navigateToTab(int index) {
    selectedIndex.value = index;
    switch (index) {
      case 0:
        Get.offAllNamed('/dashboard');
        break;
      case 1:
        Get.offAllNamed('/employees');
        break;
      case 2:
        // Current page - do nothing
        break;
      default:
        break;
    }
  }

  /// Navigate to view employees
  void navigateToViewEmployees() {
    Get.toNamed(Routes.EMPLOYEE);
  }

  /// Force refresh when returning from edit
  void onEmployeeUpdated() {
    _refreshEmployeeList();
  }
}
