import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Snackbar {
  static void show(String content) {
    var context = Get.context;
    if (context == null) return;

    var overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    // Create an animation controller
    var animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Animation duration
      vsync: Navigator.of(context),
    );

    var opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    var slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly lower
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.5,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) => Opacity(
              opacity: opacityAnimation.value,
              child: SlideTransition(
                position: slideAnimation,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        content,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward(); // Start the animation

    // Remove snackbar after duration with fade-out animation
    Future.delayed(const Duration(seconds: 2), () async {
      await animationController.reverse(); // Fade out
      overlayEntry.remove();
    });
  }
}