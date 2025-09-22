import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/sales_controller.dart';
import 'view_sales.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        title: 'Sales',
        showAddIcon: true,
        onAddPressed: controller.navigateToAddSales,
      ),
      endDrawer: const MyDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            ViewSales(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        // Make sure to access the observable within the Obx builder
        final currentIndex = controller.selectedIndex.value;
        return MyBottomNavigation(
          selectedIndex: currentIndex,
          onTabSelected: controller.onTabSelected,
        );
      }),
    );
  }
}