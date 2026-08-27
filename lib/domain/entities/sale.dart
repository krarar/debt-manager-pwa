import 'payment.dart';

enum SaleType { cash, partial, installment }

class Sale {
  const Sale({
    required this.id,
    this.customerId,
    required this.subtotalIQD,
    this.discountIQD = 0,
    required this.totalIQD,
    this.paidAmountIQD = 0,
    required this.type,
    required this.createdAt,
    this.note = '',
    this.paymentMethod = PaymentMethod.cash,
    this.installmentPlanId,
  });

  final String id;
  final String? customerId;
  final int subtotalIQD;
  final int discountIQD;
  final int totalIQD;
  final int paidAmountIQD;
  final SaleType type;
  final DateTime createdAt;
  final String note;
  final PaymentMethod paymentMethod;
  final String? installmentPlanId;

  int get remainingIQD => totalIQD - paidAmountIQD;
  int get totalAmountIQD => totalIQD;
  int get paidIQD => paidAmountIQD;
  SaleType get paymentType => type;

  Sale copyWith({String? installmentPlanId}) => Sale(
    id: id,
    customerId: customerId,
    subtotalIQD: subtotalIQD,
    discountIQD: discountIQD,
    totalIQD: totalIQD,
    paidAmountIQD: paidAmountIQD,
    type: type,
    createdAt: createdAt,
    note: note,
    paymentMethod: paymentMethod,
    installmentPlanId: installmentPlanId ?? this.installmentPlanId,
  );
}
