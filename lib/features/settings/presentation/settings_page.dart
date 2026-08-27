import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.l10n.settings,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.language),
                trailing: DropdownButton<Locale>(
                  value: locale,
                  underline: const SizedBox.shrink(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(localeProvider.notifier).setLocale(value);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: const Locale('ar'),
                      child: Text(context.l10n.arabic),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text(context.l10n.english),
                    ),
                    DropdownMenuItem(
                      value: const Locale('ku'),
                      child: Text(context.l10n.kurdish),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(context.l10n.theme),
                trailing: DropdownButton<ThemeMode>(
                  value: theme,
                  underline: const SizedBox.shrink(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setMode(value);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(context.l10n.system),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(context.l10n.light),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(context.l10n.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.appName),
            subtitle: Text(context.l10n.versionLabel),
            trailing: const Text('1.0.0'),
          ),
        ),
      ],
    );
  }
}
