import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_farm_seg_controller.dart';

class AddFarmSegments extends StatelessWidget {
  const AddFarmSegments({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddFarmSegmentController());

    return WillPopScope(
      onWillPop: () async {
        controller.handleBackNavigation();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: MenuAppBar(
          title: 'Add Farm Segment',
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Farm Segment Information Section
                _buildSectionHeader('Farm Segment Information'),
                const SizedBox(height: 20.0),
                
                _buildTextField(
                  'Farm Name',
                  controller.farmNameController,
                  Icons.landscape,
                  hintText: 'Enter the name of your farm segment',
                ),
                
                const SizedBox(height: 20.0),
                
                // Information Card
                _buildInfoCard(),
                
                const SizedBox(height: 30.0),
                
                // Save Button
                Obx(() => CustomElevatedButton(
                      text: controller.isSaving.value 
                          ? 'Saving Farm Segment...' 
                          : 'Add Farm Segment',
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
        bottomNavigationBar: Obx(() => MyBottomNavigation(
              selectedIndex: controller.selectedIndex.value,
              onTabSelected: controller.navigateToTab,
            )),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.agriculture,
            color: kPrimaryColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumeric = false,
    bool isMultiline = false,
    String? hintText,
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
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: kSecondaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
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
                Icon(
                  Icons.info_outline,
                  color: kPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Farm Segment Guidelines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildInfoItem(
              Icons.check_circle_outline,
              'Farm name should be descriptive and unique',
            ),
            _buildInfoItem(
              Icons.check_circle_outline,
              'Maximum 255 characters allowed for farm name',
            ),
            _buildInfoItem(
              Icons.check_circle_outline,
              'Use clear naming convention (e.g., "North Field", "Greenhouse A")',
            ),
            _buildInfoItem(
              Icons.check_circle_outline,
              'This will help organize your farming operations',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}