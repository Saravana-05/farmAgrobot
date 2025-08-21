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
              _buildEmployeeMultiselect(context,controller), // CHANGED: From _buildEmployeeDropdown
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

  // UPDATED: Preview card for multiselect
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
                  'Employees:',
                  controller.employeePreview, // CHANGED: Now uses employeePreview
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

  // NEW: Multiselect employee widget
  Widget _buildEmployeeMultiselect(BuildContext context,AddWageController controller) {
    return Obx(() {
      print("=== MULTISELECT REBUILD ===");
      print("isLoadingEmployees: ${controller.isLoadingEmployees.value}");
      print("employees.length: ${controller.employees.length}");
      print("selectedEmployees: ${controller.selectedEmployees.map((e) => e.name).toList()}");
      print("selectedEmployees count: ${controller.selectedEmployees.length}");

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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main multiselect container
          GestureDetector(
            onTap: () => _showEmployeeMultiselectDialog(context, controller),
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: kSecondaryColor),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: controller.selectedEmployees.isEmpty
                        ? Text(
                            'Select Employees (${controller.employees.length} available)',
                            style: const TextStyle(
                              color: kSecondaryColor,
                              fontSize: 16,
                            ),
                          )
                        : _buildSelectedEmployeesDisplay(controller),
                  ),
                  const Icon(Icons.arrow_drop_down, color: kSecondaryColor),
                ],
              ),
            ),
          ),
          // Selected employees chips (optional, for better visibility)
          if (controller.selectedEmployees.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: controller.selectedEmployees.map((employee) {
                return Chip(
                  label: Text(
                    controller.getEmployeeDisplayName(employee),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () => controller.removeSelectedEmployee(employee),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  deleteIconColor: kSecondaryColor,
                );
              }).toList(),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSelectedEmployeesDisplay(AddWageController controller) {
    if (controller.selectedEmployees.length == 1) {
      return Text(
        controller.getEmployeeDisplayName(controller.selectedEmployees.first),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      );
    } else {
      return Text(
        '${controller.selectedEmployees.length} employees selected',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      );
    }
  }

  void _showEmployeeMultiselectDialog(BuildContext context, AddWageController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.people, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  const Text('Select Employees'),
                  const Spacer(),
                  Text(
                    '${controller.selectedEmployees.length}/${controller.employees.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: kSecondaryColor,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Select All / Deselect All buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              controller.selectAllEmployees();
                              setState(() {});
                            },
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Select All'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              controller.clearAllSelectedEmployees();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear All'),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Employee list
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.employees.length,
                        itemBuilder: (context, index) {
                          final employee = controller.employees[index];
                          final isSelected = controller.isEmployeeSelected(employee);
                          
                          return CheckboxListTile(
                            title: Text(controller.getEmployeeDisplayName(employee)),
                            subtitle: Text('ID: ${employee.id}'),
                            value: isSelected,
                            onChanged: (bool? selected) {
                              if (selected == true) {
                                controller.addSelectedEmployee(employee);
                              } else {
                                controller.removeSelectedEmployee(employee);
                              }
                              setState(() {});
                            },
                            activeColor: kPrimaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                  ),
                  child: Text(
                    'Done (${controller.selectedEmployees.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
