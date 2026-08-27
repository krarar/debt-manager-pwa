import '../../core/database/database_service.dart';
import '../models/domain_models.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_return.dart';
import '../../domain/repositories/qisti_repository.dart';

final class QistiRepositoryImpl implements QistiRepository {
  const QistiRepositoryImpl(this.database);
  final DatabaseService database;
  @override
  Future<List<Customer>> customers({String query = ''}) =>
      database.getCustomers(query: query);
  @override
  Future<Customer?> customer(String id) => database.getCustomer(id);
  @override
  Future<void> saveCustomer(Customer c) => database.saveCustomer(c);
  @override
  Future<void> deleteCustomer(String id) => database.deleteCustomer(id);
  @override
  Future<List<InstallmentPlan>> plans({String? customerId}) =>
      database.getPlans(customerId: customerId);
  @override
  Future<InstallmentPlan?> plan(String id) => database.getPlan(id);
  @override
  Future<void> createPlan(InstallmentPlan p) async {
    final amounts = allocateInstallments(
      p.totalAmountIQD - p.downPaymentIQD,
      p.numberOfInstallments,
    );
    await database.savePlan(p);
    for (var i = 0; i < amounts.length; i++) {
      final due = _dueDate(p.startDate, p.recurringPeriod, i);
      await database.saveInstallment(
        Installment(
          id: '${p.id}-$i',
          planId: p.id,
          sequence: i + 1,
          amountIQD: amounts[i],
          dueDate: due,
          paidAmountIQD: 0,
          status: InstallmentStatus.pending,
        ),
      );
    }
  }

  @override
  Future<void> updatePlan(InstallmentPlan p) => database.savePlan(p);

  @override
  Future<void> deletePlan(String id) => database.deletePlan(id);
  @override
  Future<List<Installment>> installments({String? planId}) =>
      database.getInstallments(planId: planId);
  @override
  Future<List<Payment>> payments({String? planId}) =>
      database.getPayments(planId: planId);
  @override
  Future<List<Receipt>> receipts({String? paymentId}) =>
      database.getReceipts(paymentId: paymentId);
  @override
  Future<Receipt?> receipt(String id) => database.getReceipt(id);
  @override
  Future<List<SearchResult>> search(String query) => database.search(query);
  @override
  Future<List<AppNotification>> notifications({bool unreadOnly = false}) =>
      database.getNotifications(unreadOnly: unreadOnly);
  @override
  Future<void> saveNotification(AppNotification notification) =>
      database.saveNotification(notification);
  @override
  Future<void> markNotificationRead(String id) =>
      database.markNotificationRead(id);
  @override
  Future<void> markAllNotificationsRead() =>
      database.markAllNotificationsRead();
  @override
  Future<void> registerPayment(Payment p) => database.registerPayment(p);
  @override
  Future<Receipt> registerPaymentAtomic(Payment p) =>
      database.registerPaymentAtomic(p);

  @override
  Future<List<Category>> categories() => database.getCategories();

  @override
  Future<Category?> category(String id) => database.getCategory(id);

  @override
  Future<void> saveCategory(Category category) =>
      database.saveCategory(category);

  @override
  Future<void> deleteCategory(String id) => database.deleteCategory(id);

  @override
  Future<List<Product>> products({String query = '', String? categoryId}) =>
      database.getProducts(query: query, categoryId: categoryId);

  @override
  Future<Product?> product(String id) => database.getProduct(id);

  @override
  Future<void> saveProduct(Product product) => database.saveProduct(product);

  @override
  Future<void> deleteProduct(String id) => database.deleteProduct(id);

  @override
  Future<List<InventoryMovement>> inventoryMovements({String? productId}) =>
      database.getInventoryMovements(productId: productId);

  @override
  Future<void> recordInventoryMovement(InventoryMovement movement) =>
      database.saveInventoryMovement(movement);

  @override
  Future<List<Sale>> sales() => database.getSales();

  @override
  Future<Sale?> sale(String id) => database.getSale(id);

  @override
  Future<List<SaleItem>> saleItems(String saleId) =>
      database.getSaleItems(saleId);

