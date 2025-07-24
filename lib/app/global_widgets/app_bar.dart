import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/values/app_colors.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function()? onBackPressed;
  final bool hideBackButton;
  final String title;
  final bool showAddIcon;
  final Function()? onAddPressed;
  final Icon? addIcon;

  const MyAppBar({
    this.onBackPressed,
    this.hideBackButton = false,
    super.key,
    this.title = '',
    this.showAddIcon = false,
    this.onAddPressed,
    this.addIcon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: hideBackButton
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: kBlackColor),
              onPressed: onBackPressed ?? () => Get.back(),
            ),
      iconTheme: const IconThemeData(color: kSecondaryColor),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          if (showAddIcon)
            Positioned(
              right: 30.0,
              top: 40.0,
              child: Container(
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kLightYellowColor,
                    width: 1.0,
                  ),
                ),
                child: RawMaterialButton(
                  onPressed: onAddPressed ?? () {},
                  elevation: 0.0,
                  fillColor: kPrimaryColor,
                  padding: const EdgeInsets.all(10.0),
                  shape: const CircleBorder(),
                  child: addIcon ??
                      const Icon(
                        Icons.add,
                        size: 25.0,
                        color: kTertiaryColor,
                      ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
        ),
      ],
      backgroundColor: const Color.fromARGB(0, 221, 19, 19),
      elevation: 0.0,
    );
  }
}
