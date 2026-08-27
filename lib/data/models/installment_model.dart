import '../../domain/entities/installment.dart';

final class InstallmentModel {
  const InstallmentModel({
    required this.customerName,
    required this.amount,
    required this.dueDate,
  });

  final String customerName;
  final num amount;
  final DateTime dueDate;

  Installment toEntity() => Installment(
    id: 'legacy-${dueDate.millisecondsSinceEpoch}',
    planId: 'legacy',
    sequence: 1,
    amountIQD: amount.toInt(),
    dueDate: dueDate,
    paidAmountIQD: 0,
    status: InstallmentStatus.pending,
  );
}
