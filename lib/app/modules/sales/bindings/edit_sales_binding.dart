import 'package:get/get.dart';
import '../controller/edit_sales_controller.dart';

class EditSaleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditSaleController>(() => EditSaleController());
  }
}