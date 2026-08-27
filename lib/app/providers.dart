import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../data/repositories/qisti_repository_impl.dart';
import '../domain/entities/customer.dart';
import '../domain/entities/installment.dart';
import '../domain/entities/installment_plan.dart';
import '../domain/entities/payment.dart';
import '../domain/entities/receipt.dart';
import '../domain/entities/app_notification.dart';
import '../domain/entities/search_result.dart';
import '../domain/entities/category.dart';
import '../domain/entities/product.dart';
import '../domain/entities/inventory_movement.dart';
import '../domain/entities/sale.dart';
import '../domain/entities/sale_item.dart';
import '../domain/repositories/qisti_repository.dart';
import '../domain/services/financial_calculation_service.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  final database = HiveDatabaseService();
  database.open();
  ref.onDispose(database.close);
  return database;
});
final repositoryProvider = Provider<QistiRepository>(
  (ref) => QistiRepositoryImpl(ref.watch(databaseProvider)),
);

final customersProvider = FutureProvider.autoDispose
    .family<List<Customer>, String>(
      (ref, query) => ref.watch(repositoryProvider).customers(query: query),
    );
final customerProvider = FutureProvider.autoDispose.family<Customer?, String>(
  (ref, id) => ref.watch(repositoryProvider).customer(id),
);
final customerPlansProvider = FutureProvider.autoDispose
    .family<List<InstallmentPlan>, String>(
      (ref, id) => ref.watch(repositoryProvider).plans(customerId: id),
    );
final allPlansProvider = FutureProvider.autoDispose<List<InstallmentPlan>>(
  (ref) => ref.watch(repositoryProvider).plans(),
);
final planProvider = FutureProvider.autoDispose
    .family<InstallmentPlan?, String>(
      (ref, id) => ref.watch(repositoryProvider).plan(id),
    );
final planInstallmentsProvider = FutureProvider.autoDispose
    .family<List<Installment>, String>(
      (ref, id) => ref.watch(repositoryProvider).installments(planId: id),
    );
final planPaymentsProvider = FutureProvider.autoDispose
    .family<List<Payment>, String>(
      (ref, id) => ref.watch(repositoryProvider).payments(planId: id),
    );
final allInstallmentsProvider = FutureProvider.autoDispose<List<Installment>>(
  (ref) => ref.watch(repositoryProvider).installments(),
);
final allPaymentsProvider = FutureProvider.autoDispose<List<Payment>>(
  (ref) => ref.watch(repositoryProvider).payments(),
);
final receiptsProvider = FutureProvider.autoDispose<List<Receipt>>(
  (ref) => ref.watch(repositoryProvider).receipts(),
);
final receiptProvider = FutureProvider.autoDispose.family<Receipt?, String>(
  (ref, id) => ref.watch(repositoryProvider).receipt(id),
);
final globalSearchProvider = FutureProvider.autoDispose
    .family<List<SearchResult>, String>(
      (ref, query) => ref.watch(repositoryProvider).search(query),
    );
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.watch(repositoryProvider).notifications(),
);
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final items = await ref
      .watch(repositoryProvider)
      .notifications(unreadOnly: true);
  return items.length;
});
final upcomingInstallmentsProvider =
    FutureProvider.autoDispose<List<Installment>>(
      (ref) async => (await ref.watch(repositoryProvider).installments())
          .where((item) => item.remainingIQD > 0)
          .toList(),
    );

final financialCalculationServiceProvider =
    Provider<FinancialCalculationService>(
      (ref) => const FinancialCalculationService(),
    );

final financialSummaryProvider = FutureProvider<FinancialSummary>((ref) async {
  final repository = ref.watch(repositoryProvider);
  final customers = await repository.customers();
  final plans = await repository.plans();
  final installments = await repository.installments();
  final payments = await repository.payments();
  final sales = await repository.sales();
  final products = await repository.products();
  return ref
      .read(financialCalculationServiceProvider)
      .summarize(
        customers: customers,
        plans: plans,
        installments: installments,
        payments: payments,
        sales: sales,
        products: products,
      );
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(repositoryProvider).categories(),
);
final productsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>(
      (ref, query) => ref.watch(repositoryProvider).products(query: query),
    );
final productProvider = FutureProvider.autoDispose.family<Product?, String>(
  (ref, id) => ref.watch(repositoryProvider).product(id),
);
final inventoryMovementsProvider = FutureProvider.autoDispose
    .family<List<InventoryMovement>, String?>(
      (ref, productId) => ref
          .watch(repositoryProvider)
          .inventoryMovements(productId: productId),
    );
final salesProvider = FutureProvider.autoDispose<List<Sale>>(
  (ref) => ref.watch(repositoryProvider).sales(),
);
final saleProvider = FutureProvider.autoDispose.family<Sale?, String>(
  (ref, id) => ref.watch(repositoryProvider).sale(id),
);
final saleItemsProvider = FutureProvider.autoDispose
    .family<List<SaleItem>, String>(
      (ref, id) => ref.watch(repositoryProvider).saleItems(id),
    );