  @override
  Future<Sale> createSale(
    Sale sale,
    List<SaleItem> items, {
    int installmentCount = 1,
    RecurringPeriod recurringPeriod = RecurringPeriod.monthly,
    DateTime? installmentStartDate,
  }) async {
    final itemTotal = items.fold<int>(0, (sum, item) => sum + item.totalIQD);
    if (items.isEmpty ||
        items.any(
          (item) => item.totalIQD != item.quantity * item.unitPriceIQD,
        ) ||
        sale.totalIQD != itemTotal - sale.discountIQD ||
        sale.discountIQD < 0 ||
        sale.discountIQD > itemTotal) {
      throw ArgumentError('Sale total does not match items');
    }
    switch (sale.type) {
      case SaleType.cash:
        if (sale.paidAmountIQD != sale.totalIQD) {
          throw ArgumentError('Cash sale must be paid in full');
        }
      case SaleType.partial:
        if (sale.paidAmountIQD <= 0 || sale.paidAmountIQD >= sale.totalIQD) {
          throw ArgumentError('Partial sale payment is invalid');
        }
      case SaleType.installment:
        if (sale.customerId == null ||
            sale.paidAmountIQD < 0 ||
            sale.paidAmountIQD >= sale.totalIQD ||
            installmentCount <= 0) {
          throw ArgumentError('Installment sale details are invalid');
        }
    }
    Sale storedSale = sale;
    String? planId;
    try {
      if (sale.type == SaleType.installment) {
        planId = 'sale-plan-${sale.id}';
        storedSale = sale.copyWith(installmentPlanId: planId);
      }
      await database.createSaleAtomic(storedSale, items);
      if (planId != null) {
        final now = installmentStartDate ?? sale.createdAt;
        await createPlan(
          InstallmentPlan(
            id: planId,
            customerId: sale.customerId!,
            title: 'Sale ${sale.id}',
            totalAmountIQD: sale.totalIQD,
            downPaymentIQD: 0,
            numberOfInstallments: installmentCount,
            recurringPeriod: recurringPeriod,
            startDate: now,
            status: PlanStatus.active,
            createdAt: sale.createdAt,
          ),
        );
        await _allocateSalePayment(storedSale, planId);
      }
      return storedSale;
    } catch (error) {
      if (planId != null) {
        await database.deletePlan(planId);
      }
      await database.deleteSale(sale.id);
      rethrow;
    }
  }

  Future<void> _allocateSalePayment(Sale sale, String planId) async {
    var remaining = sale.paidAmountIQD;
    if (remaining <= 0) return;
    final installments = await database.getInstallments(planId: planId);
    for (final installment in installments) {
      if (remaining <= 0) break;
      final amount = remaining < installment.amountIQD
          ? remaining
          : installment.amountIQD;
      await database.registerPaymentAtomic(
        Payment(
          id: '${sale.id}-payment-${installment.sequence}',
          planId: planId,
          installmentId: installment.id,
          amountIQD: amount,
          paidAt: sale.createdAt,
          paymentMethod: sale.paymentMethod,
          customerId: sale.customerId,
          note: sale.note,
        ),
      );
      remaining -= amount;
    }
    if (remaining != 0) throw StateError('Could not allocate sale payment');
  }

  @override
  Future<List<SaleReturn>> returns({String? saleId}) =>
      database.getReturns(saleId: saleId);

  @override
  Future<void> registerReturn(SaleReturn saleReturn) =>
      database.registerReturnAtomic(saleReturn);
}

DateTime _dueDate(DateTime start, RecurringPeriod period, int index) =>
    switch (period) {
      RecurringPeriod.weekly => start.add(Duration(days: 7 * index)),
      RecurringPeriod.biweekly => start.add(Duration(days: 14 * index)),
      RecurringPeriod.monthly => _monthlyDueDate(start, index),
    };

DateTime _monthlyDueDate(DateTime start, int index) {
  final month = DateTime(start.year, start.month + index, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(
    month.year,
    month.month,
    start.day > lastDay ? lastDay : start.day,
  );
}
