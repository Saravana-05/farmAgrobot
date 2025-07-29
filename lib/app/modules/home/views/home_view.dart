import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/app_bar.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/card_grid/views/card_view.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: controller.onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const MyAppBar(hideBackButton: true),
        endDrawer: MyDrawer(),
        bottomNavigationBar: Obx(() => MyBottomNavigation(
              selectedIndex: controller.selectedIndex,
              onTabSelected: controller.onTabSelected,
            )),
        body: Stack(
          children: [
            // Background container
            Container(
              height: 100.0,
              color: kPrimaryColor,
            ),

            // Logo
            Positioned(
              top: 50.0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 100.0,
                  width: 100.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/images/xeLogo.png'),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.only(top: 35.0),
              child: SingleChildScrollView(
                child: CardGrid(
                  cards: [
                    SmallCard(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                    SmallCard(
                      icon: Icons.person,
                      title: 'Employee',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToEmployee),
                    ),
                    SmallCard(
                      icon: Icons.present_to_all,
                      title: 'Attendance',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                    SmallCard(
                      icon: Icons.energy_savings_leaf,
                      title: 'Farm',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                    SmallCard(
                      icon: Icons.person_add_alt,
                      title: 'Merchants',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                    SmallCard(
                      icon: Icons.work,
                      title: 'Jobs',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                    SmallCard(
                      icon: Icons.crop,
                      title: 'Crop & Yield',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                    SmallCard(
                      icon: Icons.money,
                      title: 'Expenses',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToExpenses),
                    ),
                    SmallCard(
                      icon: Icons.sell,
                      title: 'Sales',
                      color: kTertiaryColor,
                      onTap: (controller.navigateToDashboard),
                    ),
                  ],
                ),
              ),
            ),

            // Loading indicator
            Obx(
              () => controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
