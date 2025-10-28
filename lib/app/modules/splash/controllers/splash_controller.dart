import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../data/services/connectivity_service.dart';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  final ConnectivityService connectivityService = Get.find<ConnectivityService>();

  late AnimationController _bgController;
  late AnimationController _leafController;
  late AnimationController _logoController;
  late AnimationController _secondImageController;
  late AnimationController _textController;
  late AnimationController _navButtonController;

  late Animation<double> _bgAnimation;
  late Animation<double> _leafAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _secondImageOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _navButtonAnimation;

  final String motto = "Growing Organic, Growing Together";
  final _displayedText = "".obs;
  final _showNavigationButton = false.obs;

  // Getters for animations
  Animation<double> get bgAnimation => _bgAnimation;
  Animation<double> get leafAnimation => _leafAnimation;
  Animation<double> get logoOpacityAnimation => _logoOpacityAnimation;
  Animation<double> get secondImageOpacityAnimation => _secondImageOpacityAnimation;
  Animation<double> get textOpacityAnimation => _textOpacityAnimation;
  Animation<double> get navButtonAnimation => _navButtonAnimation;

  // Getters for reactive variables
  String get displayedText => _displayedText.value;
  bool get showNavigationButton => _showNavigationButton.value;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Background animation controller
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );

    _leafController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _secondImageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _navButtonController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _leafAnimation = CurvedAnimation(
      parent: _leafController,
      curve: Curves.easeInOut,
    );

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));

    _secondImageOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondImageController,
      curve: Curves.easeInOut,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _navButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navButtonController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // Start background animation first
    _bgController.forward();

    // Leaf animation
    await _leafController.forward();

    // Delay before logo
    await Future.delayed(const Duration(milliseconds: 500));
    await _logoController.forward();

    // Delay before second image
    await Future.delayed(const Duration(milliseconds: 300));
    await _secondImageController.forward();

    // Delay before text
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();

    // Typing effect for text
    for (int i = 0; i <= motto.length; i++) {
      _displayedText.value = motto.substring(0, i);
      await Future.delayed(const Duration(milliseconds: 80));
    }

    // Show navigation button
    await Future.delayed(const Duration(milliseconds: 500));
    _showNavigationButton.value = true;
    _navButtonController.forward();
  }

  void navigateToNext() {
    bool isLoggedIn = _checkUserLoginStatus();
    if (isLoggedIn) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.HOME);
    }
  }

  bool _checkUserLoginStatus() {
    // TODO: Replace with real login check
    return false;
  }

  @override
  void onClose() {
    _bgController.dispose();
    _leafController.dispose();
    _logoController.dispose();
    _secondImageController.dispose();
    _textController.dispose();
    _navButtonController.dispose();
    super.onClose();
  }
}
