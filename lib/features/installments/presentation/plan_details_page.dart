import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../domain/entities/installment.dart';
import '../../../domain/entities/installment_plan.dart';
import '../../../domain/entities/payment.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../shared/widgets/summary_card.dart';

class PlanDetailsPage extends ConsumerWidget {
  const PlanDetailsPage({required this.planId, super.key});
  final String planId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider(planId));
    final installments = ref.watch(planInstallmentsProvider(planId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.installments),
        actions: [
          IconButton(
            tooltip: context.l10n.editPlan,
            onPressed: () => context.push('/plans/$planId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: context.l10n.deletePlan,
            onPressed: () => _deletePlan(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.saveFailed)),
        data: (p) => p == null
            ? const SizedBox.shrink()
            : installments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(context.l10n.saveFailed)),
                data: (items) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      p.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (p.notes.isNotEmpty) Text(p.notes),
                    const SizedBox(height: 20),
                    _summary(context, p, items),
                    const SizedBox(height: 24),
                    ...items.map(
                      (i) => Card(
                        child: ListTile(
                          title: Text(
                            '${context.l10n.installments} ${i.sequence}',
                          ),
                          subtitle: Text(
                            '${context.l10n.dueDate}: ${i.dueDate.toLocal().toString().split(' ').first}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${i.remainingIQD} ${context.l10n.currency}',
                              ),
                              _StatusChip(
                                label: _status(
                                  context,
                                  i.statusAt(DateTime.now()),
                                ),
                                status: i.statusAt(DateTime.now()),
                              ),
                            ],
                          ),
                          onTap: i.remainingIQD <= 0
                              ? null
                              : () => _payment(
                                  context,
                                  ref,
                                  p.id,
                                  p.customerId,
                                  i,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _deletePlan(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(context.l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deletePlan),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final customerId = ref.read(planProvider(planId)).valueOrNull?.customerId;
    try {
      await ref.read(repositoryProvider).deletePlan(planId);
      ref
        ..invalidate(planProvider(planId))
        ..invalidate(planInstallmentsProvider(planId))
        ..invalidate(allInstallmentsProvider)
        ..invalidate(allPlansProvider)
        ..invalidate(upcomingInstallmentsProvider)
        ..invalidate(allPaymentsProvider)
        ..invalidate(planPaymentsProvider(planId))
        ..invalidate(receiptsProvider)
        ..invalidate(receiptProvider)
        ..invalidate(globalSearchProvider)
        ..invalidate(notificationsProvider);
      if (customerId != null) {
        ref.invalidate(customerPlansProvider(customerId));
        ref.invalidate(customerProvider(customerId));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.planDeleted)));
        context.go('/installments');
      }
    } on StateError {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed)));
      }
    } on ArgumentError {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed)));
      }
    }
  }

  Widget _summary(
    BuildContext context,
    InstallmentPlan plan,
    List<Installment> items,
  ) {
    final paid = items
        .where(
          (item) => item.statusAt(DateTime.now()) == InstallmentStatus.paid,
        )
        .length;
    final overdue = items
        .where(
          (item) => item.statusAt(DateTime.now()) == InstallmentStatus.overdue,
        )
        .length;
    final remaining = items.fold<int>(
      0,
      (sum, item) => sum + item.remainingIQD,
    );
    final cards = [
      SummaryCard(
        label: context.l10n.totalDebt,
        value: '${plan.totalAmountIQD} ${context.l10n.currency}',
        icon: Icons.account_balance_wallet_outlined,
      ),
      SummaryCard(
        label: context.l10n.totalInstallments,
        value: '${items.length}',
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

  String _status(BuildContext c, InstallmentStatus status) => switch (status) {
    InstallmentStatus.paid => c.l10n.paid,
    InstallmentStatus.partiallyPaid => c.l10n.partiallyPaid,
    InstallmentStatus.overdue => c.l10n.overdue,
    InstallmentStatus.pending => c.l10n.pending,
    InstallmentStatus.completed => c.l10n.paid,
  };

  Future<void> _payment(
    BuildContext context,
    WidgetRef ref,
    String planId,
    String customerId,
    Installment installment,
  ) async {
    final amount = TextEditingController(
      text: installment.remainingIQD.toString(),
    );
    final note = TextEditingController();
    var method = PaymentMethod.cash;
    final value = await showDialog<_PaymentInput>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(context.l10n.recordPayment),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.paymentAmount,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: context.l10n.notes),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentMethod>(
                  value: method,
                  decoration: InputDecoration(
                    labelText: context.l10n.paymentMethod,
                  ),
                  items: [
                    for (final item in PaymentMethod.values)
                      DropdownMenuItem(
                        value: item,
                        child: Text(_methodName(context, item)),
                      ),
                  ],
                  onChanged: (item) {
                    if (item != null) setState(() => method = item);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _PaymentInput(int.tryParse(amount.text), method, note.text),
                ),
                child: Text(context.l10n.save),
              ),
            ],
          );
        },
      ),
    );
    amount.dispose();
    note.dispose();
    if (value == null || value.amount == null || value.amount! <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.invalidPayment)));
      }

      return;
    }
    try {
      await ref
          .read(repositoryProvider)
          .registerPayment(
            Payment(
              id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
              planId: planId,
              installmentId: installment.id,
              amountIQD: value.amount!,
              paidAt: DateTime.now(),
              paymentMethod: value.method,
              note: value.note,
              customerId: customerId,
            ),
          );
      ref.invalidate(planInstallmentsProvider(planId));
      ref.invalidate(planProvider(planId));
      ref.invalidate(allInstallmentsProvider);
      ref.invalidate(upcomingInstallmentsProvider);
      ref.invalidate(allPaymentsProvider);
      ref.invalidate(receiptsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.paymentSaved)));
      }
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message == 'Payment exceeds remaining balance'
                  ? context.l10n.paymentTooHigh
                  : context.l10n.invalidPayment,
            ),
          ),
        );
      }
    } on ArgumentError {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.invalidPayment)));
      }
    }
  }

  String _methodName(BuildContext context, PaymentMethod method) =>
      switch (method) {
        PaymentMethod.cash => context.l10n.cash,
        PaymentMethod.card => context.l10n.card,
        PaymentMethod.bankTransfer => context.l10n.bankTransfer,
        PaymentMethod.other => context.l10n.other,
      };
}

class _PaymentInput {
  const _PaymentInput(this.amount, this.method, this.note);
  final int? amount;
  final PaymentMethod method;
  final String note;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final InstallmentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      InstallmentStatus.paid => scheme.tertiary,
      InstallmentStatus.overdue => scheme.error,
      InstallmentStatus.partiallyPaid => scheme.secondary,
      InstallmentStatus.pending ||
      InstallmentStatus.completed => scheme.primary,
    };
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: .12),
      side: BorderSide.none,
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
