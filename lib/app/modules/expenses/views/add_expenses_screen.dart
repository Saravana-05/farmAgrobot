import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_expense_controller.dart';

class AddExpenses extends StatelessWidget {
  const AddExpenses({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddExpensesController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Add Expenses',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                'Expense Name',
                controller.expNameController,
                Icons.money,
                isRequired: true,
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
                isRequired: true,
              ),
              const SizedBox(height: 20.0),
              _buildTextField(
                'Spent By',
                controller.spentByController,
                Icons.person_add,
                isRequired: true,
              ),
              const SizedBox(height: 20.0),
              _buildModeOfPaymentDropdown(controller),
              const SizedBox(height: 20.0),
              _buildImagePicker(controller),
              const SizedBox(height: 30.0),
              // Required fields note
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fields marked with * are required',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              Obx(() => CustomElevatedButton(
                    text: controller.isSaving.value
                        ? 'Saving...'
                        : 'Add Expenses',
                    onPressed: controller.isSaving.value
                        ? () {}
                        : () => controller.saveExpense(),
                    backgroundColor: kPrimaryColor,
                    textColor: kLightColor,
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
    bool isRequired = false,
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
        labelText: isRequired ? '$label *' : label,
        hintText: isRequired ? 'This field is required' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(
            color: kPrimaryColor,
            width: 2.0,
          ),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildDateField(AddExpensesController controller) {
    return TextField(
      controller: controller.dateController,
      readOnly: true,
      onTap: () => controller.selectDate(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.date_range, color: kPrimaryColor),
        labelText: 'Expense Date *',
        hintText: 'This field is required',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(
            color: kPrimaryColor,
            width: 2.0,
          ),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        suffixIcon: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 8),
            Icon(
              Icons.calendar_today,
              color: kSecondaryColor,
              size: 20,
            ),
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(AddExpensesController controller) {
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
            labelText: 'Expense Category *',
            hintText: 'This field is required',
            prefixIcon: const Icon(Icons.category, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(
                color: kPrimaryColor,
                width: 2.0,
              ),
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

  Widget _buildModeOfPaymentDropdown(AddExpensesController controller) {
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
            labelText: 'Mode of Payment *',
            hintText: 'This field is required',
            prefixIcon: const Icon(Icons.payment, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(
                color: kPrimaryColor,
                width: 2.0,
              ),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a payment mode';
            }
            return null;
          },
        ));
  }

  Widget _buildImagePicker(AddExpensesController controller) {
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
                            : const AssetImage('assets/images/exp_avatar.jpg')
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
                      labelText: 'Upload Expense Bill (Optional)',
                      hintText: controller.isUploading.value
                          ? 'Processing...'
                          : 'Choose a receipt image',
                      prefixIcon: const Icon(Icons.receipt_long),
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
