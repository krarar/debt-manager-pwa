enum PlanStatus { active, completed, cancelled }

enum RecurringPeriod { weekly, biweekly, monthly }

class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.customerId,
    required this.title,
    required this.totalAmountIQD,
    required this.downPaymentIQD,
    required this.numberOfInstallments,
    required this.recurringPeriod,
    required this.startDate,
    required this.status,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final String customerId;
  final String title;
  final int totalAmountIQD;
  final int downPaymentIQD;
  final int numberOfInstallments;
  final RecurringPeriod recurringPeriod;
  final DateTime startDate;
  final PlanStatus status;
  final DateTime createdAt;
  final String notes;

  InstallmentPlan copyWith({String? title, String? notes}) => InstallmentPlan(
    id: id,
    customerId: customerId,
    title: title ?? this.title,
    totalAmountIQD: totalAmountIQD,
    downPaymentIQD: downPaymentIQD,
    numberOfInstallments: numberOfInstallments,
    recurringPeriod: recurringPeriod,
    startDate: startDate,
    status: status,
    createdAt: createdAt,
    notes: notes ?? this.notes,
  );
}
