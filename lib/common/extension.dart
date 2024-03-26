

import 'package:flutter/material.dart';

extension ThemeModeFromString on ThemeMode {
  static ThemeMode c(String value) {
    return ThemeMode.values.firstWhere(
          (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase(),
      orElse: () => ThemeMode.light,
    );
  }
}