import 'package:flutter_test/flutter_test.dart';
import 'package:qisti/core/database/database_service.dart';
import 'package:qisti/data/models/domain_models.dart';
import 'package:qisti/data/repositories/qisti_repository_impl.dart';
import 'package:qisti/domain/entities/customer.dart';
import 'package:qisti/domain/entities/installment.dart';
import 'package:qisti/domain/entities/installment_plan.dart';
import 'package:qisti/domain/entities/payment.dart';
import 'package:qisti/domain/entities/search_result.dart';

void main() {
  test('allocation keeps exact total and puts remainder last', () {
    expect(allocateInstallments(100, 3), [33, 33, 34]);
  });

  test(
    'repository CRUD creates installments and prevents overpayment',
    () async {
      final db = InMemoryDatabaseService()..open();
      final repository = QistiRepositoryImpl(db);
      final now = DateTime.now();
      await repository.saveCustomer(
        Customer(id: 'c', name: 'Test', createdAt: now, updatedAt: now),
      );
      expect((await repository.customers()).single.name, 'Test');
      final plan = InstallmentPlan(
        id: 'p',
        customerId: 'c',
        title: 'Plan',
        totalAmountIQD: 100,
        downPaymentIQD: 0,
        numberOfInstallments: 3,
        recurringPeriod: RecurringPeriod.monthly,
        startDate: now,
        status: PlanStatus.active,
        createdAt: now,
      );
      await repository.createPlan(plan);
      final installments = await repository.installments(planId: 'p');
      expect(installments.map((i) => i.amountIQD).toList(), [33, 33, 34]);
      await repository.registerPayment(
        Payment(
          id: 'pay',
          planId: 'p',
          installmentId: 'p-0',
          amountIQD: 33,
          paidAt: now,
        ),
      );
      expect(
        (await repository.installments(planId: 'p')).first.status,
        InstallmentStatus.paid,
      );
      await expectLater(
        repository.registerPayment(
          Payment(
            id: 'over',
            planId: 'p',
            installmentId: 'p-1',
            amountIQD: 34,
            paidAt: now,
          ),
        ),
        throwsStateError,
      );
    },
  );

  test('unpaid installment due in the past is overdue', () {
    final installment = Installment(
      id: 'i',
      planId: 'p',
      sequence: 1,
      amountIQD: 10,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      paidAmountIQD: 0,
      status: InstallmentStatus.pending,
    );
    expect(installment.statusAt(DateTime.now()), InstallmentStatus.overdue);
  });

  test(
    'atomic payment persists payment method and sequential receipt',
    () async {
      final db = InMemoryDatabaseService()..open();
      final repository = QistiRepositoryImpl(db);
      final now = DateTime.now();
      await db.saveInstallment(
        Installment(
          id: 'i',
          planId: 'p',
          sequence: 1,
          amountIQD: 100,
          dueDate: now,
          paidAmountIQD: 0,
          status: InstallmentStatus.pending,
        ),
      );
      final first = await repository.registerPaymentAtomic(
        Payment(
          id: 'payment-1',
          planId: 'p',
          installmentId: 'i',
          amountIQD: 40,
          paidAt: now,
          paymentMethod: PaymentMethod.card,
        ),
      );
      final second = await repository.registerPaymentAtomic(
        Payment(
          id: 'payment-2',
          planId: 'p',
          installmentId: 'i',
          amountIQD: 60,
          paidAt: now,
        ),
      );
      expect(first.receiptNumber, 'R-000001');
      expect(second.receiptNumber, 'R-000002');
      expect(
        (await repository.payments()).map((p) => p.paymentMethod),
        containsAll([PaymentMethod.cash, PaymentMethod.card]),
      );
      expect((await repository.receipts()).length, 2);
      expect((await repository.installments()).single.paidAmountIQD, 100);
    },
  );

  test('search indexes customers, plans, payments, and receipts', () async {
    final db = InMemoryDatabaseService()..open();
    final repository = QistiRepositoryImpl(db);
    final now = DateTime.now();
    await repository.saveCustomer(
      Customer(
        id: 'customer',
        name: 'Ava Search',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.createPlan(
      InstallmentPlan(
        id: 'plan',
        customerId: 'customer',
        title: 'Laptop',
        totalAmountIQD: 100,
        downPaymentIQD: 0,
        numberOfInstallments: 1,
        recurringPeriod: RecurringPeriod.monthly,
        startDate: now,
        status: PlanStatus.active,
        createdAt: now,
      ),
    );
    final installment = (await repository.installments(planId: 'plan')).single;
    final receipt = await repository.registerPaymentAtomic(
      Payment(
        id: 'payment',
        planId: 'plan',
        installmentId: installment.id,
        amountIQD: 100,
        paidAt: now,
        customerId: 'customer',
      ),
    );
    expect(
      (await repository.search('Ava')).single.type,
      SearchResultType.customer,
    );
    expect(
      (await repository.search('Laptop')).single.type,
      SearchResultType.plan,
    );
    expect((await repository.search(receipt.receiptNumber)).length, 2);
    expect(
      (await repository.notifications()).any(
        (item) => item.relatedId == 'payment',
      ),
      isTrue,
    );
  });
}
