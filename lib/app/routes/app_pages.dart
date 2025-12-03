import 'package:Farm_Agrobot/app/modules/yield/controller/yield_analytics_controller.dart';
import 'package:get/get.dart';
import '../modules/attendance/binding/employee_details_screen_binding.dart';
import '../modules/attendance/views/attendance.dart';
import '../modules/attendance/views/employee_details_screen.dart';
import '../modules/crop_variants/views/add_crop_variant.dart';
import '../modules/crop_variants/views/crop_variant_screen.dart';
import '../modules/crop_variants/views/edit_crop_variant.dart';
import '../modules/crop_variants/views/view_crop_variant.dart';
import '../modules/crops/views/add_crop_screen.dart';
import '../modules/crops/views/crop_edit_screen.dart';
import '../modules/crops/views/crop_view.dart';
import '../modules/crops/views/crops_screen.dart';
import '../modules/dashboard/view/dashboard_view.dart';
import '../modules/employees/views/add_employee.dart';
import '../modules/employees/views/edit_employee_screen.dart';
import '../modules/employees/views/employee_screen.dart';
import '../modules/employees/views/employee_view.dart';
import '../modules/expenses/binding/edit_expense_binding.dart';
import '../modules/expenses/binding/expense_initial_binding.dart';
import '../modules/expenses/views/add_expenses_screen.dart';
import '../modules/expenses/views/edit_expense_view.dart';
import '../modules/expenses/views/expense_screen.dart';
import '../modules/expenses/views/expense_view.dart';
import '../modules/farm_segments/views/add_farm_seg.dart';
import '../modules/farm_segments/views/edit_farm_seg.dart';
import '../modules/farm_segments/views/farm_seg_screen.dart';
import '../modules/farm_segments/views/view_farm_seg.dart';
import '../modules/home/binding/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/merchants/views/add_merchant.dart';
import '../modules/merchants/views/edit_merchant.dart';
import '../modules/merchants/views/merchant_screen.dart';
import '../modules/merchants/views/view_merchant.dart';
import '../modules/sales/bindings/edit_sales_binding.dart';
import '../modules/sales/bindings/sales_binding.dart';
import '../modules/sales/controller/add_sales_controller.dart';
import '../modules/sales/views/add_sales.dart';
import '../modules/sales/views/edit_sales.dart';
import '../modules/sales/views/sale_review_screen.dart';
import '../modules/sales/views/sales_screen.dart';
import '../modules/settings/views/settings_screen.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/wages/views/add_wages.dart';
import '../modules/wages/views/edit_wages.dart';
import '../modules/wages/views/view_wages.dart';
import '../modules/wages/views/wages_screen.dart';
import '../modules/yield/views/add_yield.dart';
import '../modules/yield/views/yield_analytics_screen.dart';
import '../modules/yield/views/yield_edit.dart';
import '../modules/yield/views/yield_screen.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => DashboardScreen(),
      // binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.EXPENSES,
      page: () => ExpensesScreen(),
    ),
    GetPage(
      name: _Paths.ADD_EXPENSES,
      page: () => AddExpenses(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_EXPENSE,
      page: () => EditExpense(),
      binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_EXPENSE,
      page: () => ViewExpenses(),
      binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EMPLOYEE,
      page: () => EmployeeScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_EMPLOYEE,
      page: () => ViewEmployees(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_EMPLOYEE,
      page: () => AddEmployee(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_EMPLOYEE,
      page: () => EditEmployee(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.WAGES,
      page: () => WagesScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_WAGES,
      page: () => AddWage(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_WAGES,
      page: () => ViewWages(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_WAGES,
      page: () => EditWage(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ATTENDANCE,
      page: () => AttendanceScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.CROPS,
      page: () => CropScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_CROPS,
      page: () => AddCrops(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_CROPS,
      page: () => CropEditScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_CROPS,
      page: () => ViewCrops(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.CROPS_VARIANTS,
      page: () => CropVariantScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_CROPS_VARIANTS,
      page: () => AddCropVariant(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_CROPS_VARIANTS,
      page: () => ViewCropVariants(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_CROPS_VARIANTS,
      page: () => CropVariantEditScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.MERCHANT,
      page: () => MerchantScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_MERCHANT,
      page: () => AddMerchant(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_MERCHANT,
      page: () => ViewMerchants(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_MERCHANT,
      page: () => MerchantEditScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.FARM_SEGMENT,
      page: () => FarmSegScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_FARM_SEGMENT,
      page: () => AddFarmSegments(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_FARM_SEGMENT,
      page: () => FarmSegmentEditScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.VIEW_FARM_SEGMENT,
      page: () => ViewFarmSegments(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.YIELD,
      page: () => YieldScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_YIELD,
      page: () => AddYield(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_YIELD,
      page: () => YieldEditScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.SALES,
      page: () => SalesScreen(),
      binding: SalesBinding(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ADD_SALES,
      page: () => AddSale(),
      binding: BindingsBuilder(() {
        Get.put(AddSaleController());
      }),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_SALES,
      page: () => EditSale(),
      binding: EditSaleBinding(),
    ),
    GetPage(
      name: _Paths.SALES_REVIEW,
      page: () => SaleReviewScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => SettingsScreen(),
      // binding: EditExpenseBinding(),
    ),
    GetPage(
      name: _Paths.YIELDANALYTICS,
      page: () => YieldAnalyticsScreen(),
    ),
    GetPage(
      name: _Paths.EMPLOYEE_DETAILS,
      page: () => EmployeeDetailsScreen(),
      binding: EmployeeDetailsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
