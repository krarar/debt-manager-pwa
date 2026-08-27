import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qisti/l10n/app_localizations.dart';

void main() {
  test('supports Arabic, English, and Kurdish locales', () async {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(const [Locale('ar'), Locale('en'), Locale('ku')]),
    );
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    expect(arabic.dashboard, 'لوحة التحكم');
    expect(english.dashboard, 'Dashboard');
  });
}
