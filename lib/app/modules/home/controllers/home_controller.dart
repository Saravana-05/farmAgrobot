
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../attendance/views/attendance.dart';
import '../../employees/views/employee_screen.dart';
import '../../expenses/views/expense_screen.dart';
import '../../wages/views/wages_screen.dart';
import '../views/home_view.dart';

class HomeController extends GetxController {
  // Observable variables
  final _selectedIndex = 0.obs;
  final _isLoading = false.obs;

  // Getters
  int get selectedIndex => _selectedIndex.value;
  bool get isLoading => _isLoading.value;

  // Methods
  void onTabSelected(int index) {
    _selectedIndex.value = index;
    
    // Handle navigation
    switch (index) {
      case 0:
        Get.toNamed('/home');
        break;
      case 1:
        Get.toNamed('/dashboard');
        break;
      case 2:
        Get.toNamed('/settings');
        break;
    }
  }

  Future<bool> onWillPop() async {
    final bool? shouldLogout = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Implement logout functionality here
      Get.offAllNamed('/login'); // Clear all routes and go to login
      return false;
    }
    return true;
  }

  void navigateToDashboard() {
    Get.to(() => const HomeView());
  }

  void navigateToExpenses() {
    Get.to(() => ExpensesScreen());
  }

  void navigateToEmployee() {
    Get.to(() => EmployeeScreen());
  }

  void navigateToWages() {
    Get.to(() => WagesScreen());
  }
  void navigateToAttendance() {
    Get.to(() => AttendanceScreen());
  }

  // void navigateToAttendance() {
  //   Get.to(() => EmployeeScreen());
  // }

  // void navigateToFarm() {
  //   Get.to(() => FarmScreen());
  // }

  // void navigateToMerchants() {
  //   Get.to(() => MerchantsScreen());
  // }

  // void navigateToJobs() {
  //   Get.to(() => JobScreen());
  // }

  // void navigateToYield() {
  //   Get.to(() => YieldScreen());
  // }

  // void navigateToExpenses() {
  //   Get.to(() => ExpensesScreen());
  // }

  // void navigateToSales() {
  //   Get.to(() => SalesScreen());
  // }

  void setLoading(bool value) {
    _isLoading.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize any data here
    print('HomeController initialized');
  }

  @override
  void onReady() {
    super.onReady();
    // Called after the widget is rendered
    print('HomeController ready');
  }

  @override
  void onClose() {
    super.onClose();
    // Clean up resources
    print('HomeController disposed');
  }
}