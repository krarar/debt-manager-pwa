import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/services/report_service.dart';
import '../services/report_file.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final _search = TextEditingController();
  ReportKind _kind = ReportKind.financial;
  PaymentMethod? _method;
  String? _status;
  String? _customerId;
  ReportResult? _result;
  bool _working = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _working = true);
    final repository = ref.read(repositoryProvider);
    final customers = await repository.customers();
    final plans = await repository.plans();
    final installments = await repository.installments();
    final payments = await repository.payments();
    var result = const ReportService().filter(
      customers: customers,
      plans: plans,
      installments: installments,
      payments: payments,
      filter: ReportFilter(
        search: _search.text,
        customerId: _customerId,
        paymentMethod: _method,
        status: _status,
      ),
    );
    result = switch (_kind) {
      ReportKind.financial => result.copyWith(customers: const []),
      ReportKind.customers => result.copyWith(
        payments: const [],
        installments: const [],
      ),
      ReportKind.installments => result.copyWith(
        payments: const [],
        customers: const [],
      ),
    };
    setState(() {
      _result = result;
      _working = false;
    });
  }

  Future<void> _exportCsv() async {
    final result = _result;
    if (result == null) return;
    final bytes = Uint8List.fromList(
      const Utf8Encoder().convert(const ReportService().toCsv(result)),
    );
    final path = await saveReportFile(bytes, 'qisti-report.csv');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path ?? context.l10n.pdfSaveFallback)),
      );
    }
  }

  Future<void> _exportPdf() async {
    final result = _result;
    if (result == null) return;
    final bytes = await const ReportService().toPdf(
      result,
      context.l10n.reports,
      labels: ReportPdfLabels(
        payments: context.l10n.payments,
        installments: context.l10n.installments,
        customers: context.l10n.customers,
        payment: context.l10n.payment,
        installment: context.l10n.installment,
        type: switch (context.l10n.localeName) {
          'ar' => 'النوع',
          'ku' => 'جۆر',
          _ => 'Type',
        },
        id: 'ID',
        date: context.l10n.date,
        amount: context.l10n.amount,
        status: context.l10n.status,
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider('')).valueOrNull ?? const [];
    final isMobile = ResponsiveLayout.isMobile(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filterFields = [
            DropdownButtonFormField<ReportKind>(
              value: _kind,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) => setState(() => _kind = value!),
              items: [
                for (final kind in ReportKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(_reportKindLabel(context, kind)),
                  ),
              ],
            ),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: context.l10n.search,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            DropdownButtonFormField<String?>(
              value: _customerId,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: Text(context.l10n.customers),
              onChanged: (value) => setState(() => _customerId = value),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(context.l10n.all),
                ),
                ...customers.map(
                  (customer) => DropdownMenuItem<String?>(
                    value: customer.id,
                    child: Text(customer.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<PaymentMethod?>(
              value: _method,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: Text(context.l10n.paymentMethod),
              onChanged: (value) => setState(() => _method = value),
              items: [
                DropdownMenuItem<PaymentMethod?>(
                  value: null,
                  child: Text(context.l10n.allMethods),
                ),
                ...PaymentMethod.values.map(
                  (method) => DropdownMenuItem(
                    value: method,
                    child: Text(_paymentMethodLabel(context, method)),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String?>(
              value: _status,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: Text(context.l10n.status),
              onChanged: (value) => setState(() => _status = value),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(context.l10n.all),
                ),
                for (final value in [
                  'pending',
                  'partiallyPaid',
                  'paid',
                  'overdue',
                ])
                  DropdownMenuItem(
                    value: value,
                    child: Text(_statusLabel(context, value)),
                  ),
              ],
            ),
          ];

          final buttonBar = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _working ? null : _run,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.create),
              ),
              OutlinedButton.icon(
                onPressed: _result == null ? null : _exportCsv,
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('CSV'),
              ),
              OutlinedButton.icon(
                onPressed: _result == null ? null : _exportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
            ],
          );

          return SingleChildScrollView(
            padding: ResponsiveLayout.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.reports,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isMobile) ...[
                    for (final field in filterFields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(width: double.infinity, child: field),
                      ),
                    const SizedBox(height: 6),
                    buttonBar,
                  ] else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...filterFields.map(
                          (field) => ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 180,
                              maxWidth: 240,
                            ),
                            child: field,
                          ),
                        ),
                        buttonBar,
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (_result == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(context.l10n.searchPrompt),
                      ),
                    )
                  else if (isMobile)
                    _ReportCards(result: _result!)
                  else
                    SizedBox(
                      height: 420,
                      child: _ReportTable(result: _result!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _reportKindLabel(BuildContext context, ReportKind kind) {
    final locale = context.l10n.localeName;
    return switch (kind) {
      ReportKind.financial =>
        locale == 'ar'
            ? 'مالي'
            : locale == 'ku'
            ? 'دارایی'
            : 'Financial',
      ReportKind.customers => context.l10n.customers,
      ReportKind.installments => context.l10n.installments,
    };
  }

  String _paymentMethodLabel(BuildContext context, PaymentMethod method) =>
      switch (method) {
        PaymentMethod.cash => context.l10n.cash,
        PaymentMethod.card => context.l10n.card,
        PaymentMethod.bankTransfer => context.l10n.bankTransfer,
        PaymentMethod.other => context.l10n.other,
      };

  String _statusLabel(BuildContext context, String status) => switch (status) {
    'pending' => context.l10n.pending,
    'partiallyPaid' => context.l10n.partiallyPaid,
    'paid' => context.l10n.paid,
    'overdue' => context.l10n.overdue,
    _ => status,
  };
}

class _ReportCards extends StatelessWidget {
  const _ReportCards({required this.result});
  final ReportResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...result.payments.map(
        (payment) => _ReportCardItem(
          title: payment.receiptNumber ?? payment.id,
          subtitle: payment.paymentMethod.name,
          trailing: '${payment.amountIQD} ${context.l10n.currency}',
          meta: payment.paidAt.toLocal().toString().split(' ').first,
        ),
      ),
      ...result.installments.map(
        (installment) => _ReportCardItem(
          title: '${context.l10n.installments} ${installment.sequence}',
          subtitle: installment.status.name,
          trailing: '${installment.remainingIQD} ${context.l10n.currency}',
          meta: installment.dueDate.toLocal().toString().split(' ').first,
        ),
      ),
    ];

    if (items.isEmpty) {
      return Center(child: Text(context.l10n.noSearchResults));
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.meta,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        item.trailing,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportCardItem {
  const _ReportCardItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String meta;
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.result});
  final ReportResult result;
  @override
  Widget build(BuildContext context) {
    final rows = [
      ...result.payments.map(
        (p) => DataRow(
          cells: [
            DataCell(Text(p.receiptNumber ?? p.id)),
            DataCell(Text(p.amountIQD.toString())),
            DataCell(Text(p.paidAt.toLocal().toString().split(' ').first)),
            DataCell(Text(p.paymentMethod.name)),
          ],
        ),
      ),
      ...result.installments.map(
        (i) => DataRow(
          cells: [
            DataCell(Text(i.id)),
            DataCell(Text(i.remainingIQD.toString())),
            DataCell(Text(i.dueDate.toLocal().toString().split(' ').first)),
            DataCell(Text(i.status.name)),
          ],
        ),
      ),
    ];
    if (rows.isEmpty) return Center(child: Text(context.l10n.noSearchResults));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Expanded(child: Text('ID'))),
          DataColumn(label: Expanded(child: Text('IQD'))),
          DataColumn(label: Expanded(child: Text('Date'))),
          DataColumn(label: Expanded(child: Text('Status'))),
        ],
        rows: rows,
      ),
    );
  }
}
