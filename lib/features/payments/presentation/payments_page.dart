import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/payment.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _search = TextEditingController();
  PaymentMethod? _method;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(allPaymentsProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.payments,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.searchPayments,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<PaymentMethod?>(
                  value: _method,
                  hint: Text(context.l10n.allMethods),
                  onChanged: (value) => setState(() => _method = value),
                  items: [
                    DropdownMenuItem<PaymentMethod?>(
                      value: null,
                      child: Text(context.l10n.allMethods),
                    ),
                    for (final method in PaymentMethod.values)
                      DropdownMenuItem(
                        value: method,
                        child: Text(_methodName(context, method)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: payments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) {
                  final query = _search.text.trim().toLowerCase();
                  final filtered = items.where((payment) {
                    final matchesMethod =
                        _method == null || payment.paymentMethod == _method;
                    final text =
                        '${payment.receiptNumber ?? ''} ${payment.note}'
                            .toLowerCase();
                    return matchesMethod &&
                        (query.isEmpty || text.contains(query));
                  }).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text(context.l10n.noPayments));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final payment = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.payments_outlined),
                          ),
                          title: Text(
                            payment.receiptNumber ??
                                '${context.l10n.payment} ${payment.id}',
                          ),
                          subtitle: Text(
                            '${_methodName(context, payment.paymentMethod)} • '
                            '${payment.paidAt.toLocal().toString().split(' ').first}',
                          ),
                          trailing: Text(
                            '${payment.amountIQD} ${context.l10n.currency}',
                          ),
                          onTap: payment.receiptId == null
                              ? null
                              : () => context.push(
                                  '/receipts/${payment.receiptId}',
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodName(BuildContext context, PaymentMethod method) =>
      switch (method) {
        PaymentMethod.cash => context.l10n.cash,
        PaymentMethod.card => context.l10n.card,
        PaymentMethod.bankTransfer => context.l10n.bankTransfer,
        PaymentMethod.other => context.l10n.other,
      };
}
