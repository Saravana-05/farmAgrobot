import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_crop_variant_controller.dart';

class CropVariantEditScreen extends StatelessWidget {
  const CropVariantEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CropVariantEditController());

    return Scaffold(
      appBar: MenuAppBar(
        title: controller.isEditMode.value
            ? 'Edit Crop Variant'
            : 'Add Crop Variant',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewCropVariants(),
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
                  'Loading data...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Crop Selection Dropdown Field
                  _buildCropSelectionField(controller),
                  const SizedBox(height: 20.0),

                  // Crop Variant Name Field
                  _buildTextField(
                    'Crop Variant Name',
                    controller.cropVariantController,
                    Icons.grass,
                  ),
                  const SizedBox(height: 20.0),

                  // Unit Selection Dropdown
                  _buildUnitDropdown(controller),
                  const SizedBox(height: 30.0),

                  // Save/Update Button
                  Obx(() => CustomElevatedButton(
                        text: controller.isSaving.value
                            ? (controller.isEditMode.value
                                ? 'Updating...'
                                : 'Saving...')
                            : (controller.isEditMode.value
                                ? 'Update Crop Variant'
                                : 'Save Crop Variant'),
                        onPressed: controller.isSaving.value
                            ? null
                            : () => controller.saveCropVariant(),
                        backgroundColor: kPrimaryColor,
                        textColor: kLightColor,
                      )),

                  // Add refresh button for debugging
                  const SizedBox(height: 16.0),
                  OutlinedButton.icon(
                    onPressed: controller.refreshCrops,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Crops'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
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

  Widget _buildCropSelectionField(CropVariantEditController controller) {
    return Obx(() {
      // Show loading state while crops are being fetched
      if (controller.isLoadingCrops.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: kSecondaryColor),
            borderRadius: BorderRadius.circular(50.0),
          ),
          child: const Row(
            children: [
              Icon(Icons.agriculture, color: kPrimaryColor),
              SizedBox(width: 16),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading crops...'),
            ],
          ),
        );
      }

      // Show error state if no crops are available
      if (controller.availableCrops.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(50.0),
            color: Colors.orange.shade50,
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('No crops available. Please add crops first.'),
              ),
              TextButton(
                onPressed: controller.refreshCrops,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      // Actual dropdown field
      return DropdownButtonFormField<String>(
        value: controller.selectedCropId.value.isEmpty
            ? null
            : controller.selectedCropId.value,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.agriculture, color: kPrimaryColor),
          labelText: 'Select Crop',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(color: kSecondaryColor),
          ),
          labelStyle: const TextStyle(color: kSecondaryColor),
          // Add enabled state styling
          filled: controller.isEditMode.value,
          fillColor: controller.isEditMode.value
              ? Colors.grey.shade100
              : Colors.transparent,
        ),
        items: controller.availableCrops.map<DropdownMenuItem<String>>((crop) {
          return DropdownMenuItem<String>(
            value: crop['id'],
            child: Text(
              crop['name'],
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            final selectedCrop = controller.availableCrops.firstWhere(
              (crop) => crop['id'] == newValue,
            );
            controller.selectCrop(newValue, selectedCrop['name']);
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a crop';
          }
          return null;
        },
        hint: const Text('Choose a crop'),
        disabledHint: controller.isEditMode.value && controller.hasCropSelected
            ? Text(
                controller.selectedCropName.value,
                style: const TextStyle(color: Colors.black54),
              )
            : const Text('Select crop'),
      );
    });
  }

  Widget _buildTextField(
    String label,
    TextEditingController textController,
    IconData icon, {
    Color iconColor = kPrimaryColor,
  }) {
    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Crop variant name is required';
        }
        if (value.length > 100) {
          return 'Crop variant name must be less than 100 characters';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
      maxLength: 100,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/${maxLength ?? 100}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  Widget _buildUnitDropdown(CropVariantEditController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedUnit.value.isEmpty
              ? null
              : controller.selectedUnit.value,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.straighten, color: kPrimaryColor),
            labelText: 'Unit',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
          items: controller.availableUnits.map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(unit),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.selectUnit(newValue);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a unit';
            }
            return null;
          },
          hint: const Text('Select Unit'),
        ));
  }
}
