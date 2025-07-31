import 'package:get/get.dart';
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
import '../modules/home/binding/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/wages/views/wages_screen.dart';



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
   
  ];
}