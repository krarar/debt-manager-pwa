import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/utils/responsive_layout.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installments = ref.watch(allInstallmentsProvider);
    final summary = ref.watch(financialSummaryProvider);
    return installments.when(
      loading: () => Center(child: Text(context.l10n.welcome)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) {
        final figures = summary.valueOrNull;
        if (figures == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final total = figures.totalDebtIQD;
        final outstanding = figures.totalRemainingIQD;
        final collected = figures.totalPaidIQD;
        final due = figures.dueTodayCount;
        final overdueAmount = figures.overdueIQD;
        final totalSales = figures.totalSalesIQD;
        final lowStock = figures.lowStockCount;
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: ResponsiveLayout.pagePadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveLayout.maxContentWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.welcome,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(context.l10n.dashboardSubtitle),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: ResponsiveLayout.metricColumns(context),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: ResponsiveLayout.isMobile(context)
                          ? 2.7
                          : 2.2,
                      children: [
                        _MetricCard(
                          title: context.l10n.totalOwed,
                          value: '$total ${context.l10n.currency}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.blue,
                        ),
                        _MetricCard(
                          title: context.l10n.totalDueToMe,
                          value: '$outstanding ${context.l10n.currency}',
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                        _MetricCard(
                          title: context.l10n.dueToday,
                          value: '$due',
                          icon: Icons.warning_amber_outlined,
                          color: Colors.orange,
                        ),
                        _MetricCard(
                          title: context.l10n.overdue,
                          value: '$overdueAmount ${context.l10n.currency}',
                          icon: Icons.people_outline,
                          color: Colors.purple,
                        ),
                        _MetricCard(
                          title: context.l10n.totalCollected,
                          value: '$collected ${context.l10n.currency}',
                          icon: Icons.savings_outlined,
                          color: Colors.teal,
                        ),
                        _MetricCard(
                          title: context.l10n.totalSales,
                          value: '$totalSales ${context.l10n.currency}',
                          icon: Icons.point_of_sale,
                          color: Colors.indigo,
                        ),
                        _MetricCard(
                          title: context.l10n.lowStock,
                          value: '$lowStock',
                          icon: Icons.inventory_2_outlined,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.l10n.upcomingInstallments,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => context.go('/installments'),
                                  child: Text(context.l10n.viewAll),
                                ),
                              ],
                            ),
                            ...items
                                .where((i) => i.remainingIQD > 0)
                                .take(5)
                                .map(
                                  (i) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                    title: Text(
                                      '${context.l10n.installments} ${i.sequence}',
                                    ),
                                    subtitle: Text(
                                      i.dueDate
                                          .toLocal()
                                          .toString()
                                          .split(' ')
                                          .first,
                                    ),
                                    trailing: Text(
                                      '${i.remainingIQD} ${context.l10n.currency}',
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .14),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
