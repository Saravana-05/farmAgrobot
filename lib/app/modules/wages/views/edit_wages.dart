import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_wage_controller.dart';

class EditWage extends StatelessWidget {
  const EditWage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditWageController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Edit Wage',
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
                // Original wage info card
                if (controller.originalWageInfo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Current Wage Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: kPrimaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.originalWageInfo,
                          style: const TextStyle(
                            color: kSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Employee Selection Dropdown
                _buildEmployeeDropdown(controller),
                const SizedBox(height: 20.0),

                // Amount Field with preview
                _buildAmountField(controller),
                const SizedBox(height: 20.0),

                // Effective From Date
                _buildEffectiveFromDateField(controller),
                const SizedBox(height: 20.0),

                // Effective To Date with clear option
                _buildEffectiveToDateField(controller),
                const SizedBox(height: 20.0),

                // Date Range Preview Card
                _buildDateRangePreview(controller),
                const SizedBox(height: 20.0),

                // Remarks Field
                _buildRemarksField(controller),
                const SizedBox(height: 30.0),

                // Update Button
                Obx(() => CustomElevatedButton(
                      text: controller.isSaving.value
                          ? 'Updating...'
                          : 'Update Wage',
                      onPressed: controller.isSaving.value || !controller.isFormValid
                          ? () {}
                          : () => controller.updateWage(),
                    )),
                const SizedBox(height: 20.0),

                // Cancel Button
                OutlinedButton(
                  onPressed: () => controller.navigateBack(),
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

                // Reset Form Button (only show if there are changes)
                Obx(() => controller.hasChanges
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: TextButton(
                          onPressed: () => controller.resetForm(),
                          child: const Text(
                            'Reset to Original',
                            style: TextStyle(
                              color: kTertiaryColor,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
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

  Widget _buildEmployeeDropdown(EditWageController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedEmployee.value?.id.toString(),
          onChanged: controller.isLoadingEmployees.value
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    controller.selectEmployeeById(newValue);
                  }
                },
          items: controller.employees.map((employee) {
            return DropdownMenuItem<String>(
              value: employee.id.toString(),
              child: Text(
                controller.getEmployeeDisplayName(employee),
                style: TextStyle(
                  color: employee.status ? Colors.black : Colors.grey,
                  fontWeight: controller.isEmployeeSelected(employee)
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Select Employee *',
            prefixIcon: controller.isLoadingEmployees.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: controller.isEmployeeValid ? kPrimaryColor : Colors.grey,
                  ),
            suffixIcon: controller.employees.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.refresh, color: kSecondaryColor),
                    onPressed: () => controller.refreshEmployees(),
                    tooltip: 'Refresh employees',
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide(
                color: controller.isEmployeeValid ? kSecondaryColor : Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide(
                color: controller.isEmployeeValid ? kPrimaryColor : Colors.red,
                width: 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide(
                color: controller.isEmployeeValid ? kSecondaryColor : Colors.red,
              ),
            ),
            labelStyle: TextStyle(
              color: controller.isEmployeeValid ? kSecondaryColor : Colors.red,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            errorText: controller.isEmployeeValid ? null : 'Please select an employee',
          ),
        ));
  }

  Widget _buildAmountField(EditWageController controller) {
    return Column(
      children: [
        TextField(
          controller: controller.amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => controller.formatAmountInput(),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.currency_rupee,
              color: controller.isAmountValid ? kPrimaryColor : Colors.grey,
            ),
            labelText: 'Amount *',
            hintText: 'Enter wage amount',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide(
                color: controller.isAmountValid ? kSecondaryColor : Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide(
                color: controller.isAmountValid ? kPrimaryColor : Colors.red,
                width: 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: BorderSide(
                color: controller.isAmountValid ? kSecondaryColor : Colors.red,
              ),
            ),
            labelStyle: TextStyle(
              color: controller.isAmountValid ? kSecondaryColor : Colors.red,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            errorText: controller.isAmountValid
                ? null
                : controller.validateAmount(controller.amountController.text),
          ),
        ),
        // Amount Preview
        Obx(() => controller.amountText.value.isNotEmpty
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: kLightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'Preview: ${controller.formattedAmountPreview}',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildEffectiveFromDateField(EditWageController controller) {
    return TextField(
      controller: controller.effectiveFromController,
      readOnly: true,
      onTap: () => controller.selectEffectiveFromDate(),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.date_range,
          color: controller.isEffectiveFromValid ? kPrimaryColor : Colors.grey,
        ),
        labelText: 'Effective From Date *',
        hintText: 'Select start date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(
            color: controller.isEffectiveFromValid ? kSecondaryColor : Colors.red,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(
            color: controller.isEffectiveFromValid ? kPrimaryColor : Colors.red,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(
            color: controller.isEffectiveFromValid ? kSecondaryColor : Colors.red,
          ),
        ),
        labelStyle: TextStyle(
          color: controller.isEffectiveFromValid ? kSecondaryColor : Colors.red,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        errorText: controller.isEffectiveFromValid ? null : 'Please select effective from date',
      ),
    );
  }

  Widget _buildEffectiveToDateField(EditWageController controller) {
    return TextField(
      controller: controller.effectiveToController,
      readOnly: true,
      onTap: () => controller.selectEffectiveToDate(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.event, color: kSecondaryColor),
        labelText: 'Effective To Date (Optional)',
        hintText: 'Select end date or leave empty for ongoing',
        suffixIcon: Obx(() => controller.effectiveToDate.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => controller.clearEffectiveToDate(),
                tooltip: 'Clear end date',
              )
            : const Icon(Icons.event_available, color: Colors.grey)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(
            color: controller.isDateRangeValid ? kSecondaryColor : Colors.red,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(
            color: controller.isDateRangeValid ? kPrimaryColor : Colors.red,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(
            color: controller.isDateRangeValid ? kSecondaryColor : Colors.red,
          ),
        ),
        labelStyle: TextStyle(
          color: controller.isDateRangeValid ? kSecondaryColor : Colors.red,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        errorText: controller.isDateRangeValid ? null : 'End date must be after start date',
      ),
    );
  }

  Widget _buildDateRangePreview(EditWageController controller) {
    return Obx(() => controller.effectiveFromDate.value.isNotEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: kPrimaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Wage Period',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  controller.dateRangePreview,
                  style: const TextStyle(
                    color: kSecondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  Widget _buildRemarksField(EditWageController controller) {
    return TextField(
      controller: controller.remarksController,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      maxLength: 255,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.note_alt, color: kSecondaryColor),
        labelText: 'Remarks (Optional)',
        hintText: 'Add any additional notes or comments...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        counterStyle: const TextStyle(color: kSecondaryColor, fontSize: 12),
      ),
    );
  }
}