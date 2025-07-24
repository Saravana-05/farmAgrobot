import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../drawer/controller/drawer_controller.dart' as drawer_controller;

class MyDrawerItem extends GetWidget<drawer_controller.DrawerController> {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MyDrawerItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}