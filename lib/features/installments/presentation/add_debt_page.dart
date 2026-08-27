import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/installment_plan.dart';

class AddDebtPage extends ConsumerStatefulWidget {
  const AddDebtPage({this.customerId, super.key});

  final String? customerId;

  @override
  ConsumerState<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends ConsumerState<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _total = TextEditingController();
  final _down = TextEditingController(text: '0');
  final _count = TextEditingController(text: '1');
  final _notes = TextEditingController();
  Customer? _customer;
  RecurringPeriod _period = RecurringPeriod.monthly;
  DateTime _firstDueDate = DateTime.now();
  bool _saving = false;
  bool _customerLoaded = false;

  @override
  void dispose() {
    _product.dispose();
    _total.dispose();
    _down.dispose();
    _count.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider(''));
    if (!_customerLoaded && customers.hasValue) {
      final customerId = widget.customerId;
      if (customerId != null) {
        for (final item in customers.value!) {
          if (item.id == customerId) {
            _customer = item;
            break;
          }
        }
      }
      _customerLoaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addDebt)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            customers.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(context.l10n.saveFailed),
              data: (items) => DropdownButtonFormField<Customer>(
                value: _customer,
                decoration: InputDecoration(
                  labelText: context.l10n.customerName,
                ),
                items: [
                  for (final item in items)
                    DropdownMenuItem(value: item, child: Text(item.name)),
                ],
                onChanged: (value) => setState(() => _customer = value),
                validator: (value) =>
                    value == null ? context.l10n.customerName : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _product,
              decoration: InputDecoration(labelText: context.l10n.productName),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.productName
                  : null,
            ),
            TextFormField(
              controller: _total,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.l10n.totalAmount),
              validator: _positiveInteger,
            ),
            TextFormField(
              controller: _down,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.l10n.downPayment),
              validator: _nonNegativeInteger,
            ),
            TextFormField(
              controller: _count,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.installmentCount,
              ),
              validator: _positiveInteger,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecurringPeriod>(
              value: _period,
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
              onChanged: (value) {
                if (value != null) setState(() => _period = value);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.firstDueDate),
              subtitle: Text(_formatDate(_firstDueDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.l10n.notes),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    )
                  : Text(context.l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  String? _positiveInteger(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? context.l10n.invalidPlan : null;
  }

  String? _nonNegativeInteger(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? context.l10n.invalidPlan : null;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _firstDueDate,
    );
    if (picked != null) setState(() => _firstDueDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = int.parse(_total.text.trim());
    final downPayment = int.parse(_down.text.trim());
    if (downPayment >= amount) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidPlan)));
      return;
    }
    final number = int.parse(_count.text.trim());
    setState(() => _saving = true);
    final now = DateTime.now();
    final plan = InstallmentPlan(
      id: 'plan-${now.microsecondsSinceEpoch}',
      customerId: _customer!.id,
      title: _product.text.trim(),
      totalAmountIQD: amount,
      downPaymentIQD: downPayment,
      numberOfInstallments: number,
      recurringPeriod: _period,
      startDate: _firstDueDate,
      status: PlanStatus.active,
      createdAt: now,
      notes: _notes.text.trim(),
    );
    try {
      await ref.read(repositoryProvider).createPlan(plan);
      ref.invalidate(customersProvider);
      ref.invalidate(customerPlansProvider(plan.customerId));
      ref.invalidate(allPlansProvider);
      ref.invalidate(allInstallmentsProvider);
      if (mounted) context.go('/plans/${plan.id}');
    } on StateError {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.invalidPlan)));
      }
    } on ArgumentError {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.invalidPlan)));
      }
    }
  }
}
