import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerController extends GetxController {
  var name = 'Guest'.obs;
  var email = 'user@example.com'.obs;
  var isLoading = true.obs;
  final String appVersion = 'v0.5';

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      name.value = prefs.getString('name') ?? 'Guest';
      email.value = prefs.getString('email') ?? 'user@example.com';
    } catch (e) {
      // Handle error if needed
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToPage(String route) {
    Get.back(); // Close the drawer
    Get.toNamed(route); // Navigate to the specified route
  }
}
