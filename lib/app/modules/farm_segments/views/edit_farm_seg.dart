import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_farm_seg_controller.dart';

class FarmSegmentEditScreen extends StatelessWidget {
  const FarmSegmentEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FarmSegmentEditController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Edit Farm Segment',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewFarmSegments(),
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
                  'Loading farm segment data...',
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
                  // Farm Name Field
                  _buildTextField(
                    'Farm Name',
                    controller.farmNameController,
                    Icons.agriculture,
                  ),
                  const SizedBox(height: 30.0),

                  // Save/Update Button
                  Obx(() => CustomElevatedButton(
                        text: controller.isSaving.value
                            ? (controller.isEditMode.value ? 'Updating...' : 'Saving...')
                            : (controller.isEditMode.value ? 'Update Farm Segment' : 'Add Farm Segment'),
                        onPressed: controller.isSaving.value
                            ? () {}
                            : () => controller.saveFarmSegment(),
                        backgroundColor: kPrimaryColor,
                        textColor: kLightColor,
                      )),

                  const SizedBox(height: 20.0),

                  
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

  Widget _buildTextField(
    String label,
    TextEditingController textController,
    IconData icon, {
    Color iconColor = kPrimaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: textController,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor),
            labelText: 'Enter $label',
            hintText: 'e.g., North Farm Field',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            if (value.trim().length < 2) {
              return '$label must be at least 2 characters';
            }
            if (value.length > 255) {
              return '$label must be less than 255 characters';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
          maxLength: 255,
          buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '$currentLength/${maxLength ?? 255}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}