enum InstallmentStatus { pending, paid, overdue, partiallyPaid, completed }

class Installment {
  const Installment({
    required this.id,
    required this.planId,
    required this.sequence,
    required this.amountIQD,
    required this.dueDate,
    required this.paidAmountIQD,
    required this.status,
  });

  final String id;
  final String planId;
  final int sequence;
  final int amountIQD;
  final DateTime dueDate;
  final int paidAmountIQD;
  final InstallmentStatus status;

  int get remainingIQD => amountIQD - paidAmountIQD;
  InstallmentStatus statusAt(DateTime now) {
    if (paidAmountIQD >= amountIQD) return InstallmentStatus.paid;
    if (paidAmountIQD > 0) return InstallmentStatus.partiallyPaid;
    if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return InstallmentStatus.overdue;
    }
    return InstallmentStatus.pending;
  }
}
