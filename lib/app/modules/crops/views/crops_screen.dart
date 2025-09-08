import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/crop_controller.dart' as crop_controller;
import 'crop_view.dart';



class CropScreen extends GetView<crop_controller.CropController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        // isCustomScreen: false,
        title: 'Crops',
        showAddIcon: true,
        onAddPressed: () {
          controller.navigateToAddCrops();
        },
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [ViewCrops()],
        ),
      ),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: (index) {
              controller.onTabSelected(index);
            },
          )),
    );
  }
}
