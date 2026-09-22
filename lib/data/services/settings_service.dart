import 'package:hive_flutter/hive_flutter.dart';

import 'package:binarypuzzle/domain/models/app_settings.dart';

class SettingsService {
  static const String _boxName = 'binary_puzzle_settings';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  AppSettings getSettings() {
    final box = Hive.box(_boxName);
    final isHintEnabled = box.get('hint_enabled', defaultValue: false) as bool;
    final isHapticsEnabled = box.get('haptics_enabled', defaultValue: true) as bool;
    final themeId = box.get('app_theme', defaultValue: 'pastelMint') as String?;
    final resolvedTheme = AppThemePreset.fromId(themeId);
    return AppSettings(
      isHintEnabled: isHintEnabled,
      isHapticsEnabled: isHapticsEnabled,
      theme: resolvedTheme,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box(_boxName);
    await box.put('hint_enabled', settings.isHintEnabled);
    await box.put('haptics_enabled', settings.isHapticsEnabled);
    await box.put('app_theme', settings.theme.id);
  }
}
