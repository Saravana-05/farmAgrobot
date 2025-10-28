import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_expense_controller.dart';

class EditExpense extends StatelessWidget {
  const EditExpense({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditExpenseController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Edit Expense',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewExpenses(),
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading expense data...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
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
                  'Expense Name',
                  controller.expNameController,
                  Icons.money,
                ),
                const SizedBox(height: 20.0),
                _buildDateField(controller),
                const SizedBox(height: 20.0),
                _buildCategoryDropdown(controller),
                const SizedBox(height: 20.0),
                _buildTextField(
                  'Description',
                  controller.descriptionController,
                  Icons.description,
                  isMultiline: true,
                ),
                const SizedBox(height: 20.0),
                _buildTextField(
                  'Amount',
                  controller.amountController,
                  Icons.money_off_sharp,
                  isNumeric: true,
                ),
                const SizedBox(height: 20.0),
                _buildTextField(
                  'Spent By',
                  controller.spentByController,
                  Icons.person_add,
                ),
                const SizedBox(height: 20.0),
                _buildModeOfPaymentDropdown(controller),
                const SizedBox(height: 20.0),
                _buildImagePicker(controller),
                const SizedBox(height: 20.0),
                Obx(() => CustomElevatedButton(
                      text: controller.isSaving.value
                          ? 'Updating...'
                          : 'Update Expense',
                      onPressed: controller.isSaving.value
                          ? () {}
                          : () => controller.updateExpense(),
                      backgroundColor: kPrimaryColor,
                      textColor: kLightColor,
                    ))
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

  Widget _buildDateField(EditExpenseController controller) {
    return TextField(
      controller: controller.dateController,
      readOnly: true,
      onTap: () => controller.selectDate(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.date_range, color: kPrimaryColor),
        labelText: 'Expense Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildCategoryDropdown(EditExpenseController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedCategoryTypes.value,
          onChanged: (String? newValue) {
            controller.selectedCategoryTypes.value = newValue;
          },
          items: controller.categoryTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Expense Category',
            prefixIcon: const Icon(Icons.category, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ));
  }

  Widget _buildModeOfPaymentDropdown(EditExpenseController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedModeOfPayment.value,
          onChanged: (String? newValue) {
            controller.selectedModeOfPayment.value = newValue;
          },
          items: controller.modeOfPayment.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Mode of Payment',
            prefixIcon: const Icon(Icons.payment, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select mode of payment';
            }
            return null;
          },
        ));
  }

  Widget _buildImagePicker(EditExpenseController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Stack(
                  children: [
                    GestureDetector(
                      onTap: controller.isUploading.value
                          ? null
                          : () => controller.selectImage(),
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundImage: controller.image.value != null
                            ? MemoryImage(controller.image.value!)
                            : const AssetImage('assets/images/exp_avatar.jpg')
                                as ImageProvider,
                        child: controller.image.value == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Colors.grey,
                              )
                            : null,
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
                      labelText: 'Update Expense Bill',
                      hintText: controller.isUploading.value
                          ? 'Processing...'
                          : controller.image.value != null
                              ? 'Image selected'
                              : 'Choose a receipt image',
                      prefixIcon: const Icon(Icons.receipt_long),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      filled: true,
                      fillColor: controller.image.value != null
                          ? Colors.green.withOpacity(0.1)
                          : kLightGreen,
                    ),
                    readOnly: true,
                    onTap: controller.isUploading.value
                        ? null
                        : () => controller.selectImage(),
                  )),
            ),
          ],
        ),
        if (controller.image.value != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  controller.image.value = null;
                },
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
