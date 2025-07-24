import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import 'controller/menu_app_bar_controller.dart';

class MenuAppBar extends GetView<MenuAppBarController> implements PreferredSizeWidget {
  final Function()? onBackPressed;
  final bool hideBackButton;
  final String title;
  final bool showAddIcon;
  final Function()? onAddPressed;
  final Icon? addIcon;
  final Function()? onMenuPressed;
  final List<Widget>? actions;

  const MenuAppBar({
    this.onBackPressed,
    this.hideBackButton = false,
    super.key,
    required this.title,
    this.showAddIcon = false,
    this.onAddPressed,
    this.addIcon,
    this.onMenuPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    // Initialize controller if not already done
    Get.put(MenuAppBarController(), permanent: true);
    
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: kPrimaryColor, // Green background color
        ),
      ),
      leading: hideBackButton
          ? null // Hide the back button
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: kLightColor),
              onPressed: () => controller.handleBackPress(onBackPressed),
            ),
      iconTheme: const IconThemeData(color: kLightYellow),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white, // White text color for better contrast on green
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          if (showAddIcon)
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: kLightYellowColor,
                  width: 1.0,
                ),
              ),
              child: RawMaterialButton(
                onPressed: () => controller.handleAddPress(onAddPressed),
                elevation: 0.0,
                fillColor: kPrimaryColor,
                child: addIcon ??
                    const Icon(
                      Icons.add,
                      size: 25.0,
                      color: kTertiaryColor,
                    ),
                padding: const EdgeInsets.all(8.0),
                shape: const CircleBorder(),
              ),
            ),
        ],
      ),
      actions: [
        // Include any custom actions passed in
        if (actions != null) ...actions!,
        // Menu button with better error handling
        Builder(
          builder: (BuildContext scaffoldContext) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => controller.handleMenuPress(onMenuPressed, scaffoldContext),
            );
          },
        ),
      ],
      elevation: 0.0,
    );
  }
}