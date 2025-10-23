import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/data/services/attendance/attendance_service.dart';
import 'app/data/services/expenses/expense_service.dart';
import 'app/global_widgets/bottom_navigation/controller/bottom_navigation_controller.dart';
import 'app/global_widgets/card_grid/controller/card_controller.dart';
import 'app/modules/attendance/controller/attendance_controller.dart';
import 'app/modules/crop_variants/controller/crop_variant_controller.dart';
import 'app/modules/crops/controller/crop_controller.dart';
import 'app/modules/dashboard/controller/dashboard_controller.dart';
import 'app/modules/employees/controller/employee_controller.dart';
import 'app/modules/expenses/controller/expense_controller.dart';
import 'app/modules/farm_segments/controller/farm_seg_controller.dart';
import 'app/modules/merchants/controller/merchant_controller.dart';
import 'app/modules/sales/controller/sales_controller.dart';
import 'app/modules/settings/controller/settings_controller.dart';
import 'app/modules/wages/controller/wages_controller.dart';
import 'app/modules/yield/controller/yield_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/connectivity_service.dart';
import 'app_binding.dart';
import 'app/global_widgets/drawer/controller/drawer_controller.dart'
    as drawer_controller;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.init();

  // Register global services
  Get.put(connectivityService);
  Get.put(NavigationController());
  Get.put(CardController());
  Get.put(drawer_controller.DrawerController());
  Get.put(ExpensesController());
  Get.put(EmployeeController());
  Get.put(WagesController());
  Get.put(ExpenseService());
  Get.put(AttendanceService());
  Get.put(AttendanceController());
  Get.put(SettingsController());
  Get.put(CropController());
  Get.put(CropVariantController());
  Get.put(MerchantController());
  Get.put(FarmSegController());
  Get.put(YieldController());
  Get.put(SalesController());
  Get.put(DashboardController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Farm Agrobot',
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: AppBinding(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Work Sans',
      ),
    );
  }
}
