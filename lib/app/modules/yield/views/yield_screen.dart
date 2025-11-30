import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/yield_controller.dart' as yield_controller;
import 'yield_view.dart';


class YieldScreen extends GetView<yield_controller.YieldController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        // isCustomScreen: false,
        title: 'Yield',
        showAddIcon: true,
        onAddPressed: () {
          controller.navigateToAddYield();
        },
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [ViewYields()],
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
