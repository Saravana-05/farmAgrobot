import 'package:farm_agrobot/app/routes/app_pages.dart';
import 'package:get/get.dart';

class EmployeeController extends GetxController {
  // Observable variable for selected bottom navigation index
  final RxInt selectedIndex = 0.obs;

  // Method to handle tab selection
  void onTabSelected(int index) {
    selectedIndex.value = index;

    // Navigate to the corresponding screen based on the selected index
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
      // Add cases for other indexes if needed
    }
  }

  // Method to handle add expense navigation
  void navigateToEmployee() {
    Get.toNamed(Routes.ADD_EMPLOYEE);
  }
}
