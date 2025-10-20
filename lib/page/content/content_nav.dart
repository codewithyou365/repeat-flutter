import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'content_binding.dart';
import 'content_page.dart';

class UpToDownWithFadeTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3), // from top
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve ?? Curves.easeOut,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve ?? Curves.easeOut,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

GetPage contentNav(String path) {
  return GetPage(
    name: path,
    customTransition: UpToDownWithFadeTransition(),
    popGesture: false,
    page: () => const ContentPage(),
    binding: ContentBinding(),
  );
}
