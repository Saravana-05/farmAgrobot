import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_crop_variant_controller.dart';

class AddCropVariant extends StatelessWidget {
  const AddCropVariant({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddCropVariantController());

    return WillPopScope(
      onWillPop: () async {
        controller.handleBackNavigation();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: MenuAppBar(
          title: 'Add Crop Variant',
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCropDropdown(controller),
                const SizedBox(height: 20.0),
                _buildTextField(
                  'Crop Variant Name',
                  controller.cropVariantController,
                  Icons.grass,
                  hintText: 'e.g., Green Bell Pepper, Red Tomato',
                ),
                const SizedBox(height: 20.0),
                _buildUnitDropdown(controller),
                const SizedBox(height: 30.0),
                Obx(() => CustomElevatedButton(
                      text: controller.isSaving.value
                          ? 'Saving...'
                          : 'Add Crop Variant',
                      onPressed: controller.isSaving.value
                          ? () {}
                          : () => controller.saveCropVariant(),
                      backgroundColor: kPrimaryColor,
                      textColor: kLightColor,
                    )),
                const SizedBox(height: 20.0),
                _buildHelpCard(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Obx(() => MyBottomNavigation(
              selectedIndex: controller.selectedIndex.value,
              onTabSelected: controller.navigateToTab,
            )),
      ),
    );
  }

  Widget _buildCropDropdown(AddCropVariantController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Crop *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8.0),
        Obx(() => controller.isLoadingCrops.value
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.0),
                  border: Border.all(color: kSecondaryColor),
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
                      Text('Loading crops...'),
                    ],
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.0),
                  border: Border.all(color: kSecondaryColor),
                ),
                child: DropdownButtonFormField<Crop>(
                  value: controller.selectedCrop.value,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.agriculture, color: kPrimaryColor),
                    hintText: 'Choose a crop',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                  items: controller.crops.map((Crop crop) {
                    return DropdownMenuItem<Crop>(
                      value: crop,
                      child: Text(
                        crop.cropName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: controller.onCropSelected,
                  dropdownColor: Colors.white,
                  isExpanded: true,
                ),
              )),
        const SizedBox(height: 8.0),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => controller.refreshCrops(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Crops'),
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumeric = false,
    bool isMultiline = false,
    Color iconColor = kPrimaryColor,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          keyboardType: isNumeric
              ? TextInputType.number
              : (isMultiline ? TextInputType.multiline : TextInputType.text),
          maxLines: isMultiline ? null : 1,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor),
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown(AddCropVariantController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8.0),
        Obx(() => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                border: Border.all(color: kSecondaryColor),
              ),
              child: DropdownButtonFormField<String>(
                value: controller.selectedUnit.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.straighten, color: kPrimaryColor),
                  hintText: 'Choose a unit',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                items: controller.availableUnits.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Row(
                      children: [
                        _getUnitIcon(unit),
                        const SizedBox(width: 8),
                        Text(controller.getUnitDisplayName(unit)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: controller.onUnitSelected,
                dropdownColor: Colors.white,
                isExpanded: true,
              ),
            )),
        const SizedBox(height: 8.0),
        Text(
          'Choose the appropriate unit for measuring this crop variant',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _getUnitIcon(String unit) {
    switch (unit) {
      case 'Pieces':
        return const Icon(Icons.looks_one, size: 16, color: kPrimaryColor);
      case 'Bunch':
        return const Icon(Icons.grass, size: 16, color: kPrimaryColor);
      case 'Pack':
        return const Icon(Icons.inventory, size: 16, color: kPrimaryColor);
      default:
        return const Icon(Icons.straighten, size: 16, color: kPrimaryColor);
    }
  }

  Widget _buildHelpCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'About Crop Variants',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Crop variants help you categorize different types or varieties of the same crop. For example:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildExampleRow('🌶️', 'Pepper', 'Green Bell, Red Bell, Jalapeño'),
            _buildExampleRow('🍅', 'Tomato', 'Cherry, Roma, Beefsteak'),
            _buildExampleRow('🥬', 'Lettuce', 'Iceberg, Romaine, Butterhead'),
            const SizedBox(height: 12),
            const Text(
              'Units help specify how the crop variant is typically sold or measured.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleRow(String emoji, String crop, String variants) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$crop: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: variants),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}