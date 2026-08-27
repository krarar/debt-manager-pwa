import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../domain/entities/installment_plan.dart';
import '../../../core/localization/app_localizations_extension.dart';

class AddPlanPage extends ConsumerStatefulWidget {
  const AddPlanPage({required this.customerId, super.key});
  final String customerId;
  @override
  ConsumerState<AddPlanPage> createState() => _AddPlanPageState();
}

class _AddPlanPageState extends ConsumerState<AddPlanPage> {
  final title = TextEditingController(),
      total = TextEditingController(),
      down = TextEditingController(),
      count = TextEditingController(text: '1');
  RecurringPeriod period = RecurringPeriod.monthly;
  bool saving = false;
  String? validationError;
  @override
  void dispose() {
    title.dispose();
    total.dispose();
    down.dispose();
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.addPlan)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: title,
          decoration: InputDecoration(labelText: context.l10n.planTitle),
        ),
        TextField(
          controller: total,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.totalAmount),
        ),
        TextField(
          controller: down,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.downPayment),
        ),
        TextField(
          controller: count,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.installmentCount),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<RecurringPeriod>(
          value: period,
          decoration: InputDecoration(labelText: context.l10n.period),
          items: [
            DropdownMenuItem(
              value: RecurringPeriod.weekly,
              child: Text(context.l10n.weekly),
            ),
            DropdownMenuItem(
              value: RecurringPeriod.biweekly,
              child: Text(context.l10n.biweekly),
            ),
            DropdownMenuItem(
              value: RecurringPeriod.monthly,
              child: Text(context.l10n.monthly),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => period = v);
          },
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : Text(context.l10n.create),
        ),
        if (validationError != null) ...[
          const SizedBox(height: 12),
          Text(
            validationError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );
  Future<void> _save() async {
    final amount = int.tryParse(total.text.trim()),
        initial = int.tryParse(down.text.trim()) ?? 0,
        number = int.tryParse(count.text.trim());
    if (title.text.trim().isEmpty ||
        amount == null ||
        number == null ||
        amount <= 0 ||
        initial < 0 ||
        initial >= amount ||
        number <= 0) {
      setState(() => validationError = context.l10n.invalidPlan);
      return;
    }
    setState(() {
      saving = true;
      validationError = null;
    });
    final now = DateTime.now();
    final plan = InstallmentPlan(
      id: 'plan-${now.microsecondsSinceEpoch}',
      customerId: widget.customerId,
      title: title.text.trim(),
      totalAmountIQD: amount,
      downPaymentIQD: initial,
      numberOfInstallments: number,
      recurringPeriod: period,
      startDate: now,
      status: PlanStatus.active,
      createdAt: now,
    );
    try {
      await ref.read(repositoryProvider).createPlan(plan);
      ref.invalidate(customerPlansProvider(widget.customerId));
      ref.invalidate(allPlansProvider);
      ref.invalidate(allInstallmentsProvider);
      ref.invalidate(upcomingInstallmentsProvider);
      if (mounted) context.go('/plans/${plan.id}');
    } on StateError {
      if (mounted) {
        setState(() {
          saving = false;
          validationError = context.l10n.invalidPlan;
        });
      }
    } on ArgumentError {
      if (mounted) {
        setState(() {
          saving = false;
          validationError = context.l10n.invalidPlan;
        });
      }
    }
  }
}
