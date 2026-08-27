import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/installment.dart';
import '../../../domain/entities/installment_plan.dart';

enum _InstallmentFilter { all, pending, partiallyPaid, overdue, paid, dueToday }

class InstallmentsPage extends ConsumerStatefulWidget {
  const InstallmentsPage({super.key});

  @override
  ConsumerState<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends ConsumerState<InstallmentsPage> {
  _InstallmentFilter _filter = _InstallmentFilter.all;

  @override
  Widget build(BuildContext context) {
    final installments = ref.watch(allInstallmentsProvider);
    final customers = ref.watch(customersProvider(''));
    final plans = ref.watch(allPlansProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.installments,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(context, _InstallmentFilter.all, context.l10n.all),
                  _chip(
                    context,
                    _InstallmentFilter.pending,
                    context.l10n.pending,
                  ),
                  _chip(
                    context,
                    _InstallmentFilter.partiallyPaid,
                    context.l10n.partiallyPaid,
                  ),
                  _chip(
                    context,
                    _InstallmentFilter.overdue,
                    context.l10n.overdue,
                  ),
                  _chip(context, _InstallmentFilter.paid, context.l10n.paid),
                  _chip(
                    context,
                    _InstallmentFilter.dueToday,
                    context.l10n.dueToday,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: installments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text(context.l10n.saveFailed)),
                data: (items) => plans.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(context.l10n.saveFailed)),
                  data: (planItems) => customers.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) =>
                        Center(child: Text(context.l10n.saveFailed)),
                    data: (customerItems) => _buildCustomers(
                      context,
                      items,
                      planItems,
                      customerItems,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomers(
    BuildContext context,
    List<Installment> items,
    List<InstallmentPlan> plans,
    List<Customer> customers,
  ) {
    final customerById = {
      for (final customer in customers) customer.id: customer,
    };
    final planCustomer = {for (final plan in plans) plan.id: plan.customerId};
    final grouped = <String, List<Installment>>{};
    for (final item in items) {
      final customerId = planCustomer[item.planId];
      if (customerId == null || !_matches(item)) continue;
      grouped.putIfAbsent(customerId, () => []).add(item);
    }
    final entries =
        grouped.entries
            .where((entry) => customerById.containsKey(entry.key))
            .toList()
          ..sort(
            (a, b) => customerById[a.key]!.name.toLowerCase().compareTo(
              customerById[b.key]!.name.toLowerCase(),
            ),
          );
    if (entries.isEmpty) return Center(child: Text(context.l10n.noPlans));
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final customer = customerById[entries[index].key]!;
        final customerItems = entries[index].value;
        final remaining = customerItems.fold<int>(
          0,
          (sum, item) => sum + item.remainingIQD,
        );
        final overdue = customerItems
            .where(
              (item) =>
                  item.statusAt(DateTime.now()) == InstallmentStatus.overdue,
            )
            .length;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Text(
                customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
              ),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('${customerItems.length} ${context.l10n.installments}'),
                  Text(
                    '${context.l10n.remaining}: $remaining ${context.l10n.currency}',
                  ),
                  Text(
                    '$overdue ${context.l10n.overdue}',
                    style: TextStyle(
                      color: overdue > 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/customers/${customer.id}'),
          ),
        );
      },
    );
  }

  FilterChip _chip(
    BuildContext context,
    _InstallmentFilter filter,
    String label,
  ) => FilterChip(
    label: Text(label),
    selected: _filter == filter,
    onSelected: (_) => setState(() => _filter = filter),
  );

  bool _matches(Installment item) {
    final status = item.statusAt(DateTime.now());
    return switch (_filter) {
      _InstallmentFilter.all => true,
      _InstallmentFilter.pending => status == InstallmentStatus.pending,
      _InstallmentFilter.partiallyPaid =>
        status == InstallmentStatus.partiallyPaid,
      _InstallmentFilter.overdue => status == InstallmentStatus.overdue,
      _InstallmentFilter.paid => status == InstallmentStatus.paid,
      _InstallmentFilter.dueToday =>
        _sameDay(item.dueDate, DateTime.now()) && item.remainingIQD > 0,
    };
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
