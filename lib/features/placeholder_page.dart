import 'package:flutter/material.dart';
import '../core/localization/app_localizations_extension.dart';

enum PlaceholderTitle { reports, backup, settings }

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.titleKey,
    required this.icon,
    super.key,
  });
  final PlaceholderTitle titleKey;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final title = switch (titleKey) {
      PlaceholderTitle.reports => context.l10n.reports,
      PlaceholderTitle.backup => context.l10n.backup,
      PlaceholderTitle.settings => context.l10n.settings,
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(context.l10n.placeholderDescription),
        ],
      ),
    );
  }
}
