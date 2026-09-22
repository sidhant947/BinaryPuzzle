import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  static bool isEnabled = true;

  static void selectionClick() {
    if (isEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void lightImpact() {
    if (isEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (isEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (isEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  static void vibrate() {
    if (isEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
