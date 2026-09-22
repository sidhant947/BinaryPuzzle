import 'package:flutter/material.dart';
import 'package:binarypuzzle/domain/models/app_settings.dart';

class AppColors {
  AppColors._();

  static AppThemePreset currentTheme = AppThemePreset.pastelMint;

  static Color get primary => currentTheme.primary;
  static Color get accent => currentTheme.accent;
  static Color get headingDark => currentTheme.headingDark;
  static Color get subtext => currentTheme.subtext;
  static Color get bg => currentTheme.bg;
  static Color get gridLines => currentTheme.gridLines;
  static Color get surface => currentTheme.surface;
  static Color get border => currentTheme.border;
}
