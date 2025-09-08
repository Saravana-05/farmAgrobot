import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../../crops/views/crop_view.dart';
import '../controller/merchant_controller.dart' as merchant_controller;
import 'view_merchant.dart';



class MerchantScreen extends GetView<merchant_controller.MerchantController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        // isCustomScreen: false,
        title: 'Merchants',
        showAddIcon: true,
        onAddPressed: () {
          controller.navigateToAddMerchant();
        },
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [ViewMerchants()],
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
