import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/crop_variant/crop_variant_model.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../data/models/yield/yield_model.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_yield_controller.dart';

class YieldEditScreen extends StatelessWidget {
  const YieldEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditYieldController());

    return Scaffold(
      appBar: MenuAppBar(
        title: controller.isEditMode.value ? 'Edit Yield' : 'Add Yield',
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading yield data...',
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
                  // Crop Selection Dropdown
                  _buildCropDropdown(controller),
                  const SizedBox(height: 20.0),

                  // Harvest Date Field
                  _buildDateField(controller),
                  const SizedBox(height: 20.0),

                  // Farm Segments Selection
                  _buildFarmSegmentsSection(controller),
                  const SizedBox(height: 20.0),

                  // Yield Variants Section
                  _buildVariantsSection(controller),
                  const SizedBox(height: 20.0),

                  // Bill Images Section
                  _buildBillImagesSection(controller),
                  const SizedBox(height: 20.0),

                  // Notes Field
                  _buildTextField(
                    'Notes (Optional)',
                    controller.notesController,
                    Icons.notes,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 30.0),

                  // Save Button
                  Obx(() => CustomElevatedButton(
                        text: controller.isSaving.value
                            ? (controller.isEditMode.value
                                ? 'Updating...'
                                : 'Saving...')
                            : (controller.isEditMode.value
                                ? 'Update Yield'
                                : 'Save Yield'),
                        onPressed: controller.isSaving.value
                            ? () {}
                            : () => controller.saveYield(),
                        backgroundColor: kPrimaryColor,
                        textColor: kLightColor,
                      )),
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
    String? Function(String?)? validator,
    Color iconColor = kPrimaryColor,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        counterStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      validator: validator,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      buildCounter: maxLength != null
          ? (context, {required currentLength, required isFocused, maxLength}) {
              return Text(
                '$currentLength/${maxLength ?? 500}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              );
            }
          : null,
    );
  }

  Widget _buildCropDropdown(EditYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crop *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                border: Border.all(color: kSecondaryColor),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: DropdownButtonFormField<String>(
                value: controller.selectedCrop.value!.isNotEmpty
                    ? controller.selectedCrop.value
                    : null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.grass, color: kPrimaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: controller.availableCrops
                    .map((Crop crop) => DropdownMenuItem<String>(
                          value: crop.id.toString(),
                          child: Row(
                            children: [
                              const Icon(Icons.eco,
                                  size: 20, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(crop.cropName ?? ''),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  controller.updateCrop(value); // This will now filter variants
                },
                validator: controller.validateCrop,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                hint: const Text('Select Crop'),
              ),
            )),
        const SizedBox(height: 8),
        Obx(() => controller.selectedCropName.value.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected: ${controller.selectedCropName.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  // Show available variants count
                  if (controller.filteredVariants.isNotEmpty)
                    Text(
                      '${controller.filteredVariants.length} variant(s) available',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              )
            : const SizedBox()),
      ],
    );
  }

  Widget _buildDateField(EditYieldController controller) {
    return _buildTextField(
      'Harvest Date *',
      controller.harvestDateController,
      Icons.calendar_today,
      readOnly: true,
      onTap: controller.selectHarvestDate,
      validator: controller.validateHarvestDate,
    );
  }

  Widget _buildFarmSegmentsSection(EditYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Segments *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kSecondaryColor),
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.terrain, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select Farm Segments',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showFarmSegmentSelector(controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Select',
                      style: TextStyle(color: kLightColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.farmSegmentNames.isEmpty) {
                  return Text(
                    'No farm segments selected',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                return Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: controller.farmSegmentNames.map((name) {
                    return Chip(
                      label: Text(name),
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        int index = controller.farmSegmentNames.indexOf(name);
                        if (index >= 0) {
                          controller.selectedFarmSegments.removeAt(index);
                          controller.farmSegmentNames.removeAt(index);
                        }
                      },
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsSection(EditYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Yield Variants *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kSecondaryColor,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: controller.addNewVariant,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: kLightColor, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Add Variant',
                    style: TextStyle(color: kLightColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() => Column(
              children: controller.yieldVariants.asMap().entries.map((entry) {
                int index = entry.key;
                var variant = entry.value;
                return _buildVariantCard(controller, index, variant);
              }).toList(),
            )),
        const SizedBox(height: 8),
        Obx(() => Text(
              'Total Quantity: ${controller.totalQuantity.toStringAsFixed(2)} kg',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
            )),
      ],
    );
  }

  Widget _buildVariantCard(
      EditYieldController controller, int index, YieldVariant variant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Variant ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (controller.yieldVariants.length > 1)
                  IconButton(
                    onPressed: () => controller.removeVariant(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Crop Variant Dropdown - UPDATED TO USE FILTERED VARIANTS
            Obx(() => DropdownButtonFormField<String>(
                  value: variant.cropVariantId.isNotEmpty
                      ? variant.cropVariantId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Crop Variant',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: controller
                      .filteredVariants // CHANGED FROM availableVariants to filteredVariants
                      .map((CropVariant v) => DropdownMenuItem<String>(
                            value: v.id,
                            child: Text(v.cropVariant),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final variantInfo = controller
                          .filteredVariants // CHANGED FROM availableVariants
                          .firstWhere((v) => v.id == value);
                      controller.updateVariant(
                        index,
                        variant.copyWith(
                          cropVariantId: value,
                          cropVariantName: variantInfo.cropVariant,
                          unit: variantInfo.unit, // Auto-populate unit
                        ),
                      );
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select crop variant' : null,
                )),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: variant.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      double quantity = double.tryParse(value) ?? 0.0;
                      controller.updateVariant(
                        index,
                        variant.copyWith(quantity: quantity),
                      );
                    },
                    validator: (value) {
                      double? quantity = double.tryParse(value ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => TextFormField(
                        initialValue: controller.yieldVariants[index].unit,
                        readOnly: true, // MAKE UNIT READ-ONLY
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Color(
                              0xFFF5F5F5), // Light gray to show it's read-only
                        ),
                        style: TextStyle(
                          color: Colors.grey[600], // Slightly muted text color
                        ),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillImagesSection(EditYieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bill Images (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kSecondaryColor,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: controller.pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate, color: kLightColor, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Add Images',
                    style: TextStyle(color: kLightColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Existing Images (for edit mode)
        Obx(() {
          if (controller.existingBillUrls.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Existing Images:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.existingBillUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = controller.existingBillUrls[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    controller.removeExistingImage(imageUrl),
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }
          return const SizedBox();
        }),

        // New Images
        Obx(() {
          if (controller.billImages.isEmpty) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey[300]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No images selected',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Images:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
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
                              image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
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
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 8),
        Obx(() {
          int totalImages =
              controller.billImages.length + controller.existingBillUrls.length;
          return Text(
            'Images: $totalImages/10',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          );
        }),
      ],
    );
  }

  void _showFarmSegmentSelector(EditYieldController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Farm Segments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.availableFarmSegments.length,
                itemBuilder: (context, index) {
                  final segment = controller.availableFarmSegments[index];
                  final segmentId = segment.id;
                  final segmentName = segment.displayName;

                  return Obx(() => CheckboxListTile(
                        title: Text(segmentName),
                        value:
                            controller.selectedFarmSegments.contains(segmentId),
                        onChanged: (bool? value) {
                          if (value == true) {
                            if (!controller.selectedFarmSegments
                                .contains(segmentId)) {
                              controller.selectedFarmSegments.add(segmentId);
                              controller.farmSegmentNames.add(segmentName);
                            }
                          } else {
                            controller.selectedFarmSegments.remove(segmentId);
                            controller.farmSegmentNames.remove(segmentName);
                          }
                        },
                        activeColor: kPrimaryColor,
                      ));
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Done (${controller.selectedFarmSegments.length} selected)',
                    style: const TextStyle(color: kLightColor, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
