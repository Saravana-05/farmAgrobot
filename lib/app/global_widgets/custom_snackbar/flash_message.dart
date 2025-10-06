import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom Flash Message utility class for consistent flash messages throughout the app
class CustomFlashMessage {
  /// Show success flash message
  static void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    _showFlashMessage(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF4CAF50), // Green
      icon: Icons.check_circle_outline,
      duration: duration ?? const Duration(seconds: 3),
      margin: margin,
    );
  }

  /// Show error flash message
  static void showError({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    _showFlashMessage(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFFF5252), // Red
      icon: Icons.error_outline,
      duration: duration ?? const Duration(seconds: 4),
      margin: margin,
    );
  }

  /// Show warning flash message
  static void showWarning({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    _showFlashMessage(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFFF9800), // Orange
      icon: Icons.warning_amber_outlined,
      duration: duration ?? const Duration(seconds: 3),
      margin: margin,
    );
  }

  /// Show info flash message
  static void showInfo({
    required String title,
    required String message,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    _showFlashMessage(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF2196F3), // Blue
      icon: Icons.info_outline,
      duration: duration ?? const Duration(seconds: 3),
      margin: margin,
    );
  }

  /// Show custom flash message with full customization
  static void showCustom({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color? textColor,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    _showFlashMessage(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      textColor: textColor,
      duration: duration ?? const Duration(seconds: 3),
      margin: margin,
    );
  }

  /// Private method to show the flash message overlay
  static void _showFlashMessage({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color? textColor,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    final context = Get.context;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FlashMessageWidget(
        title: title,
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        textColor: textColor ?? Colors.white,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration ?? const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/// Private widget for the flash message UI
class _FlashMessageWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color textColor;
  final EdgeInsets margin;
  final VoidCallback onDismiss;

  const _FlashMessageWidget({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.textColor,
    required this.margin,
    required this.onDismiss,
  });

  @override
  State<_FlashMessageWidget> createState() => _FlashMessageWidgetState();
}

class _FlashMessageWidgetState extends State<_FlashMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                margin: widget.margin,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              widget.icon,
                              color: widget.textColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: widget.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      color: widget.textColor.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _dismiss,
                              child: Icon(
                                Icons.close,
                                color: widget.textColor.withOpacity(0.8),
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
            ),
          );
        },
      ),
    );
  }
}