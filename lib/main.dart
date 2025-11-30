import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/data/services/attendance/attendance_service.dart';
import 'app/data/services/expenses/expense_service.dart';
import 'app/data/services/engagement/app_engagement_service.dart';
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

  // Initialize services
  await _initializeServices();

  runApp(MyApp());
}

/// Initialize all app services
Future<void> _initializeServices() async {
  debugPrint('🚀 Starting services initialization...');

  try {
    // Initialize connectivity service
    final connectivityService = ConnectivityService();
    await connectivityService.init();
    Get.put(connectivityService, permanent: true);
    debugPrint('✓ ConnectivityService initialized');

    // Initialize and register AppEngagementService
    final engagementService = AppEngagementService();
    await engagementService.initialize();
    Get.put(engagementService, permanent: true);
    debugPrint('✓ AppEngagementService initialized');

    // Register global controllers
    Get.put(NavigationController(), permanent: true);
    Get.put(CardController(), permanent: true);
    Get.put(drawer_controller.DrawerController(), permanent: true);
    Get.put(ExpensesController(), permanent: true);
    Get.put(EmployeeController(), permanent: true);
    Get.put(WagesController(), permanent: true);
    Get.put(ExpenseService(), permanent: true);
    Get.put(AttendanceService(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(CropController(), permanent: true);
    Get.put(CropVariantController(), permanent: true);
    Get.put(MerchantController(), permanent: true);
    Get.put(FarmSegController(), permanent: true);
    Get.put(YieldController(), permanent: true);
    Get.put(SalesController(), permanent: true);
    Get.put(DashboardController(), permanent: true);
    
    debugPrint('✓ All controllers registered');
    debugPrint('✅ Services initialization completed successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Error initializing services: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue app execution even if some services fail
  }
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