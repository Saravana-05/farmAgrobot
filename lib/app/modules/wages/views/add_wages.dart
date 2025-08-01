import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_wage_controller.dart';

class AddWage extends StatelessWidget {
  const AddWage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddWageController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Add Wage',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewWages(),
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEmployeeDropdown(controller),
              const SizedBox(height: 20.0),
              _buildTextField(
                'Amount',
                controller.amountController,
                Icons.attach_money,
                isNumeric: true,
                onChanged: (value) => controller.formatAmountInput(),
              ),
              const SizedBox(height: 20.0),
              _buildEffectiveFromDateField(controller),
              const SizedBox(height: 20.0),
              _buildEffectiveToDateField(controller),
              const SizedBox(height: 20.0),
              _buildTextField(
                'Remarks (Optional)',
                controller.remarksController,
                Icons.notes,
                isMultiline: true,
              ),
              const SizedBox(height: 20.0),
              _buildPreviewCard(controller),
              const SizedBox(height: 20.0),
              Obx(() => CustomElevatedButton(
                    text: controller.isSaving.value ? 'Saving...' : 'Add Wage',
                    onPressed: controller.isSaving.value
                        ? () {}
                        : () => controller.saveWage(),
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
    TextEditingController textController,
    IconData icon, {
    bool isNumeric = false,
    bool isMultiline = false,
    Color iconColor = kPrimaryColor,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: textController,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : (isMultiline ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiline ? 3 : 1,
      onChanged: onChanged,
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

  Widget _buildEmployeeDropdown(AddWageController controller) {
    return Obx(() {
      print("=== DROPDOWN REBUILD ===");
      print("isLoadingEmployees: ${controller.isLoadingEmployees.value}");
      print("employees.length: ${controller.employees.length}");
      print("selectedEmployee: ${controller.selectedEmployee.value?.name}");
      print("selectedEmployee ID: ${controller.selectedEmployee.value?.id}");

      if (controller.isLoadingEmployees.value) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: kSecondaryColor),
            borderRadius: BorderRadius.circular(50.0),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading employees...'),
              ],
            ),
          ),
        );
      }

      if (controller.employees.isEmpty) {
        return Column(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: const Center(
                child: Text(
                  'No employees available',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => controller.refreshEmployees(),
              child: const Text('Retry Loading'),
            ),
          ],
        );
      }

      // Convert selected employee ID to string for dropdown comparison
      String? selectedValue;
      if (controller.selectedEmployee.value != null) {
        selectedValue = controller.selectedEmployee.value!.id.toString();
        print("Dropdown selected value: '$selectedValue'");
      }

      return DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: (String? selectedId) {
          print("=== DROPDOWN SELECTION CHANGED ===");
          print("Selected ID: '$selectedId'");

          if (selectedId == null ||
              selectedId.isEmpty ||
              selectedId == 'null') {
            print("Clearing employee selection");
            controller.selectedEmployee.value = null;
            return;
          }

          try {
            // Find employee by converting both IDs to strings for comparison
            final selectedEmployee = controller.employees.firstWhere(
              (employee) {
                String empIdStr = employee.id.toString();
                print("Comparing: '$empIdStr' == '$selectedId'");
                return empIdStr == selectedId;
              },
              orElse: () => throw Exception(
                  'No employee found'), // Throw an exception if no employee is found
            );

            if (selectedEmployee != null) {
              controller.selectedEmployee.value = selectedEmployee;
              print("✅ Employee selected successfully:");
              print("   Name: ${selectedEmployee.name}");
              print(
                  "   ID: ${selectedEmployee.id} (${selectedEmployee.id.runtimeType})");
              print("   Type: ${selectedEmployee.empType}");

              // Verify the selection is properly stored
              print(
                  "Verification - controller.selectedEmployee.value: ${controller.selectedEmployee.value?.name}");
            } else {
              print("❌ Employee not found for ID: '$selectedId'");
              controller.selectedEmployee.value = null;
            }
          } catch (e) {
            print("❌ Error selecting employee: $e");
            controller.selectedEmployee.value = null;
          }
          print("=== END DROPDOWN SELECTION ===");
        },
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Select Employee'),
          ),
          ...controller.employees.map((employee) {
            String employeeIdStr = employee.id.toString();
            String displayName = controller.getEmployeeDisplayName(employee);

            return DropdownMenuItem<String>(
              value: employeeIdStr,
              child: Text(displayName),
            );
          }).toList(),
        ],
        decoration: InputDecoration(
          labelText: 'Employee (${controller.employees.length} available)',
          prefixIcon: const Icon(Icons.person, color: kPrimaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(color: kSecondaryColor),
          ),
          labelStyle: const TextStyle(color: kSecondaryColor),
        ),
        isExpanded: true,
        validator: (value) {
          if (controller.selectedEmployee.value == null) {
            return 'Please select an employee';
          }
          return null;
        },
      );
    });
  }

  Widget _buildEffectiveFromDateField(AddWageController controller) {
    return TextField(
      controller: controller.effectiveFromController,
      readOnly: true,
      onTap: () => controller.selectEffectiveFromDate(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.date_range, color: kPrimaryColor),
        labelText: 'Effective From Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildEffectiveToDateField(AddWageController controller) {
    return TextField(
      controller: controller.effectiveToController,
      readOnly: true,
      onTap: () => controller.selectEffectiveToDate(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.event, color: kPrimaryColor),
        labelText: 'Effective To Date (Optional)',
        suffixIcon: Obx(() => controller.effectiveToDate.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: kSecondaryColor),
                onPressed: () => controller.clearEffectiveToDate(),
              )
            : const SizedBox.shrink()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildPreviewCard(AddWageController controller) {
    return Obx(() => Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.preview, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Wage Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                _buildPreviewRow(
                  'Employee:',
                  controller.selectedEmployee.value?.name ?? 'Not selected',
                  controller.isEmployeeValid,
                ),
                const SizedBox(height: 8),
                _buildPreviewRow(
                  'Amount:',
                  controller.formattedAmountPreview,
                  controller.isAmountValid,
                ),
                const SizedBox(height: 8),
                _buildPreviewRow(
                  'Date Range:',
                  controller.dateRangePreview,
                  controller.isEffectiveFromValid,
                ),
                const SizedBox(height: 8),
                _buildPreviewRow(
                  'Remarks:',
                  controller.remarksController.text.isEmpty
                      ? 'None'
                      : controller.remarksController.text,
                  true, // Remarks are optional, so always valid
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      controller.isFormValid ? Icons.check_circle : Icons.error,
                      color: controller.isFormValid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isFormValid
                          ? 'Form is ready to submit'
                          : 'Please complete all required fields',
                      style: TextStyle(
                        color:
                            controller.isFormValid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildPreviewRow(String label, String value, bool isValid) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: kSecondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isValid ? Colors.black87 : Colors.red,
                    fontWeight: isValid ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                isValid ? Icons.check : Icons.close,
                color: isValid ? Colors.green : Colors.red,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
