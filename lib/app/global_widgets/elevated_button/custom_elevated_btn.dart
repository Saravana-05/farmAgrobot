import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/values/app_colors.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final RxBool isLoading;
  
  CustomElevatedButton({
    required this.text,
    required this.onPressed,
    RxBool? isLoading,
    super.key,
  }) : isLoading = isLoading ?? RxBool(false);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() => ElevatedButton(
        onPressed: isLoading.value ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: kLightColor,
          backgroundColor: kSecondaryColor,
          minimumSize: const Size(150.0, 50.0),
        ),
        child: isLoading.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kLightColor),
                ),
              )
            : Text(text),
      )),
    );
  }
}