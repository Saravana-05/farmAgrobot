import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom Snackbar utility class for consistent snackbars throughout the app
class CustomSnackbar {
  /// Show success snackbar
  static void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green, // Replace with kPrimaryColor if you have it
      colorText: Colors.white,
      snackPosition: position ?? SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 2),
      margin: margin ?? const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show error snackbar
  static void showError({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red, // Replace with kRed if you have it
      colorText: Colors.white,
      snackPosition: position ?? SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 3),
      margin: margin ?? const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.error,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show warning snackbar
  static void showWarning({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: position ?? SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 2),
      margin: margin ?? const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.warning,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show info snackbar
  static void showInfo({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
    SnackPosition? position,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: position ?? SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 2),
      margin: margin ?? const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.info,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// Show custom snackbar with full customization
  static void showCustom({
    required String title,
    required String message,
    required Color backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration? duration,
    EdgeInsets? margin,
    SnackPosition? position,
    bool isDismissible = true,
    double borderRadius = 8,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: textColor ?? Colors.white,
      snackPosition: position ?? SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 2),
      margin: margin ?? const EdgeInsets.all(16),
      borderRadius: borderRadius,
      icon: icon != null
          ? Icon(
              icon,
              color: textColor ?? Colors.white,
              size: 24,
            )
          : null,
      shouldIconPulse: false,
      isDismissible: isDismissible,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }
}