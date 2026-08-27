import 'payment.dart';

/// An immutable, printable record of a payment.
class Receipt {
  const Receipt({
    required this.id,
    required this.paymentId,
    required this.receiptNumber,
    required this.issuedAt,
    required this.amountIQD,
    required this.paymentMethod,
    required this.planId,
    required this.installmentId,
    this.note = '',
    this.customerId,
  });

  final String id;
  final String paymentId;
  final String receiptNumber;
  final DateTime issuedAt;
  final int amountIQD;
  final PaymentMethod paymentMethod;
  final String planId;
  final String installmentId;
  final String note;
  final String? customerId;

  /// Short alias useful to callers that refer to the number as `number`.
  String get number => receiptNumber;
  DateTime get createdAt => issuedAt;

  /// Numeric portion of the persistent receipt sequence, when available.
  int get sequence =>
      int.tryParse(receiptNumber.replaceFirst(RegExp(r'^[A-Za-z-]+'), '')) ?? 0;
}
