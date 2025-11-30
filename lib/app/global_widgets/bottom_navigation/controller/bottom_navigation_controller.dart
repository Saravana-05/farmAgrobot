import 'package:get/get.dart';

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;

void changeTabIndex(int index) {
    selectedIndex.value = index;
    
    // Handle navigation based on index
    switch (index) {
      case 0:
        // Home - you might want to navigate to home or do nothing
        break;
      case 1:
        // Dashboard - navigate to dashboard if needed
        break;
      case 2:
        // Settings - navigate to settings screen
        Get.toNamed('/settings'); // or Get.to(() => SettingsScreen());
        break;
    }
  }
}