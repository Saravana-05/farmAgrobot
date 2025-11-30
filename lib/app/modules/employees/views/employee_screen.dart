import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/employee_controller.dart' as emploee_controller;
import 'employee_view.dart';

class EmployeeScreen extends GetView<emploee_controller.EmployeeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        // isCustomScreen: false,
        title: 'Employees',
        showAddIcon: true,
        onAddPressed: () {
          controller.navigateToEmployee();
        },
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [ViewEmployees()],
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
