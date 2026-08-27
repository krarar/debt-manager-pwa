import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../entities/customer.dart';
import '../entities/installment.dart';
import '../entities/installment_plan.dart';
import '../entities/payment.dart';

enum ReportKind { financial, customers, installments }

class ReportFilter {
  const ReportFilter({
    this.from,
    this.to,
    this.customerId,
    this.status,
    this.paymentMethod,
    this.planId,
    this.search = '',
  });
  final DateTime? from;
  final DateTime? to;
  final String? customerId;
  final String? status;
  final PaymentMethod? paymentMethod;
  final String? planId;
  final String search;
}

class ReportResult {
  const ReportResult({
    required this.payments,
    required this.installments,
    required this.customers,
  });
  final List<Payment> payments;
  final List<Installment> installments;
  final List<Customer> customers;

  ReportResult copyWith({
    List<Payment>? payments,
    List<Installment>? installments,
    List<Customer>? customers,
  }) => ReportResult(
    payments: payments ?? this.payments,
    installments: installments ?? this.installments,
    customers: customers ?? this.customers,
  );
}

class ReportPdfLabels {
  const ReportPdfLabels({
    required this.payments,
    required this.installments,
    required this.customers,
    required this.payment,
    required this.installment,
    required this.type,
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String payments;
  final String installments;
  final String customers;
  final String payment;
  final String installment;
  final String type;
  final String id;
  final String date;
  final String amount;
  final String status;
}

class ReportService {
  const ReportService();

  ReportResult filter({
    required Iterable<Customer> customers,
    required Iterable<InstallmentPlan> plans,
    required Iterable<Installment> installments,
    required Iterable<Payment> payments,
    required ReportFilter filter,
    DateTime? now,
  }) {
    final query = filter.search.trim().toLowerCase();
    bool inRange(DateTime date) =>
        (filter.from == null || !date.isBefore(filter.from!)) &&
        (filter.to == null || !date.isAfter(filter.to!));
    final planById = <String, InstallmentPlan>{
      for (final plan in plans) plan.id: plan,
    };
    final planIds = filter.planId == null ? null : <String>{filter.planId!};
    final customerIds = filter.customerId == null
        ? null
        : <String>{filter.customerId!};
    final filteredPayments = payments.where((payment) {
      return inRange(payment.paidAt) &&
          (planIds == null || planIds.contains(payment.planId)) &&
          (customerIds == null || customerIds.contains(payment.customerId)) &&
          (filter.paymentMethod == null ||
              payment.paymentMethod == filter.paymentMethod) &&
          (query.isEmpty ||
              payment.id.toLowerCase().contains(query) ||
              (payment.receiptNumber ?? '').toLowerCase().contains(query));
    }).toList()..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    final filteredInstallments = installments.where((item) {
      final plan = planById[item.planId];
      if (plan == null) return false;
      final status = item.statusAt(now ?? DateTime.now()).name;
      return inRange(item.dueDate) &&
          (planIds == null || planIds.contains(item.planId)) &&
          (customerIds == null || customerIds.contains(plan.customerId)) &&
          (filter.status == null || filter.status == status) &&
          (query.isEmpty ||
              item.id.toLowerCase().contains(query) ||
              plan.title.toLowerCase().contains(query));
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final filteredCustomers = customers.where((customer) {
      return (customerIds == null || customerIds.contains(customer.id)) &&
          (query.isEmpty ||
              customer.name.toLowerCase().contains(query) ||
              customer.phone.toLowerCase().contains(query));
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return ReportResult(
      payments: filteredPayments,
      installments: filteredInstallments,
      customers: filteredCustomers,
    );
  }

  String toCsv(ReportResult result) {
    final rows = <List<Object?>>[
      ['type', 'id', 'date', 'amount_iqd', 'status', 'payment_method'],
      ...result.payments.map(
        (payment) => [
          'payment',
          payment.id,
          payment.paidAt.toIso8601String(),
          payment.amountIQD,
          '',
          payment.paymentMethod.name,
        ],
      ),
      ...result.installments.map(
        (item) => [
          'installment',
          item.id,
          item.dueDate.toIso8601String(),
          item.remainingIQD,
          item.status.name,
          '',
        ],
      ),
    ];
    return '\uFEFF${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}\r\n';
  }

  Future<Uint8List> toPdf(
    ReportResult result,
    String title, {
    ReportPdfLabels? labels,
  }) async {
    final pdfLabels =
        labels ??
        const ReportPdfLabels(
          payments: 'Payments',
          installments: 'Installments',
          customers: 'Customers',
          payment: 'Payment',
          installment: 'Installment',
          type: 'Type',
          id: 'Id',
          date: 'Date',
          amount: 'Amount IQD',
          status: 'Status',
        );
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, text: title),
          pw.Text('${pdfLabels.payments}: ${result.payments.length}'),
          pw.Text('${pdfLabels.installments}: ${result.installments.length}'),
          pw.Text('${pdfLabels.customers}: ${result.customers.length}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              pdfLabels.type,
              pdfLabels.id,
              pdfLabels.date,
              pdfLabels.amount,
              pdfLabels.status,
            ],
            data: [
              ...result.payments.map(
                (p) => [
                  pdfLabels.payment,
                  p.receiptNumber ?? p.id,
                  p.paidAt.toIso8601String().split('T').first,
                  '${p.amountIQD}',
                  '',
                ],
              ),
              ...result.installments.map(
                (i) => [
                  pdfLabels.installment,
                  i.id,
                  i.dueDate.toIso8601String().split('T').first,
                  '${i.remainingIQD}',
                  i.status.name,
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return document.save();
  }

  String _escape(Object? value) {
    final text = '$value';
    return text.contains(RegExp(r'[,\"\r\n]'))
        ? '"${text.replaceAll('"', '""')}"'
        : text;
  }
}
