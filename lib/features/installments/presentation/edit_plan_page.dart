import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/installment_plan.dart';

class EditPlanPage extends ConsumerStatefulWidget {
  const EditPlanPage({required this.planId, super.key});

  final String planId;

  @override
  ConsumerState<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends ConsumerState<EditPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider(widget.planId));
    if (!_loaded && plan.hasValue && plan.value != null) {
      _title.text = plan.value!.title;
      _notes.text = plan.value!.notes;
      _loaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editPlan)),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(context.l10n.saveFailed)),
        data: (item) => item == null
            ? const SizedBox.shrink()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: InputDecoration(
                        labelText: context.l10n.planTitle,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? context.l10n.planTitle
                          : null,
                    ),
                    TextFormField(
                      controller: _notes,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.l10n.notes,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : () => _save(item),
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
      ),
    );
  }

  Future<void> _save(InstallmentPlan plan) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .updatePlan(
            plan.copyWith(title: _title.text.trim(), notes: _notes.text.trim()),
          );
      ref.invalidate(planProvider(widget.planId));
      ref.invalidate(customerPlansProvider(plan.customerId));
      ref.invalidate(allPlansProvider);
      if (mounted) context.go('/plans/${widget.planId}');
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
