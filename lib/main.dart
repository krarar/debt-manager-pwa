import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'l10n/app_localizations.dart';
import 'core/localization/framework_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/settings_store.dart';

class QistiApp extends StatelessWidget {
  const QistiApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderScope(child: _QistiAppView());
}

class _QistiAppView extends ConsumerWidget {
  const _QistiAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Qisti | قِسطي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        const QistiMaterialLocalizationsDelegate(),
        const QistiCupertinoLocalizationsDelegate(),
        const QistiWidgetsLocalizationsDelegate(),
      ],
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'en'
            ? TextDirection.ltr
            : TextDirection.rtl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.25,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: .035),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore.initialize();
  runApp(const QistiApp());
}
