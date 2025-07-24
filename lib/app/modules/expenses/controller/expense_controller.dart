import 'package:get/get.dart';

class ExpensesController extends GetxController {
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
  void navigateToAddExpenses() {
    Get.toNamed('/add_expenses');
    
  }
  
  // Method to handle backup navigation
  // void navigateToBackup() {
  //   Get.toNamed('/expense_backup');
   
  // }
}