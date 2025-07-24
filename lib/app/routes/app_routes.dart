part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const HOME = _Paths.HOME;
  static const EXPENSES = _Paths.EXPENSES;
  static const ADD_EXPENSES = _Paths.ADD_EXPENSES;
  static const EDIT_EXPENSE = _Paths.EDIT_EXPENSE;
  static const VIEW_EXPENSE = _Paths.VIEW_EXPENSE;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const EXPENSES = '/expenses';
  static const ADD_EXPENSES = '/add_expenses';
  static const EDIT_EXPENSE = '/edit_expenses';
  static const VIEW_EXPENSE = '/view_expenses';
}
