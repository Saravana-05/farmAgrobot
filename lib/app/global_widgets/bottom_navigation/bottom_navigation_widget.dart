import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import '../../core/values/app_colors.dart';

class MyBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const MyBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: selectedIndex,
      backgroundColor: kLightColor,
      color: kPrimaryColor,
      onTap: onTabSelected,
      items: [
        CurvedNavigationBarItem(
          child: Icon(
            Icons.home,
            color: selectedIndex == 0 ? Colors.yellow : kLightColor,
          ),
          label: 'Home',
          labelStyle: TextStyle(
            color: selectedIndex == 0 ? Colors.yellow : kLightYellow,
          ),
        ),
        CurvedNavigationBarItem(
          child: Icon(
            Icons.dashboard,
            color: selectedIndex == 1 ? Colors.yellow : kLightColor,
          ),
          label: 'Dashboard',
          labelStyle: TextStyle(
            color: selectedIndex == 1 ? Colors.yellow : kLightYellow,
          ),
        ),
        CurvedNavigationBarItem(
          child: Icon(
            Icons.settings,
            color: selectedIndex == 2 ? Colors.yellow : kLightColor,
          ),
          label: 'Settings',
          labelStyle: TextStyle(
            color: selectedIndex == 2 ? Colors.yellow : kLightYellow,
          ),
        ),
      ],
    );
  }
}
