import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/receipt.dart';
import '../services/receipt_file.dart';

class ReceiptDetailsPage extends ConsumerWidget {
  const ReceiptDetailsPage({required this.receiptId, super.key});
  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(receiptId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.receiptDetails),
        actions: [
          if (receipt.valueOrNull != null)
            IconButton(
              tooltip: context.l10n.savePdf,
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _saveReceipt(context, ref, receipt.valueOrNull!),
            ),
          if (receipt.valueOrNull != null)
            IconButton(
              tooltip: context.l10n.shareReceipt,
              icon: const Icon(Icons.share_outlined),
              onPressed: () =>
                  _shareReceipt(context, ref, receipt.valueOrNull!),
            ),
          if (receipt.valueOrNull != null)
            IconButton(
              tooltip: context.l10n.printReceipt,
              icon: const Icon(Icons.print_outlined),
              onPressed: () =>
                  _printReceipt(context, ref, receipt.valueOrNull!),
            ),
        ],
      ),
      body: receipt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (item) => item == null
            ? Center(child: Text(context.l10n.receiptNotFound))
            : _receiptBody(context, ref, item),
      ),
    );
  }

  Widget _receiptBody(BuildContext context, WidgetRef ref, Receipt item) {
    final plan = ref.watch(planProvider(item.planId)).valueOrNull;
    final customerId = item.customerId ?? plan?.customerId;
    final customer = customerId == null
        ? null
        : ref.watch(customerProvider(customerId)).valueOrNull;
    final installment = ref
        .watch(planInstallmentsProvider(item.planId))
        .valueOrNull
        ?.where((value) => value.id == item.installmentId)
        .firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  item.receiptNumber,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(height: 32),
                _detail(
                  context.l10n.amount,
                  '${item.amountIQD} ${context.l10n.currency}',
                ),
                if (customer != null)
                  _detail(context.l10n.customerName, customer.name),
                if (customer?.phone.isNotEmpty == true)
                  _detail(context.l10n.phone, customer!.phone),
                if (plan != null) _detail(context.l10n.planTitle, plan.title),
                if (installment != null)
                  _detail(
                    context.l10n.installment,
                    '${installment.sequence} • '
                    '${installment.remainingIQD} ${context.l10n.currency} '
                    '${context.l10n.remaining.toLowerCase()}',
                  ),
                if (plan != null)
                  _detail(
                    context.l10n.totalAmount,
                    '${plan.totalAmountIQD} ${context.l10n.currency}',
                  ),
                _detail(
                  context.l10n.paymentMethod,
                  _methodName(context, item.paymentMethod),
                ),
                _detail(
                  context.l10n.date,
                  item.issuedAt.toLocal().toString().split(' ').first,
                ),
                if (item.note.isNotEmpty)
                  _detail(context.l10n.notes, item.note),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  String _methodName(BuildContext context, PaymentMethod method) =>
      switch (method) {
        PaymentMethod.cash => context.l10n.cash,
        PaymentMethod.card => context.l10n.card,
        PaymentMethod.bankTransfer => context.l10n.bankTransfer,
        PaymentMethod.other => context.l10n.other,
      };

  Future<void> _printReceipt(
    BuildContext context,
    WidgetRef ref,
    Receipt receipt,
  ) async {
    final bytes = await _buildPdf(context, ref, receipt);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _shareReceipt(
    BuildContext context,
    WidgetRef ref,
    Receipt receipt,
  ) async {
    try {
      final bytes = await _buildPdf(context, ref, receipt);
      final shared = await Printing.sharePdf(
        bytes: bytes,
        filename: 'receipt-${receipt.receiptNumber}.pdf',
      );
      if (context.mounted && !shared) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pdfShareUnavailable)),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.pdfActionFailed)));
      }
    }
  }

  Future<void> _saveReceipt(
    BuildContext context,
    WidgetRef ref,
    Receipt receipt,
  ) async {
    try {
      final bytes = await _buildPdf(context, ref, receipt);
      final path = await saveReceiptPdf(
        bytes,
        'receipt-${receipt.receiptNumber}.pdf',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path == null
                  ? context.l10n.pdfSaveFallback
                  : '${context.l10n.pdfSaved}: $path',
            ),
          ),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.pdfActionFailed)));
      }
    }
  }

  Future<Uint8List> _buildPdf(
    BuildContext context,
    WidgetRef ref,
    Receipt receipt,
  ) async {
    final l10n = context.l10n;
    final paymentMethod = _methodName(context, receipt.paymentMethod);
    final repository = ref.read(repositoryProvider);
    final plan = await repository.plan(receipt.planId);
    final customerId = receipt.customerId ?? plan?.customerId;
    final customer = customerId == null
        ? null
        : await repository.customer(customerId);
    final installments = await repository.installments(planId: receipt.planId);
    final installment = installments
        .where((value) => value.id == receipt.installmentId)
        .firstOrNull;
    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(l10n.appName, style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('${l10n.receiptDetails}: ${receipt.receiptNumber}'),
            pw.Text('${l10n.date}: ${receipt.issuedAt.toLocal()}'),
            pw.Text('${l10n.amount}: ${receipt.amountIQD} ${l10n.currency}'),
            if (customer != null) ...[
              pw.Text('${l10n.customerName}: ${customer.name}'),
              if (customer.phone.isNotEmpty)
                pw.Text('${l10n.phone}: ${customer.phone}'),
            ],
            if (plan != null) pw.Text('${l10n.planTitle}: ${plan.title}'),
            if (installment != null) ...[
              pw.Text('${l10n.installment}: ${installment.sequence}'),
              pw.Text(
                '${l10n.remaining}: ${installment.remainingIQD} ${l10n.currency}',
              ),
            ],
            if (plan != null)
              pw.Text(
                '${l10n.totalAmount}: ${plan.totalAmountIQD} ${l10n.currency}',
              ),
            pw.Text('${l10n.paymentMethod}: $paymentMethod'),
            if (receipt.note.isNotEmpty)
              pw.Text('${l10n.notes}: ${receipt.note}'),
          ],
        ),
      ),
    );
    return document.save();
  }
}
