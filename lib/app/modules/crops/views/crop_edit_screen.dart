import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/crop_edit_controller.dart';

class CropEditScreen extends StatelessWidget {
  const CropEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CropEditController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Edit Crop',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewCrops(),
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
                  'Loading crop data...',
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
                  // Crop Name Field
                  _buildTextField(
                    'Crop Name',
                    controller.cropNameController,
                    Icons.agriculture,
                  ),
                  const SizedBox(height: 20.0),

                  // Image Picker Section
                  _buildImagePicker(controller),
                  const SizedBox(height: 20.0),

                  // Update Button
                  Obx(() => CustomElevatedButton(
                        text: controller.isSaving.value
                            ? 'Updating...'
                            : 'Update Crop',
                        onPressed: controller.isSaving.value
                            ? () {}
                            : () => controller.saveCrop(),
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
          return 'Crop name is required';
        }
        if (value.length > 255) {
          return 'Crop name must be less than 255 characters';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
      maxLength: 255,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/${maxLength ?? 255}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  Widget _buildImagePicker(CropEditController controller) {
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
                          : () => controller.showImagePickerOptions(),
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundImage: _getImageProvider(controller),
                        child: _getImageProvider(controller) == null
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
                      labelText: 'Update Crop Image',
                      hintText: controller.isUploading.value
                          ? 'Processing...'
                          : _hasImage(controller)
                              ? 'Image selected'
                              : 'Choose a crop image',
                      prefixIcon: const Icon(Icons.image),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      filled: true,
                      fillColor: _hasImage(controller)
                          ? Colors.green.withOpacity(0.1)
                          : kLightGreen,
                    ),
                    readOnly: true,
                    onTap: controller.isUploading.value
                        ? null
                        : () => controller.showImagePickerOptions(),
                  )),
            ),
          ],
        ),

        // Remove existing image checkbox
        Obx(() {
          if (controller.currentCrop.value?.hasImage == true &&
              controller.selectedImageFile.value == null) {
            return Column(
              children: [
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: controller.removeExistingImage.value,
                  onChanged: (value) => controller.toggleRemoveExistingImage(),
                  title: const Text(
                    'Remove existing image',
                    style: TextStyle(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),

        // Remove selected image option
        if (_hasNewImage(controller)) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => controller.removeSelectedImage(),
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text(
                  'Remove Selected Image',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ImageProvider? _getImageProvider(CropEditController controller) {
    // If a new image is selected, show it
    if (controller.selectedImageFile.value != null) {
      // Assuming you have a method to get bytes from the selected file
      // You might need to adjust this based on your controller implementation
      return FileImage(controller.selectedImageFile.value!);
    }

    // If existing image should be removed, show placeholder
    if (controller.removeExistingImage.value) {
      return null;
    }

    // If there's an existing image, show it
    if (controller.currentCrop.value?.hasImage == true) {
      // You might need to adjust this based on how you store/retrieve existing images
      return NetworkImage(controller.currentCrop.value!.imageUrl!);
    }

    // Default placeholder
    return const AssetImage('assets/images/crop_placeholder.jpg');
  }

  bool _hasImage(CropEditController controller) {
    return controller.selectedImageFile.value != null ||
        (controller.currentCrop.value?.hasImage == true &&
            !controller.removeExistingImage.value);
  }

  bool _hasNewImage(CropEditController controller) {
    return controller.selectedImageFile.value != null;
  }
}
