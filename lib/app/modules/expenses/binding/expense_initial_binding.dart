import 'package:get/get.dart';
import '../../../data/services/expenses/expense_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExpenseService());
  }
}