import 'package:flutter/services.dart';

class HapticService {
  static Future<void> light() async {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> medium() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
