import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_yield_controller.dart';

class AddYield extends StatelessWidget {
  const AddYield({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddYieldController());

    return WillPopScope(
      onWillPop: () async {
        controller.handleBackNavigation();
        return false;
      },
      child: Scaffold(
        appBar: MenuAppBar(
          title: 'Add Yield',
          showAddIcon: true,
          addIcon: const Icon(
            Icons.visibility,
            size: 25.0,
            color: kTertiaryColor,
          ),
          onAddPressed: () => controller.navigateToViewYields(),
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
                const SizedBox(height: 20),
                _buildDatePicker(controller),
                const SizedBox(height: 20),
                _buildFarmSegmentsSection(controller),
                const SizedBox(height: 20),
                _buildYieldVariantsSection(controller),
                const SizedBox(height: 20),
                _buildImageUploadSection(controller),
                const SizedBox(height: 20),
                _buildBillUrlsSection(controller),
                const SizedBox(height: 30),
                _buildSaveButton(controller),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(controller),
      ),
    );
  }

  /// -------------------------------
  /// Crop Dropdown
  /// -------------------------------
  Widget _buildCropDropdown(AddYieldController controller) {
    return Obx(() {
      return DropdownButtonFormField<String>(
        value: controller.selectedCropId.isEmpty
            ? null
            : controller.selectedCropId,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.agriculture, color: kPrimaryColor),
          labelText: 'Select Crop',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(color: kSecondaryColor),
          ),
          labelStyle: const TextStyle(color: kSecondaryColor),
        ),
        items: controller.crops
            .map((crop) => DropdownMenuItem<String>(
                  value: crop.id,
                  child: Text(crop.displayName),
                ))
            .toList(),
        onChanged: (value) => controller.selectCrop(value),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a crop';
          }
          return null;
        },
      );
    });
  }

  /// -------------------------------
  /// Harvest Date Picker
  /// -------------------------------
  Widget _buildDatePicker(AddYieldController controller) {
    return GestureDetector(
      onTap: () => controller.selectHarvestDate(),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller.harvestDateController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today, color: kPrimaryColor),
            labelText: 'Harvest Date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select harvest date';
            }
            return null;
          },
        ),
      ),
    );
  }

  /// -------------------------------
  /// Farm Segments
  /// -------------------------------
  Widget _buildFarmSegmentsSection(AddYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Segments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: kSecondaryColor),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Obx(() {
            if (controller.farmSegments.isEmpty) {
              return Column(
                children: [
                  const Text(
                    'No farm segments available',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => controller.loadFarmSegments(),
                    child: const Text('Reload Farm Segments'),
                  ),
                ],
              );
            }

            return Column(
              children: controller.farmSegments.map((segment) {
                return Obx(() => CheckboxListTile(
                      title: Text(segment.displayName),
                      value:
                          controller.selectedFarmSegments.contains(segment.id),
                      onChanged: (bool? value) {
                        controller.toggleFarmSegment(segment.id);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ));
              }).toList(),
            );
          }),
        ),
      ],
    );
  }

  /// -------------------------------
  /// Yield Variants
  /// -------------------------------
  Widget _buildYieldVariantsSection(AddYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Yield Variants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
            IconButton(
              onPressed: () => controller.addYieldVariant(),
              icon: const Icon(Icons.add, color: kPrimaryColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.yieldVariants.isEmpty) {
            return TextButton(
              onPressed: () => controller.addYieldVariant(),
              child: const Text('Add First Variant'),
            );
          }

          return Column(
            children: controller.yieldVariants.asMap().entries.map((entry) {
              int index = entry.key;
              var variant = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Variant ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: kSecondaryColor,
                              ),
                            ),
                          ),
                          if (controller.yieldVariants.length > 1)
                            IconButton(
                              onPressed: () =>
                                  controller.removeYieldVariant(index),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: variant.variantId.isEmpty
                            ? null
                            : variant.variantId,
                        decoration: InputDecoration(
                          labelText: 'Select Variant',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: controller.filteredVariants
                            .map((v) => DropdownMenuItem<String>(
                                  value: v.id,
                                  child: Text(v.cropVariant),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            controller.updateVariantId(index, value ?? ''),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: variant.quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) => controller
                                  .updateVariantQuantity(index, value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: variant.unitController,
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) =>
                                  controller.updateVariantUnit(index, value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// -------------------------------
  /// Image Upload Section (NEW)
  /// -------------------------------
  Widget _buildImageUploadSection(AddYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bill Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
            Obx(() => Text(
                  '${controller.billImages.length}/10',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                )),
          ],
        ),
        const SizedBox(height: 10),

        // Image upload buttons
        Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  return Obx(() => ElevatedButton.icon(
                        onPressed: controller.maxImagesReached
                            ? null
                            : () => _showImageSourceDialog(context, controller),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kLightColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ));
                },
              ),
            ),
            const SizedBox(width: 10),
            Obx(() => ElevatedButton.icon(
                  onPressed: controller.maxImagesReached
                      ? null
                      : () => controller.pickMultipleImages(),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: kLightColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 15),

        // Display selected images
        Obx(() {
          if (controller.billImages.isEmpty) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: kSecondaryColor, width: 2),
                color: Colors.grey[100],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No images selected',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add images using the buttons above',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.billImages.length,
              itemBuilder: (context, index) {
                final image = controller.billImages[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          width: 150,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => controller.removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      // Show compression status
                      if (controller.isCompressing)
                        Positioned(
                          bottom: 5,
                          left: 5,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Compressing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }),

        const SizedBox(height: 10),
        Text(
          'Maximum 10 images allowed. Images will be compressed automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  /// Show image source dialog
  void _showImageSourceDialog(
      BuildContext context, AddYieldController controller) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.pickMultipleImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// -------------------------------
  /// Bill URLs Section (Modified)
  /// -------------------------------
  Widget _buildBillUrlsSection(AddYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Additional Bill URLs (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
            Obx(() => Text(
                  '${controller.billUrls.length}/10',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                )),
          ],
        ),
        const SizedBox(height: 10),

        // URL Input Field
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.billUrlController,
                decoration: InputDecoration(
                  labelText: 'Enter Bill URL',
                  hintText: 'https://example.com/bill.pdf',
                  prefixIcon: const Icon(Icons.link, color: kPrimaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onFieldSubmitted: (_) => controller.addBillUrl(),
              ),
            ),
            const SizedBox(width: 10),
            Obx(() => ElevatedButton(
                  onPressed: controller.maxBillUrlsReached
                      ? null
                      : () => controller.addBillUrl(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kLightColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Icon(Icons.add),
                )),
          ],
        ),
        const SizedBox(height: 15),

        // Display Added URLs
        Obx(() {
          if (controller.billUrls.isEmpty) {
            return Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: kSecondaryColor, width: 2),
                color: Colors.grey[100],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_outlined, size: 30, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text(
                    'No additional URLs added',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.billUrls.length,
              itemBuilder: (context, index) {
                final url = controller.billUrls[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.link, color: kPrimaryColor),
                    title: Text(
                      controller.getFormattedBillUrl(url),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showEditUrlDialog(
                              context, controller, index, url),
                          icon: const Icon(Icons.edit, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: () => controller.removeBillUrl(index),
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  /// Show edit URL dialog
  void _showEditUrlDialog(BuildContext context, AddYieldController controller,
      int index, String currentUrl) {
    final editController = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Bill URL'),
          content: TextFormField(
            controller: editController,
            decoration: InputDecoration(
              labelText: 'Bill URL',
              hintText: 'https://example.com/bill.pdf',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newUrl = editController.text.trim();
                if (newUrl.isNotEmpty) {
                  controller.editBillUrl(index, newUrl);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kLightColor,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// -------------------------------
  /// Save Button
  /// -------------------------------
  Widget _buildSaveButton(AddYieldController controller) {
    return Obx(() {
      return CustomElevatedButton(
        text: controller.isSaving
            ? 'Saving...'
            : controller.isUploading
                ? 'Uploading Images...'
                : 'Add Yield',
        onPressed: (controller.isSaving || controller.isUploading)
            ? () {}
            : () => controller.saveYield(),
        backgroundColor: kPrimaryColor,
        textColor: kLightColor,
      );
    });
  }

  /// -------------------------------
  /// Bottom Navigation
  /// -------------------------------
  Widget _buildBottomNavigation(AddYieldController controller) {
    return Obx(() {
      return MyBottomNavigation(
        selectedIndex: controller.selectedIndex,
        onTabSelected: controller.navigateToTab,
      );
    });
  }
}
