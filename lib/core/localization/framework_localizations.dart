import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const _arabicFallback = Locale('ar');

final class QistiMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const QistiMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale) ||
      locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(
        locale.languageCode == 'ku' ? _arabicFallback : locale,
      );

  @override
  bool shouldReload(QistiMaterialLocalizationsDelegate old) => false;
}

final class QistiCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const QistiCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.isSupported(locale) ||
      locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(
        locale.languageCode == 'ku' ? _arabicFallback : locale,
      );

  @override
  bool shouldReload(QistiCupertinoLocalizationsDelegate old) => false;
}

final class QistiWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const QistiWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.isSupported(locale) ||
      locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) => GlobalWidgetsLocalizations
      .delegate
      .load(locale.languageCode == 'ku' ? _arabicFallback : locale);

  @override
  bool shouldReload(QistiWidgetsLocalizationsDelegate old) => false;
}
