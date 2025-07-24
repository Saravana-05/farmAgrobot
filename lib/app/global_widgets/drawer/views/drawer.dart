import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../controller/drawer_controller.dart' as drawer_controller;
import '../drawer_item.dart';

class MyDrawer extends GetView<drawer_controller.DrawerController> {
  final String? emails;

  const MyDrawer({super.key, this.emails});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(() => controller.isLoading.value
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(
                      color: kPrimaryColor,
                    ),
                    accountName: Text(controller.name.value),
                    accountEmail: Text(controller.email.value),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        controller.name.value.isNotEmpty
                            ? controller.name.value.substring(0, 1)
                            : 'G',
                        style: const TextStyle(
                            fontSize: 40.0, color: kPrimaryColor),
                      ),
                    ),
                  )),
            MyDrawerItem(
              title: 'Dashboard',
              icon: Icons.dashboard,
              onTap: () => controller.navigateToPage('/dashboard'),
            ),
            MyDrawerItem(
              title: 'Employee',
              icon: Icons.person,
              onTap: () => controller.navigateToPage('/employee'),
            ),
            MyDrawerItem(
              title: 'Attendance',
              icon: Icons.co_present,
              onTap: () => controller.navigateToPage('/attendance_new'),
            ),
            MyDrawerItem(
              title: 'Farm Segments',
              icon: Icons.energy_savings_leaf,
              onTap: () => controller.navigateToPage('/farms'),
            ),
            MyDrawerItem(
              title: 'Merchants',
              icon: Icons.person_add_alt,
              onTap: () => controller.navigateToPage('/merchants'),
            ),
            MyDrawerItem(
              title: 'Yield',
              icon: Icons.crop,
              onTap: () => controller.navigateToPage('/yield'),
            ),
            MyDrawerItem(
              title: 'Expenses',
              icon: Icons.attach_money,
              onTap: () => controller.navigateToPage('/expenses'),
            ),
            MyDrawerItem(
              title: 'Sales',
              icon: Icons.sell,
              onTap: () => controller.navigateToPage('/sales'),
            ),
            const Divider(),
            ListTile(
              title: const Text('App Version: version 1.0.0'),
              leading: const Icon(Icons.info),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
