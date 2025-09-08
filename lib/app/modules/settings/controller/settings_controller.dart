import 'package:get/get.dart';

class SettingsController extends GetxController {
  
  // Observable selected index for bottom navigation
  var selectedIndex = 2.obs;
  
  SettingsController();
  
  // Navigation methods
  void navigateToPage(String route) {
    Get.back(); // Close the drawer if open
    Get.toNamed(route);
  }
  
  
  
  void navigateToProfile() {
    // Navigate to profile screen
    // Get.toNamed('/profile');
  }
  

  
  // Bottom navigation handler
  void onTabSelected(int index) {
    selectedIndex.value = index;
    
    switch (index) {
      case 0:
        Get.offAllNamed('/home');
        break;
      case 1:
        Get.offAllNamed('/dashboard');
        break;
      case 2:
        Get.offAllNamed('/settings');
        break;
    }
  }
}