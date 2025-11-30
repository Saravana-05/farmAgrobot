import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_crop_controller.dart';

class AddCrops extends StatelessWidget {
  const AddCrops({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddCropsController());

    return WillPopScope(
      onWillPop: () async {
        controller.handleBackNavigation();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: MenuAppBar(
          title: 'Add Crops',
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  'Crop Name',
                  controller.cropNameController,
                  Icons.agriculture,
                ),
                const SizedBox(height: 20.0),
                _buildImagePicker(controller),
                const SizedBox(height: 30.0),
                Obx(() => CustomElevatedButton(
                      text:
                          controller.isSaving.value ? 'Saving...' : 'Add Crop',
                      onPressed: controller.isSaving.value
                          ? () {}
                          : () => controller.saveCrop(),
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
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumeric = false,
    bool isMultiline = false,
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
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildImagePicker(AddCropsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview Section
        Obx(() => controller.image.value != null
            ? Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: kSecondaryColor, width: 2),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13.0),
                      child: Image.memory(
                        controller.image.value!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Remove image button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => controller.removeImage(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
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
              )
            : Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: kSecondaryColor, width: 2),
                  color: Colors.grey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No image selected',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 20.0),

        // Image Selection Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Stack(
                  children: [
                    GestureDetector(
                      onTap: () => controller.selectImage(),
                      child: CircleAvatar(
                        radius: 40.0,
                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                        child: controller.image.value != null
                            ? ClipOval(
                                child: Image.memory(
                                  controller.image.value!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.add_a_photo,
                                size: 30,
                                color: kPrimaryColor,
                              ),
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
                      labelText: 'Upload Crop Image',
                      hintText: controller.isUploading.value
                          ? 'Processing...'
                          : controller.image.value != null
                              ? 'Image selected'
                              : 'Choose a crop image',
                      prefixIcon: const Icon(
                        Icons.photo_camera,
                        color: kPrimaryColor,
                      ),
                      suffixIcon: controller.image.value != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.red,
                              ),
                              onPressed: () => controller.removeImage(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: const BorderSide(color: kSecondaryColor),
                      ),
                      labelStyle: const TextStyle(color: kSecondaryColor),
                      filled: true,
                      fillColor: controller.image.value != null
                          ? kLightGreen.withOpacity(0.3)
                          : kLightGreen,
                    ),
                    readOnly: true,
                    onTap: controller.isUploading.value
                        ? null
                        : () => controller.selectImage(),
                  )),
            ),
          ],
        ),

        // Helper text
        const SizedBox(height: 10.0),
        Text(
          'Tap to select an image from camera or gallery',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),

        // Image format info
        const SizedBox(height: 5.0),
        Text(
          'Supported formats: JPG, JPEG, PNG, GIF, WEBP (Max: 10MB)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
