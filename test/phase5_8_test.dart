import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qisti/core/database/database_service.dart';
import 'package:qisti/core/services/backup_service.dart';
import 'package:qisti/data/repositories/qisti_repository_impl.dart';
import 'package:qisti/domain/entities/customer.dart';
import 'package:qisti/domain/entities/installment.dart';
import 'package:qisti/domain/entities/installment_plan.dart';
import 'package:qisti/domain/entities/app_notification.dart';
import 'package:qisti/domain/services/financial_calculation_service.dart';
import 'package:qisti/domain/services/report_service.dart';

void main() {
  test('financial calculations are centralized and use integer IQD values', () {
    final now = DateTime(2026, 8, 27);
    final summary = const FinancialCalculationService().summarize(
      customers: [
        Customer(id: 'c', name: 'Customer', createdAt: now, updatedAt: now),
      ],
      plans: [
        InstallmentPlan(
          id: 'p',
          customerId: 'c',
          title: 'Plan',
          totalAmountIQD: 100,
          downPaymentIQD: 0,
          numberOfInstallments: 2,
          recurringPeriod: RecurringPeriod.monthly,
          startDate: now,
          status: PlanStatus.active,
          createdAt: now,
        ),
      ],
      installments: [
        Installment(
          id: 'i',
          planId: 'p',
          sequence: 1,
          amountIQD: 50,
          dueDate: now,
          paidAmountIQD: 0,
          status: InstallmentStatus.pending,
        ),
      ],
      payments: const [],
      now: now,
    );
    expect(summary.totalDebtIQD, 100);
    expect(summary.todayDueIQD, 50);
    expect(summary.dueTodayCount, 1);
  });

  test('reports generate escaped CSV and a real PDF document', () async {
    final result = ReportResult(
      payments: const [],
      installments: const [],
      customers: [
        Customer(
          id: 'c',
          name: 'A, Customer',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
    );
    expect(const ReportService().toCsv(result), contains('\uFEFF'));
    final pdf = await const ReportService().toPdf(result, 'Qisti');
    expect(pdf.take(5).toList(), [37, 80, 68, 70, 45]);
  });

  test('backup round-trips records and notifications are idempotent', () async {
    final source = InMemoryDatabaseService()..open();
    final repository = QistiRepositoryImpl(source);
    final now = DateTime(2026);
    await repository.saveCustomer(
      Customer(id: 'c', name: 'Customer', createdAt: now, updatedAt: now),
    );
    await repository.saveNotification(
      AppNotification(
        id: 'n',
        type: NotificationType.system,
        relatedId: 'system',
        createdAt: now,
      ),
    );
    final bytes = await BackupService(source).exportBytes();
    expect(jsonDecode(utf8.decode(bytes))['format'], 'qisti-backup');
    final restored = InMemoryDatabaseService()..open();
    await BackupService(restored).restoreBytes(bytes);
    expect((await restored.getCustomers()).single.name, 'Customer');
    expect(
      (await restored.getNotifications()).where((item) => item.id == 'n'),
      hasLength(1),
    );
  });
}
