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
}
