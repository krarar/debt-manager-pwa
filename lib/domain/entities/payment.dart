enum PaymentMethod { cash, card, bankTransfer, other }

class Payment {
  const Payment({
    required this.id,
    required this.planId,
    required this.installmentId,
    required this.amountIQD,
    required this.paidAt,
    this.note = '',
    this.paymentMethod = PaymentMethod.cash,
    this.receiptId,
    this.receiptNumber,
    this.customerId,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) : paymentDate = paymentDate ?? paidAt,
       createdAt = createdAt ?? paidAt;

  final String id;
  final String planId;
  final String installmentId;
  final int amountIQD;
  final DateTime paidAt;
  final String note;
  final PaymentMethod paymentMethod;
  final String? receiptId;
  final String? receiptNumber;
  final String? customerId;
  final DateTime paymentDate;
  final DateTime createdAt;

  PaymentMethod get method => paymentMethod;
  String? get receiptNo => receiptNumber;
}
