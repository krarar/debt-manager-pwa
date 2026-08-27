import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_store.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => SettingsStore.locale;

  void setLocale(Locale locale) {
    state = locale;
    SettingsStore.saveLocale(locale);
  }
}
