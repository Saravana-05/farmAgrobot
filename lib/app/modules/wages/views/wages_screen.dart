import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/wages_controller.dart' as wages_controller;
import 'view_wages.dart';


class WagesScreen extends GetView<wages_controller.WagesController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        // isCustomScreen: false,
        title: 'Wages',
        showAddIcon: true,
        onAddPressed: () {
          controller.navigateToAddWages();
        },
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [ViewWages()],
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
