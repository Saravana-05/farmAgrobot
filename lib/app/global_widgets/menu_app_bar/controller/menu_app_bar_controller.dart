import 'package:get/get.dart';
import 'package:flutter/material.dart';

class MenuAppBarController extends GetxController {
  // Handle back button press
  void handleBackPress(Function()? onBackPressed) {
    if (onBackPressed != null) {
      onBackPressed();
    } else {
      Get.back();
    }
  }
  
  // Handle add button press
  void handleAddPress(Function()? onAddPressed) {
    if (onAddPressed != null) {
      onAddPressed();
    }
  }
  
  // Handle menu button press
  void handleMenuPress(Function()? onMenuPressed, BuildContext context) {
    if (onMenuPressed != null) {
      onMenuPressed();
    } else {
      try {
        // Use the context to open end drawer
        Scaffold.of(context).openEndDrawer();
      } catch (e) {
        print('Error opening drawer: $e');
        // Fallback: try to find scaffold in widget tree
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null && scaffold.hasEndDrawer) {
          scaffold.openEndDrawer();
        }
      }
    }
  }
  
  // Show snackbar for notifications (optional enhancement)
  void showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Info',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}