import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        title: 'Settings',
        // isCustomScreen: false,
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Crops'),
            onTap: () => controller.navigateToPage('/crops'),
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Crops Variants'),
            onTap: () => controller.navigateToPage('/crop_variants'),
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Expense Category'),
            onTap: () => controller.navigateToPage('/category'),
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Employee Analytics'),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () => controller.navigateToYieldAnalytics(),
          ),
          ListTile(
            leading: Icon(Icons.crop),
            title: Text('Yield Analytics'),
            onTap: () => controller.navigateToYieldAnalytics(),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: (index) => controller.onTabSelected(index),
          )),
    );
  }
}
