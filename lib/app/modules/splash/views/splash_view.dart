import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  @override
  Widget build(BuildContext context) {
    // Observe the engagement status
    return Obx(() {
      bool isSad = controller.isFarmSad.value;
      Color primaryColor = isSad ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
      Color secondaryColor = isSad ? const Color(0xFFEF5350) : const Color(0xFF4CAF50);
      Color backgroundColor = isSad ? const Color(0xFFFFF5F5) : const Color(0xFFF8FAF5);
      
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Subtle background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(
                  painter: GridPatternPainter(color: primaryColor),
                ),
              ),
            ),

            // Animated tractor with dust trail and wheel rotation
            AnimatedBuilder(
              animation: controller.leafAnimation,
              builder: (context, child) {
                double screenWidth = MediaQuery.of(context).size.width;
                double screenHeight = MediaQuery.of(context).size.height;

                double progress = controller.leafAnimation.value;
                double horizontalPosition = screenWidth * progress;
                double roadLevel = screenHeight * 0.75;

                // Realistic suspension bounce (slower if sad)
                double bounceSpeed = isSad ? 15 : 20;
                double bounce = math.sin(progress * bounceSpeed * math.pi) * 2;
                double verticalPosition = roadLevel + bounce;

                // Wheel rotation angle (slower if sad)
                double wheelRotation = progress * (isSad ? 15 : 20) * math.pi;

                // Fade in at start, stay visible, fade out at end
                double opacity = progress < 0.08
                    ? progress * 12.5
                    : progress > 0.88
                        ? (1.0 - progress) * 8.33
                        : 1.0;

                return Stack(
                  children: [
                    // Dust trail particles
                    if (progress > 0.1 && progress < 0.85)
                      for (int i = 0; i < 5; i++)
                        Positioned(
                          top: verticalPosition + 35,
                          left: horizontalPosition - (i * 15.0) - 40,
                          child: Opacity(
                            opacity: math.max(
                                0.0,
                                math.min(
                                    1.0,
                                    (0.4 - (i * 0.08)) *
                                        math.min(1.0, opacity))),
                            child: Container(
                              width: 8 - (i * 1.0),
                              height: 8 - (i * 1.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8D6E63).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                    // Main tractor body
                    Positioned(
                      top: verticalPosition - 20,
                      left: horizontalPosition - 35,
                      child: Opacity(
                        opacity: math.max(0.0, math.min(1.0, opacity)),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: Stack(
                            children: [
                              // Autonomous tractor body
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  width: 50,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor, secondaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: secondaryColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Agriculture icon
                                      const Center(
                                        child: Icon(
                                          Icons.agriculture,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      // AI indicator - changes based on mood
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isSad 
                                                ? const Color(0xFFFF1744)
                                                : const Color(0xFF00E676),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isSad 
                                                    ? const Color(0xFFFF1744)
                                                    : const Color(0xFF00E676))
                                                    .withOpacity(0.6),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Circuit lines
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        right: 4,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Front wheel (small)
                              Positioned(
                                bottom: 5,
                                right: 8,
                                child: Transform.rotate(
                                  angle: wheelRotation,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF424242),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF616161),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF9E9E9E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Back wheel (large)
                              Positioned(
                                bottom: 0,
                                left: 5,
                                child: Transform.rotate(
                                  angle: wheelRotation,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF424242),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF616161),
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF9E9E9E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Exhaust smoke (darker if sad)
                              if (progress > 0.15 && progress < 0.8)
                                Positioned(
                                  top: 5,
                                  left: 5,
                                  child: Opacity(
                                    opacity: 0.3 +
                                        (math.sin(progress * 30 * math.pi) *
                                            0.2),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: (isSad 
                                            ? const Color(0xFF546E7A)
                                            : const Color(0xFF78909C))
                                            .withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Modern Logo Container with mood indicator
                  AnimatedBuilder(
                    animation: controller.logoOpacityAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.95 +
                            (math.sin(controller.logoOpacityAnimation.value *
                                        math.pi *
                                        2) *
                                    0.05 *
                                    controller.logoOpacityAnimation.value),
                        child: Opacity(
                          opacity: controller.logoOpacityAnimation.value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: secondaryColor.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Circuit board pattern overlay
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.1,
                                    child: CustomPaint(
                                      painter: CircuitPatternPainter(),
                                    ),
                                  ),
                                ),
                                // Agriculture icon with mood indicator
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.agriculture,
                                      color: Colors.white,
                                      size: 70,
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      isSad 
                                          ? Icons.sentiment_very_dissatisfied
                                          : Icons.sentiment_satisfied,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // App Name with Icons
                  AnimatedBuilder(
                    animation: controller.textOpacityAnimation,
                    builder: (context, child) {
                      double slideValue = controller.textOpacityAnimation.value;
                      return Opacity(
                        opacity: slideValue,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // "Farm" text
                                Transform.translate(
                                  offset: Offset(-50 * (1 - slideValue), 0),
                                  child: Text(
                                    'Farm',
                                    style: TextStyle(
                                      fontSize: 36,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Two leaves icon
                                Opacity(
                                  opacity: slideValue,
                                  child: Stack(
                                    children: [
                                      Transform.rotate(
                                        angle: -0.3,
                                        child: Icon(
                                          Icons.eco,
                                          color: secondaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12),
                                        child: Transform.rotate(
                                          angle: 0.3,
                                          child: Icon(
                                            Icons.eco,
                                            color: isSad 
                                                ? const Color(0xFFEF5350)
                                                : const Color(0xFF66BB6A),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // "Agro" text
                                Transform.translate(
                                  offset: Offset(50 * (1 - slideValue), 0),
                                  child: Text(
                                    'Agro',
                                    style: TextStyle(
                                      fontSize: 36,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),

                                // Bot icon
                                Transform.scale(
                                  scale: slideValue,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.smart_toy,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: secondaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Smart Farming Solution',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: secondaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Mood-based tagline
                  AnimatedBuilder(
                    animation: controller.secondImageOpacityAnimation,
                    builder: (context, child) {
                      double animValue =
                          controller.secondImageOpacityAnimation.value;
                      double translateY = 20 * (1 - animValue);

                      return Transform.translate(
                        offset: Offset(0, translateY),
                        child: Opacity(
                          opacity: animValue,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                Text(
                                  isSad 
                                      ? 'Your Farm Missed You!'
                                      : 'Cultivating the Future',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (isSad && controller.hoursSinceLastOpen.value > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Last visit: ${controller.hoursSinceLastOpen.value}h ago',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: primaryColor.withOpacity(0.7),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Modern Navigation Button
            Obx(() => controller.showNavigationButton
                ? Positioned(
                    left: 0,
                    right: 0,
                    bottom: 50,
                    child: FadeTransition(
                      opacity: controller.navButtonAnimation,
                      child: Center(
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(28),
                          shadowColor: secondaryColor.withOpacity(0.4),
                          child: InkWell(
                            onTap: controller.navigateToNext,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isSad ? 'Check Your Farm' : 'Get Started',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),

            // Version indicator
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: controller.textOpacityAnimation,
                child: const Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Custom painter for subtle grid pattern
class GridPatternPainter extends CustomPainter {
  final Color color;
  
  GridPatternPainter({this.color = const Color(0xFF2E7D32)});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for circuit pattern overlay
class CircuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.3),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      3,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}