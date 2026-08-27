import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations_extension.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive_layout.dart';
import '../../app/providers.dart';
import 'qisti_background.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _routes = [
    '/dashboard',
    '/installments',
    '/customers',
    '/products',
    '/sales',
    '/inventory',
    '/payments',
    '/receipts',
    '/reports',
    '/search',
    '/notifications',
    '/backup',
    '/settings',
  ];
  static const _primaryRoutes = [
    '/dashboard',
    '/installments',
    '/add-debt',
    '/customers',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    final route = GoRouterState.of(context).uri.path;
    final selected = _routes.indexWhere((item) => route.startsWith(item));
    final selectedIndex = selected < 0 ? 0 : selected;
    final mobileIndex = route.startsWith('/dashboard')
        ? 0
        : route.startsWith('/installments') || route.startsWith('/plans/')
        ? 1
        : route.startsWith('/add-debt')
        ? 2
        : route.startsWith('/customers')
        ? 3
        : 4;
    final desktop = ResponsiveLayout.isDesktop(context);
    final compactMobile = MediaQuery.sizeOf(context).width < 360;

    final actions = <Widget>[
      if (desktop)
        FilledButton.icon(
          onPressed: () => context.go('/add-debt'),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addDebt),
        ),
      IconButton(
        tooltip: context.l10n.search,
        onPressed: () => context.go('/search'),
        icon: const Icon(Icons.search),
      ),
      IconButton(
        tooltip: context.l10n.notifications,
        onPressed: () => context.go('/notifications'),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: const Icon(Icons.notifications_none),
        ),
      ),
      if (!compactMobile)
        PopupMenuButton<Locale>(
          tooltip: context.l10n.language,
          icon: const Icon(Icons.translate),
          onSelected: (locale) =>
              ref.read(localeProvider.notifier).setLocale(locale),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: const Locale('ar'),
              child: Text(context.l10n.arabic),
            ),
            PopupMenuItem(
              value: const Locale('en'),
              child: Text(context.l10n.english),
            ),
            PopupMenuItem(
              value: const Locale('ku'),
              child: Text(context.l10n.kurdish),
            ),
          ],
        ),
      if (!compactMobile)
        PopupMenuButton<ThemeMode>(
          tooltip: context.l10n.theme,
          icon: const Icon(Icons.brightness_6_outlined),
          onSelected: (mode) =>
              ref.read(themeModeProvider.notifier).setMode(mode),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ThemeMode.system,
              child: Text(context.l10n.system),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: Text(context.l10n.light),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Text(context.l10n.dark),
            ),
          ],
        ),
      if (compactMobile)
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            final parts = value.split(':');
            if (parts.length == 2 && parts[0] == 'lang') {
              ref.read(localeProvider.notifier).setLocale(Locale(parts[1]));
            }
            if (parts.length == 2 && parts[0] == 'theme') {
              final mode = switch (parts[1]) {
                'light' => ThemeMode.light,
                'dark' => ThemeMode.dark,
                _ => ThemeMode.system,
              };
              ref.read(themeModeProvider.notifier).setMode(mode);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'lang:ar', child: Text(context.l10n.arabic)),
            PopupMenuItem(value: 'lang:en', child: Text(context.l10n.english)),
            PopupMenuItem(value: 'lang:ku', child: Text(context.l10n.kurdish)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'theme:system', child: Text(context.l10n.system)),
            PopupMenuItem(value: 'theme:light', child: Text(context.l10n.light)),
            PopupMenuItem(value: 'theme:dark', child: Text(context.l10n.dark)),
          ],
        ),
      const SizedBox(width: 8),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.appName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: actions,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: QistiBackground()),
          Row(
            children: [
              if (desktop) _Sidebar(selectedIndex: selectedIndex),
              Expanded(child: child),
            ],
          ),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: mobileIndex,
              onDestinationSelected: (index) {
                if (index == 2) {
                  context.go('/add-debt');
                } else if (index == 4) {
                  _showMore(context);
                } else {
                  context.go(_primaryRoutes[index]);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: context.l10n.dashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month),
                  label: context.l10n.installments,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.add_circle_outline),
                  selectedIcon: const Icon(Icons.add_circle),
                  label: context.l10n.addDebt,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: context.l10n.customers,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz),
                  selectedIcon: const Icon(Icons.more_horiz),
                  label: context.l10n.more,
                ),
              ],
            ),
      floatingActionButton: desktop
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/add-debt'),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addDebt),
            )
          : null,
    );
  }

  void _showMore(BuildContext context) {
    final entries = [
      (context.l10n.products, Icons.inventory_2_outlined, '/products'),
      (context.l10n.sales, Icons.point_of_sale, '/sales'),
      (context.l10n.inventory, Icons.warehouse_outlined, '/inventory'),
      (context.l10n.payments, Icons.payments_outlined, '/payments'),
      (context.l10n.receipts, Icons.receipt_long_outlined, '/receipts'),
      (context.l10n.reports, Icons.bar_chart_outlined, '/reports'),
      (context.l10n.search, Icons.search, '/search'),
      (context.l10n.notifications, Icons.notifications_none, '/notifications'),
      (context.l10n.backup, Icons.backup_outlined, '/backup'),
      (context.l10n.settings, Icons.settings_outlined, '/settings'),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in entries)
              ListTile(
                leading: Icon(entry.$2),
                title: Text(entry.$1),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(entry.$3);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = [
      (l10n.dashboard, Icons.dashboard_outlined, '/dashboard'),
      (l10n.installments, Icons.calendar_month_outlined, '/installments'),
      (l10n.customers, Icons.people_outline, '/customers'),
      (l10n.products, Icons.inventory_2_outlined, '/products'),
      (l10n.sales, Icons.point_of_sale, '/sales'),
      (l10n.inventory, Icons.warehouse_outlined, '/inventory'),
      (l10n.payments, Icons.payments_outlined, '/payments'),
      (l10n.receipts, Icons.receipt_long_outlined, '/receipts'),
      (l10n.reports, Icons.bar_chart_outlined, '/reports'),
      (l10n.notifications, Icons.notifications_none, '/notifications'),
      (l10n.backup, Icons.backup_outlined, '/backup'),
      (l10n.settings, Icons.settings_outlined, '/settings'),
    ];
    return SingleChildScrollView(
      child: NavigationRail(
        selectedIndex: selectedIndex.clamp(0, entries.length - 1),
        onDestinationSelected: (index) => context.go(entries[index].$3),
        labelType: NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        destinations: [
          for (final entry in entries)
            NavigationRailDestination(
              icon: Icon(entry.$2),
              selectedIcon: Icon(entry.$2),
              label: Text(entry.$1),
            ),
        ],
      ),
    );
  }
}
