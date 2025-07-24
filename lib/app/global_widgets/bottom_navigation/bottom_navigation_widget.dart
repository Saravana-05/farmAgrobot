import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import 'controller/bottom_navigation_controller.dart';



class MyBottomNavigation extends StatelessWidget {
  final NavigationController controller = Get.find<NavigationController>();

  MyBottomNavigation({super.key, required int selectedIndex, required void Function(int index) onTabSelected});

  @override
  Widget build(BuildContext context) {
    final NavigationController controller = Get.put(NavigationController());
    return Obx(() => CurvedNavigationBar(
      index: controller.selectedIndex.value,
      backgroundColor: kLightColor,
      color: kPrimaryColor,
      onTap: (index) {
        controller.changeTabIndex(index);
      },
      items: [
        CurvedNavigationBarItem(
          child: Icon(Icons.home,
              color: controller.selectedIndex.value == 0 ? Colors.yellow : kLightColor),
          label: 'Home',
          labelStyle: TextStyle(
              color: controller.selectedIndex.value == 0 ? Colors.yellow : kLightYellow),
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.dashboard,
              color: controller.selectedIndex.value == 1 ? Colors.yellow : kLightColor),
          label: 'Dashboard',
          labelStyle: TextStyle(
              color: controller.selectedIndex.value == 1 ? Colors.yellow : kLightYellow),
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.settings,
              color: controller.selectedIndex.value == 2 ? Colors.yellow : kLightColor),
          label: 'Settings',
          labelStyle: TextStyle(
              color: controller.selectedIndex.value == 2 ? Colors.yellow : kLightYellow),
        ),
      ],
    ));
  }
}