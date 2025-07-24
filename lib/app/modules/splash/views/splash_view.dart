import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Stack(
        children: [
          // Animated falling leaf
          AnimatedBuilder(
            animation: controller.leafAnimation,
            builder: (context, child) {
              double waveOffset =
                  math.sin(controller.leafAnimation.value * 4 * math.pi) * 30;
              double verticalPosition = MediaQuery.of(context).size.height *
                  controller.leafAnimation.value *
                  0.6;

              return Positioned(
                top: verticalPosition,
                left: MediaQuery.of(context).size.width * 0.5 + waveOffset - 25,
                child: Opacity(
                  opacity: math.max(0.0, 1.0 - controller.leafAnimation.value),
                  child: Transform.rotate(
                    angle: controller.leafAnimation.value * 4 * math.pi,
                    child: Container(
                      width: 50,
                      height: 50,
                      child: Image.asset(
                        'assets/images/leaf.png',
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          // Show a simple green circle if image fails to load
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Centered Logo
                FadeTransition(
                  opacity: controller.logoOpacityAnimation,
                  child: Container(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/images/xeLogo.png',
                      width: 200,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        // Show a placeholder if logo fails to load
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 100,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Text and Icon section
                FadeTransition(
                  opacity: controller.textOpacityAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Obx(() => Text(
                                controller.displayedText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Work Sans',
                                  height: 1.3,
                                ),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Second Image
                FadeTransition(
                  opacity: controller.secondImageOpacityAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    child: Image.asset(
                      'assets/images/2leaves.png',
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Show placeholder if second image fails to load
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.nature,
                            color: Colors.white,
                            size: 75,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated Navigation Button
          Obx(() => controller.showNavigationButton
              ? Positioned(
                  right: 20,
                  bottom: 20,
                  child: FadeTransition(
                    opacity: controller.navButtonAnimation,
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 1.0, end: 1.1),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      onEnd: () {},
                      child: FloatingActionButton.extended(
                        onPressed: controller.navigateToNext,
                        backgroundColor: Colors.green,
                        elevation: 4,
                        label: const Row(
                          children: [
                            Text(
                              'Organics For All',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.eco,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
