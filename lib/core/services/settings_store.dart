import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter/material.dart';

/// Small persistent store for user preferences. Business data remains in the
/// database service; this store only owns presentation settings.
final class SettingsStore {
  SettingsStore._();
  static Box<dynamic>? _box;
  static Locale locale = const Locale('ar');
  static ThemeMode themeMode = ThemeMode.system;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<dynamic>('settings');
      final language = _box!.get('locale');
      if (language is String && {'ar', 'en', 'ku'}.contains(language)) {
        locale = Locale(language);
      }
      final theme = _box!.get('themeMode');
      if (theme is String) {
        themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == theme,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'SettingsStore',
          context: ErrorDescription(
            'Failed to initialize the Qisti settings store.',
          ),
        ),
      );
    }
  }

  static void saveLocale(Locale value) {
    locale = value;
    _box?.put('locale', value.languageCode);
  }

  static void saveTheme(ThemeMode value) {
    themeMode = value;
    _box?.put('themeMode', value.name);
  }
}
