import 'package:farm_agrobot/app/routes/app_pages.dart';
import 'package:get/get.dart';

class SalesController extends GetxController {
  /// Reactive bottom navigation index
  final RxInt selectedIndex = 0.obs;

  /// Handle tab selection
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

  /// Navigate to Add Sales screen
  void navigateToAddSales() {
    Get.toNamed(Routes.ADD_SALES);
  }

  /// Navigate to Crops screen
  void navigateToViewCrops() {
    Get.toNamed(Routes.ADD_CROPS);
  }
}
