import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/installment.dart';
import '../../../domain/entities/installment_plan.dart';
import '../../../shared/widgets/summary_card.dart';

class CustomerDetailsPage extends ConsumerWidget {
  const CustomerDetailsPage({required this.customerId, super.key});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerProvider(customerId));
    final plans = ref.watch(customerPlansProvider(customerId));
    final allInstallments = ref.watch(allInstallmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.customerDetails),
        actions: [
          IconButton(
            tooltip: context.l10n.editCustomer,
            onPressed: () => context.push('/customers/$customerId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: context.l10n.deleteCustomer,
            onPressed: () => _deleteCustomer(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: customer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.saveFailed)),
        data: (c) => c == null
            ? Center(child: Text(context.l10n.noCustomers))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    c.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (c.phone.isNotEmpty) Text(c.phone),
                  if (c.address.isNotEmpty) Text(c.address),
                  const SizedBox(height: 20),
                  plans.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(context.l10n.saveFailed),
                    data: (items) => allInstallments.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(context.l10n.saveFailed),
                      data: (allItems) => _summary(context, items, allItems),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.installments,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            context.push('/customers/$customerId/add-plan'),
                        icon: const Icon(Icons.add),
                        label: Text(context.l10n.addPlan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  plans.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text(context.l10n.saveFailed)),
                    data: (items) => items.isEmpty
                        ? Center(child: Text(context.l10n.noPlans))
                        : Column(
                            children: [
                              for (final p in items) ...[
                                Card(
                                  child: ListTile(
                                    title: Text(p.title),
                                    subtitle: Text(
                                      '${p.totalAmountIQD} ${context.l10n.currency} • '
                                      '${p.numberOfInstallments} ${context.l10n.installments}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.push('/plans/${p.id}'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    List<InstallmentPlan> plans,
    List<Installment> allItems,
  ) {
    final planIds = plans.map((plan) => plan.id).toSet();
    final itemList = allItems
        .where((item) => planIds.contains(item.planId))
        .toList();
    final totalDebt = plans.fold<int>(
      0,
      (sum, plan) => sum + plan.totalAmountIQD,
    );
    final remaining = itemList.fold<int>(
      0,
      (sum, item) => sum + item.remainingIQD,
    );
    final paid = itemList
        .where(
          (item) => item.statusAt(DateTime.now()) == InstallmentStatus.paid,
        )
        .length;
    final overdue = itemList
        .where(
          (item) => item.statusAt(DateTime.now()) == InstallmentStatus.overdue,
        )
        .length;
    final cards = [
      SummaryCard(
        label: context.l10n.totalDebt,
        value: '$totalDebt ${context.l10n.currency}',
        icon: Icons.account_balance_wallet_outlined,
      ),
      SummaryCard(
        label: context.l10n.totalInstallments,
        value: '${itemList.length}',
        icon: Icons.calendar_month_outlined,
      ),
      SummaryCard(
        label: context.l10n.paidInstallments,
        value: '$paid',
        icon: Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      SummaryCard(
        label: context.l10n.overdueInstallments,
        value: '$overdue',
        icon: Icons.warning_amber_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      SummaryCard(
        label: context.l10n.remainingAmount,
        value: '$remaining ${context.l10n.currency}',
        icon: Icons.trending_down,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 580
            ? 3
            : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth >= 580 ? 1.7 : 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      ),
    );
  }

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteCustomer),
        content: Text(context.l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deleteCustomer),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(repositoryProvider).deleteCustomer(customerId);
      ref
        ..invalidate(customerProvider(customerId))
        ..invalidate(customersProvider)
        ..invalidate(allPlansProvider)
        ..invalidate(allInstallmentsProvider)
        ..invalidate(allPaymentsProvider)
        ..invalidate(planProvider)
        ..invalidate(planInstallmentsProvider)
        ..invalidate(planPaymentsProvider)
        ..invalidate(receiptsProvider)
        ..invalidate(receiptProvider)
        ..invalidate(globalSearchProvider)
        ..invalidate(notificationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.customerDeleted)));
        context.go('/customers');
      }
    } on StateError {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cannotDeleteCustomer)),
        );
      }
    } on ArgumentError {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed)));
      }
    }
  }
}
