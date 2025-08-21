import 'package:farm_agrobot/app/config/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_employee_controller.dart';

class EditEmployee extends StatelessWidget {
  const EditEmployee({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditEmployeeController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Edit Employee',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewEmployees(),
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  'Employee Name',
                  controller.nameController,
                  Icons.person,
                ),
                const SizedBox(height: 20.0),
                _buildTextField(
                  'Tamil Name',
                  controller.tamilNameController,
                  Icons.language,
                ),
                const SizedBox(height: 20.0),
                _buildEmployeeTypeDropdown(controller),
                const SizedBox(height: 20.0),
                _buildGenderDropdown(controller),
                const SizedBox(height: 20.0),
                _buildTextField(
                  'Contact Number',
                  controller.contactController,
                  Icons.phone,
                  isNumeric: true,
                ),
                const SizedBox(height: 20.0),
                _buildDateField(controller),
                const SizedBox(height: 20.0),
                _buildStatusDropdown(controller),
                const SizedBox(height: 20.0),
                _buildImagePicker(controller),
                const SizedBox(height: 30.0),
                Obx(() => CustomElevatedButton(
                      text: controller.isSaving.value
                          ? 'Updating...'
                          : 'Update Employee',
                      onPressed: controller.isSaving.value
                          ? () {}
                          : () => controller.updateEmployee(),
                      backgroundColor: kPrimaryColor,
                      textColor: kLightColor,
                    )),
                const SizedBox(height: 20.0),
                // Cancel button
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kSecondaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: controller.navigateToTab,
          )),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumeric = false,
    bool isMultiline = false,
    Color iconColor = kPrimaryColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric
          ? TextInputType.number
          : (isMultiline ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiline ? null : 1,
      // Add Tamil font support like your existing code
      style: TextStyle(
        fontFamily: label.contains('Tamil') ? 'NotoSansTamil' : null,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDateField(EditEmployeeController controller) {
    return TextField(
      controller: controller.joiningDateController,
      readOnly: true,
      onTap: () => controller.selectJoiningDate(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.date_range, color: kPrimaryColor),
        labelText: 'Joining Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildEmployeeTypeDropdown(EditEmployeeController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedEmployeeType.value,
          onChanged: (String? newValue) {
            controller.selectedEmployeeType.value = newValue;
          },
          items: controller.employeeTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Employee Type',
            prefixIcon: const Icon(Icons.work, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ));
  }

  Widget _buildGenderDropdown(EditEmployeeController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedGender.value,
          onChanged: (String? newValue) {
            controller.selectedGender.value = newValue;
          },
          items: controller.genders.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.person_outline, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ));
  }

  Widget _buildStatusDropdown(EditEmployeeController controller) {
    return Obx(() => DropdownButtonFormField<bool>(
          value: controller.selectedStatus.value,
          onChanged: (bool? newValue) {
            controller.selectedStatus.value = newValue ?? true;
          },
          items: const [
            DropdownMenuItem<bool>(
              value: true,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Active'),
                ],
              ),
            ),
            DropdownMenuItem<bool>(
              value: false,
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Inactive'),
                ],
              ),
            ),
          ],
          decoration: InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(
              controller.selectedStatus.value
                  ? Icons.toggle_on
                  : Icons.toggle_off,
              color:
                  controller.selectedStatus.value ? Colors.green : Colors.red,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ));
  }

  Widget _buildImagePicker(EditEmployeeController controller) {
    return Column(
      children: [
        // Current Image Display
        Obx(() => Row(
              children: [
                // Image Preview
                GestureDetector(
                  onTap: () => controller.selectImage(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50.0,
                        backgroundImage: controller.image.value != null
                            ? MemoryImage(controller.image.value!)
                            : (controller.currentImageUrl.value.isNotEmpty
                                    ? NetworkImage(controller
                                            .currentImageUrl.value
                                            .startsWith('http')
                                        ? controller.currentImageUrl.value
                                        : getFullImageUrl(
                                            controller.currentImageUrl.value))
                                    : const AssetImage(
                                        'assets/images/avatar.jpg'))
                                as ImageProvider,
                        child: controller.image.value == null &&
                                controller.currentImageUrl.value.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      if (controller.isUploading.value)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      
                    ],
                  ),
                ),
                const SizedBox(width: 20.0),
                // Upload/Remove buttons
                Expanded(
                  child: Column(
                    children: [
                      // Upload button
                      Obx(() => TextField(
                            decoration: InputDecoration(
                              labelText: 'Update Emp Photo',
                              hintText: controller.isUploading.value
                                  ? 'Processing...'
                                  : 'Tap to change image',
                              prefixIcon: const Icon(Icons.photo_camera,
                                  color: kPrimaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                              filled: true,
                              fillColor: kLightGreen,
                            ),
                            readOnly: true,
                            onTap: controller.isUploading.value
                                ? null
                                : () => controller.selectImage(),
                          )),
                      const SizedBox(height: 10.0),
                      // Remove image button
                      if (controller.image.value != null ||
                          controller.currentImageUrl.value.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => controller.removeImage(),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Remove Image',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )),
      ],
    );
  }
}
