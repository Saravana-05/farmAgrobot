import 'package:get/get.dart';
import '../controller/edit_expense_controller.dart';

class EditExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditExpenseController>(() => EditExpenseController());
  }
}

