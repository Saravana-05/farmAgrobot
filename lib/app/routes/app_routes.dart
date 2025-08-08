part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const HOME = _Paths.HOME;
  static const EXPENSES = _Paths.EXPENSES;
  static const ADD_EXPENSES = _Paths.ADD_EXPENSES;
  static const EDIT_EXPENSE = _Paths.EDIT_EXPENSE;
  static const VIEW_EXPENSE = _Paths.VIEW_EXPENSE;
  static const EMPLOYEE = _Paths.EMPLOYEE;
  static const VIEW_EMPLOYEE = _Paths.VIEW_EMPLOYEE;
  static const ADD_EMPLOYEE = _Paths.ADD_EMPLOYEE;
  static const EDIT_EMPLOYEE = _Paths.EDIT_EMPLOYEE;
  static const WAGES = _Paths.WAGES;
  static const ADD_WAGES = _Paths.ADD_WAGES;
  static const EDIT_WAGES = _Paths.EDIT_WAGES;
  static const VIEW_WAGES = _Paths.VIEW_WAGES;
  static const VIEW_ATTENDANCE = _Paths.VIEW_ATTENDANCE;
  static const CREATE_ATTENDANCE = _Paths.CREATE_ATTENDANCE;
  static const EDIT_ATTENDANCE = _Paths.EDIT_ATTENDANCE;
  static const ATTENDANCE = _Paths.ATTENDANCE;
  static const EMPLOYEE_DETAILS = _Paths.EMPLOYEE_DETAILS;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const EXPENSES = '/expenses';
  static const ADD_EXPENSES = '/add_expenses';
  static const EDIT_EXPENSE = '/edit_expenses';
  static const VIEW_EXPENSE = '/view_expenses';
  static const EMPLOYEE = '/employee';
  static const VIEW_EMPLOYEE = '/view_employee';
  static const ADD_EMPLOYEE = '/add_employee';
  static const EDIT_EMPLOYEE = '/edit_employee';
  static const WAGES = '/wages';
  static const ADD_WAGES = '/add_wages';
  static const EDIT_WAGES = '/edit_wages';
  static const VIEW_WAGES = '/view_wages';
  static const VIEW_ATTENDANCE = '/view_attendance';
  static const CREATE_ATTENDANCE = '/create_attendance';
  static const EDIT_ATTENDANCE = '/edit_attendance';
  static const ATTENDANCE = '/attendance';
  static const EMPLOYEE_DETAILS = '/employee_details';
}
