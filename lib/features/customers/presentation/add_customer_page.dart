import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/customer.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  const AddCustomerPage({
    this.customerId,
    this.continueToDebt = false,
    super.key,
  });

  final String? customerId;
  final bool continueToDebt;

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.customerId == null
        ? null
        : ref.watch(customerProvider(widget.customerId!));
    if (!_loaded && existing?.hasValue == true) {
      final customer = existing!.value;
      if (customer != null) {
        _name.text = customer.name;
        _phone.text = customer.phone;
        _address.text = customer.address;
        _notes.text = customer.notes;
      }
      _loaded = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerId == null
              ? context.l10n.addCustomer
              : context.l10n.editCustomer,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.customerName),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.customerName
                  : null,
            ),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: context.l10n.phone),
            ),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: context.l10n.address),
            ),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: context.l10n.notes),
              maxLines: 3,
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
                  : Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      final current = widget.customerId == null
          ? null
          : await ref.read(repositoryProvider).customer(widget.customerId!);
      final customer = Customer(
        id: current?.id ?? 'customer-${now.microsecondsSinceEpoch}',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(repositoryProvider).saveCustomer(customer);
      ref.invalidate(customersProvider);
      if (widget.customerId != null) {
        ref.invalidate(customerProvider(widget.customerId!));
      }
      if (mounted) {
        context.go(
          widget.continueToDebt
              ? '/add-debt/form?customerId=${customer.id}'
              : '/customers',
        );
      }
    } on StateError {
      _showSaveError();
    } on ArgumentError {
      _showSaveError();
    }
  }

  void _showSaveError() {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
  }
}
