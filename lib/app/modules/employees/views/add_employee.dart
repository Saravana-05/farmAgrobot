import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_employee_controller.dart';

class AddEmployee extends StatelessWidget {
  const AddEmployee({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddEmployeeController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Add Employee',
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
      body: SingleChildScrollView(
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
              _buildImagePicker(controller),
              const SizedBox(height: 20.0),
              Obx(() => CustomElevatedButton(
                    text: controller.isSaving.value
                        ? 'Saving...'
                        : 'Add Employee',
                    onPressed: controller.isSaving.value
                        ? () {}
                        : () => controller.saveEmployee(),
                  ))
            ],
          ),
        ),
      ),
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
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildDateField(AddEmployeeController controller) {
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
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildEmployeeTypeDropdown(AddEmployeeController controller) {
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
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
        ));
  }

  Widget _buildGenderDropdown(AddEmployeeController controller) {
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
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
        ));
  }

  Widget _buildStatusDropdown(AddEmployeeController controller) {
    return Obx(() => DropdownButtonFormField<bool>(
          value: controller.selectedStatus.value,
          onChanged: (bool? newValue) {
            controller.selectedStatus.value = newValue ?? true;
          },
          items: const [
            DropdownMenuItem<bool>(
              value: true,
              child: Text('Active'),
            ),
            DropdownMenuItem<bool>(
              value: false,
              child: Text('Inactive'),
            ),
          ],
          decoration: InputDecoration(
            labelText: 'Status',
            prefixIcon: const Icon(Icons.toggle_on, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
        ));
  }

  Widget _buildImagePicker(AddEmployeeController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Stack(
                  children: [
                    GestureDetector(
                      onTap: () => controller.selectImage(),
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundImage: controller.image.value != null
                            ? MemoryImage(controller.image.value!)
                            : const AssetImage('assets/images/emp_avatar.jpg')
                                as ImageProvider,
                      ),
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
                )),
            const SizedBox(width: 20.0),
            Expanded(
              child: Obx(() => TextField(
                    decoration: InputDecoration(
                      labelText: 'Upload Employee Photo',
                      hintText: controller.isUploading.value
                          ? 'Processing...'
                          : 'Choose a profile image',
                      prefixIcon: const Icon(Icons.photo_camera),
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
            ),
          ],
        ),
      ],
    );
  }
}