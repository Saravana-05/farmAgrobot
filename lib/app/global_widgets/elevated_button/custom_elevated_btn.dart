import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/values/app_colors.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Changed to nullable
  final RxBool? isLoading;
  final Color? backgroundColor;

  const CustomElevatedButton({
    required this.text,
    this.onPressed,
    this.isLoading,
    this.backgroundColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLoadingValue = isLoading?.value ?? false;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoadingValue ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: kLightColor,
          backgroundColor: backgroundColor,
          minimumSize: const Size(150.0, 50.0),
        ),
        child: isLoadingValue
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kLightColor),
                ),
              )
            : Text(text),
      ),
    );
  }
}