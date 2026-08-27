import 'dart:async';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../data/models/domain_models.dart';
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

abstract interface class DatabaseService {
  Future<void> open();
  Future<void> close();
  Future<List<Customer>> getCustomers({String query = ''});
  Future<Customer?> getCustomer(String id);
  Future<void> saveCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<List<InstallmentPlan>> getPlans({String? customerId});
  Future<InstallmentPlan?> getPlan(String id);
  Future<void> savePlan(InstallmentPlan plan);
  Future<void> deletePlan(String id);
  Future<List<Installment>> getInstallments({String? planId});
  Future<void> saveInstallment(Installment installment);
  Future<List<Payment>> getPayments({String? planId});
  Future<void> savePayment(Payment payment);
  Future<List<Receipt>> getReceipts({String? paymentId});
  Future<void> saveReceipt(Receipt receipt);
  Future<Receipt?> getReceipt(String id);
  Future<List<SearchResult>> search(String query);
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false});
  Future<void> saveNotification(AppNotification notification);
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<void> registerPayment(Payment payment);
  Future<Receipt> registerPaymentAtomic(Payment payment);
  Future<List<Category>> getCategories();
  Future<Category?> getCategory(String id);
  Future<void> saveCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<List<Product>> getProducts({String query = '', String? categoryId});
  Future<Product?> getProduct(String id);
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<List<InventoryMovement>> getInventoryMovements({String? productId});
  Future<void> saveInventoryMovement(InventoryMovement movement);
  Future<void> saveInventoryMovementRecord(InventoryMovement movement);
  Future<List<Sale>> getSales();
  Future<Sale?> getSale(String id);
  Future<List<SaleItem>> getSaleItems(String saleId);
  Future<void> saveSale(Sale sale);
  Future<void> saveSaleItem(SaleItem item);
  Future<void> createSaleAtomic(Sale sale, List<SaleItem> items);
  Future<void> deleteSale(String id);
  Future<List<SaleReturn>> getReturns({String? saleId});
  Future<void> registerReturnAtomic(SaleReturn saleReturn);
  Future<void> saveReturn(SaleReturn saleReturn);
  Future<dynamic> getSetting(String key, {dynamic defaultValue});
  Future<void> setSetting(String key, dynamic value);
  Future<void> deleteNotification(String id);
  Future<void> clearData();
}

final class HiveDatabaseService implements DatabaseService {
  HiveDatabaseService({this.subDirectory});
  final String? subDirectory;
  late Box<Customer> _customers;
  late Box<InstallmentPlan> _plans;
  late Box<Installment> _installments;
  late Box<Payment> _payments;
  late Box<Receipt> _receipts;
  late Box<dynamic> _settings;
  late Box<AppNotification> _notifications;
  late Box<Category> _categories;
  late Box<Product> _products;
  late Box<InventoryMovement> _inventoryMovements;
  late Box<Sale> _sales;
  late Box<SaleItem> _saleItems;
  late Box<SaleReturn> _returns;
  bool _open = false;
  Future<void>? _opening;
  Future<void> _paymentQueue = Future.value();

  @override
  Future<void> open() async {
    if (_open) return;
    if (_opening != null) return _opening!;
    final opening = _initialize();
    _opening = opening;
    try {
      await opening;
    } finally {
      _opening = null;
    }
  }

  Future<void> _initialize() async {
    await Hive.initFlutter(subDirectory);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PlanAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(InstallmentAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ReceiptAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(InventoryMovementAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(SaleAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SaleItemAdapter());
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SaleReturnAdapter());
    }
    _customers = await Hive.openBox<Customer>('customers');
    _plans = await Hive.openBox<InstallmentPlan>('plans');
    _installments = await Hive.openBox<Installment>('installments');
    _payments = await Hive.openBox<Payment>('payments');
    _receipts = await Hive.openBox<Receipt>('receipts');
    _settings = await Hive.openBox<dynamic>('settings');
    _notifications = await Hive.openBox<AppNotification>('notifications');
    _categories = await Hive.openBox<Category>('categories');
    _products = await Hive.openBox<Product>('products');
    _inventoryMovements = await Hive.openBox<InventoryMovement>(
      'inventory_movements',
    );
    _sales = await Hive.openBox<Sale>('sales');
    _saleItems = await Hive.openBox<SaleItem>('sale_items');
    _returns = await Hive.openBox<SaleReturn>('sale_returns');
    _open = true;
  }

  Future<void> _ensureOpen() async {
    if (!_open) await open();
    if (!_open) throw StateError('DatabaseService.open must be called first');
  }

  @override
  Future<void> close() async {
    if (!_open) return;
    await Future.wait([
      _customers.close(),
      _plans.close(),
      _installments.close(),
      _payments.close(),
      _receipts.close(),
      _settings.close(),
      _notifications.close(),
      _categories.close(),
      _products.close(),
      _inventoryMovements.close(),
      _sales.close(),
      _saleItems.close(),
      _returns.close(),
    ]);
    _open = false;
  }

  @override
  Future<List<Customer>> getCustomers({String query = ''}) async {
    await _ensureOpen();
    final normalized = query.trim().toLowerCase();
    return _customers.values
        .where(
          (c) =>
              normalized.isEmpty ||
              c.name.toLowerCase().contains(normalized) ||
              c.phone.toLowerCase().contains(normalized),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    await _ensureOpen();
    return _customers.get(id);
  }

  @override
  Future<void> saveCustomer(Customer customer) async {
    await _ensureOpen();
    await _customers.put(customer.id, customer);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _ensureOpen();
    final hasPlans = _plans.values.any((p) => p.customerId == id);
    if (hasPlans) {
      throw StateError('Cannot delete a customer with installment plans');
    }
    await _customers.delete(id);
  }

  @override
  Future<List<InstallmentPlan>> getPlans({String? customerId}) async {
    await _ensureOpen();
    return _plans.values
        .where((p) => customerId == null || p.customerId == customerId)
        .toList();
  }

  @override
  Future<InstallmentPlan?> getPlan(String id) async {
    await _ensureOpen();
    return _plans.get(id);
  }

  @override
  Future<void> savePlan(InstallmentPlan plan) async {
    await _ensureOpen();
    await _plans.put(plan.id, plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    await _ensureOpen();
    await _plans.delete(id);
    for (final installment
        in _installments.values.where((i) => i.planId == id).toList()) {
      await _installments.delete(installment.id);
    }
    for (final payment
        in _payments.values.where((p) => p.planId == id).toList()) {
      await _payments.delete(payment.id);
    }
    for (final receipt
        in _receipts.values.where((r) => r.planId == id).toList()) {
      await _receipts.delete(receipt.id);
    }
  }

  @override
  Future<List<Installment>> getInstallments({String? planId}) async {
    await _ensureOpen();
    final now = DateTime.now();
    return _installments.values
        .where((i) => planId == null || i.planId == planId)
        .map(
          (i) => Installment(
            id: i.id,
            planId: i.planId,
            sequence: i.sequence,
            amountIQD: i.amountIQD,
            dueDate: i.dueDate,
            paidAmountIQD: i.paidAmountIQD,
            status: i.statusAt(now),
          ),
        )
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }

  @override
  Future<void> saveInstallment(Installment installment) async {
    await _ensureOpen();
    await _installments.put(installment.id, installment);
  }

  @override
  Future<List<Payment>> getPayments({String? planId}) async {
    await _ensureOpen();
    return _payments.values
        .where((p) => planId == null || p.planId == planId)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
  }

  @override
  Future<void> savePayment(Payment payment) async {
    await _ensureOpen();
    await _payments.put(payment.id, payment);
  }

  @override
  Future<List<Receipt>> getReceipts({String? paymentId}) async {
    await _ensureOpen();
    return _receipts.values
        .where((r) => paymentId == null || r.paymentId == paymentId)
        .toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await _ensureOpen();
    await _receipts.put(receipt.id, receipt);
  }

  @override
  Future<Receipt?> getReceipt(String id) async {
    await _ensureOpen();
    return _receipts.get(id);
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    await _ensureOpen();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <SearchResult>[];
    for (final customer in _customers.values) {
      if (_matches(q, [customer.name, customer.phone, customer.address])) {
        results.add(
          SearchResult(
            type: SearchResultType.customer,
            id: customer.id,
            title: customer.name,
            subtitle: customer.phone,
            route: '/customers/${customer.id}',
          ),
        );
      }
    }
    for (final plan in _plans.values) {
      if (_matches(q, [plan.title, plan.id])) {
        results.add(
          SearchResult(
            type: SearchResultType.plan,
            id: plan.id,
            title: plan.title,
            subtitle: '${plan.totalAmountIQD} IQD',
            route: '/plans/${plan.id}',
          ),
        );
      }
    }
    for (final installment in _installments.values) {
      if (_matches(q, [installment.id, '${installment.sequence}'])) {
        results.add(
          SearchResult(
            type: SearchResultType.installment,
            id: installment.id,
            title: 'Installment ${installment.sequence}',
            subtitle: '${installment.amountIQD} IQD',
            route: '/plans/${installment.planId}',
          ),
        );
      }
    }
    for (final payment in _payments.values) {
      if (_matches(q, [
        payment.id,
        payment.receiptNumber ?? '',
        payment.note,
        payment.customerId ?? '',
      ])) {
        results.add(
          SearchResult(
            type: SearchResultType.payment,
            id: payment.id,
            title: payment.receiptNumber ?? payment.id,
            subtitle: '${payment.amountIQD} IQD',
            route: payment.receiptId == null
                ? '/payments'
                : '/receipts/${payment.receiptId}',
          ),
        );
      }
    }
    for (final receipt in _receipts.values) {
      if (_matches(q, [
        receipt.receiptNumber,
        receipt.id,
        receipt.customerId ?? '',
      ])) {
        results.add(
          SearchResult(
            type: SearchResultType.receipt,
            id: receipt.id,
            title: receipt.receiptNumber,
            subtitle: '${receipt.amountIQD} IQD',
            route: '/receipts/${receipt.id}',
          ),
        );
      }
    }
    for (final product in _products.values) {
      if (_matches(q, [product.name, product.barcode, product.id])) {
        results.add(
          SearchResult(
            type: SearchResultType.product,
            id: product.id,
            title: product.name,
            subtitle: '${product.salePriceIQD} IQD',
            route: '/products',
          ),
        );
      }
    }
    for (final sale in _sales.values) {
      if (_matches(q, [sale.id, sale.customerId ?? ''])) {
        results.add(
          SearchResult(
            type: SearchResultType.sale,
            id: sale.id,
            title: sale.id,
            subtitle: '${sale.totalIQD} IQD',
            route: '/sales/${sale.id}',
          ),
        );
      }
    }
    return results;
  }

  @override
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
  }) async {
    await _ensureOpen();
    final notifications = <String, AppNotification>{
      for (final item in _notifications.values) item.id: item,
    };
    final now = DateTime.now();
    for (final installment in _installments.values) {
      final status = installment.statusAt(now);
      final type = status == InstallmentStatus.overdue
          ? NotificationType.overdue
          : _sameDay(installment.dueDate, now) && installment.remainingIQD > 0
          ? NotificationType.dueToday
          : null;
      if (type != null) {
        final id = 'installment-${installment.id}';
        final existing = notifications[id];
        if (existing == null ||
            existing.type != type ||
            existing.amountIQD != installment.remainingIQD) {
          final notification = AppNotification(
            id: id,
            type: type,
            relatedId: installment.id,
            createdAt: now,
            amountIQD: installment.remainingIQD,
          );
          notifications[id] = notification;
          await _notifications.put(id, notification);
        }
      }
    }
    return notifications.values
        .where((item) => !unreadOnly || !item.isRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveNotification(AppNotification notification) async {
    await _ensureOpen();
    await _notifications.put(notification.id, notification);
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _ensureOpen();
    final notification = _notifications.get(id);
    if (notification != null) {
      await _notifications.put(id, notification.copyWith(isRead: true));
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _ensureOpen();
    for (final item in _notifications.values.where((item) => !item.isRead)) {
      await _notifications.put(item.id, item.copyWith(isRead: true));
    }
  }

  @override
  Future<void> registerPayment(Payment payment) async {
    await registerPaymentAtomic(payment);
  }

  @override
  Future<Receipt> registerPaymentAtomic(Payment payment) {
    final completer = Completer<Receipt>();
    final previous = _paymentQueue;
    _paymentQueue = () async {
      try {
        await previous;
      } on Object {
        // A failed operation must not prevent independent queued payments.
      }
      try {
        completer.complete(await _registerPayment(payment));
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    }();
    return completer.future;
  }

  Future<Receipt> _registerPayment(Payment payment) async {
    await _ensureOpen();
    final installment = _installments.get(payment.installmentId);
    if (installment == null || installment.planId != payment.planId) {
      throw StateError('Installment not found');
    }
    if (_payments.containsKey(payment.id)) {
      throw StateError('Payment already exists');
    }
    if (payment.amountIQD <= 0) throw ArgumentError('Payment must be positive');
    if (installment.paidAmountIQD + payment.amountIQD > installment.amountIQD) {
      throw StateError('Payment exceeds remaining balance');
    }
    final storedSequence = _settings.get('receiptSequence', defaultValue: 0);
    final previousSequence = storedSequence is int
        ? storedSequence
        : int.tryParse('$storedSequence') ?? 0;
    final sequence = previousSequence + 1;
    final receiptNumber =
        payment.receiptNumber ?? 'R-${sequence.toString().padLeft(6, '0')}';
    final receiptId = payment.receiptId ?? 'receipt-${payment.id}';
    if (_receipts.containsKey(receiptId)) {
      throw StateError('Receipt already exists');
    }
    final plan = _plans.get(payment.planId);
    final storedPayment = Payment(
      id: payment.id,
      planId: payment.planId,
      installmentId: payment.installmentId,
      amountIQD: payment.amountIQD,
      paidAt: payment.paidAt,
      note: payment.note,
      paymentMethod: payment.paymentMethod,
      receiptId: receiptId,
      receiptNumber: receiptNumber,
      customerId: payment.customerId ?? plan?.customerId,
      paymentDate: payment.paymentDate,
      createdAt: payment.createdAt,
    );
    final receipt = Receipt(
      id: receiptId,
      paymentId: payment.id,
      receiptNumber: receiptNumber,
      issuedAt: payment.paidAt,
      amountIQD: payment.amountIQD,
      paymentMethod: payment.paymentMethod,
      planId: payment.planId,
      installmentId: payment.installmentId,
      note: payment.note,
      customerId: payment.customerId ?? plan?.customerId,
    );
    final updated = Installment(
      id: installment.id,
      planId: installment.planId,
      sequence: installment.sequence,
      amountIQD: installment.amountIQD,
      dueDate: installment.dueDate,
      paidAmountIQD: installment.paidAmountIQD + payment.amountIQD,
      status: installment.statusAt(DateTime.now()),
    );
    final notification = AppNotification(
      id: 'payment-${payment.id}',
      type: NotificationType.paymentReceived,
      relatedId: payment.id,
      createdAt: payment.paidAt,
      amountIQD: payment.amountIQD,
    );
    try {
      await _settings.put('receiptSequence', sequence);
      await _installments.put(updated.id, updated);
      await _payments.put(storedPayment.id, storedPayment);
      await _receipts.put(receipt.id, receipt);
      await _notifications.put(notification.id, notification);
      if (plan != null) {
        final all = _installments.values.where((i) => i.planId == plan.id);
        if (all.isNotEmpty &&
            all.every(
              (i) => i.id == updated.id
                  ? updated.paidAmountIQD >= i.amountIQD
                  : i.paidAmountIQD >= i.amountIQD,
            )) {
          await _plans.put(payment.planId, _completedPlan(plan));
          final completed = AppNotification(
            id: 'plan-completed-${plan.id}',
            type: NotificationType.planCompleted,
            relatedId: plan.id,
            createdAt: DateTime.now(),
          );
          await _notifications.put(completed.id, completed);
        }
      }
    } catch (error, stack) {
      await _installments.put(installment.id, installment);
      await _payments.delete(storedPayment.id);
      await _receipts.delete(receipt.id);
      await _notifications.delete(notification.id);
      await _settings.put('receiptSequence', sequence - 1);
      if (plan != null) await _plans.put(plan.id, plan);
      Error.throwWithStackTrace(error, stack);
    }
    return receipt;
  }

  @override
  Future<List<Category>> getCategories() async {
    await _ensureOpen();
    return _categories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Category?> getCategory(String id) async {
    await _ensureOpen();
    return _categories.get(id);
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _ensureOpen();
    await _categories.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _ensureOpen();
    if (_products.values.any((p) => p.categoryId == id)) {
      throw StateError('Category has products');
    }
    await _categories.delete(id);
  }

  @override
  Future<List<Product>> getProducts({
    String query = '',
    String? categoryId,
  }) async {
    await _ensureOpen();
    final q = query.trim().toLowerCase();
    return _products.values
        .where(
          (p) =>
              (categoryId == null || p.categoryId == categoryId) &&
              (q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.barcode.toLowerCase().contains(q)),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<Product?> getProduct(String id) async {
    await _ensureOpen();
    return _products.get(id);
  }

  @override
  Future<void> saveProduct(Product product) async {
    await _ensureOpen();
    if (product.name.trim().isEmpty || product.salePriceIQD < 0) {
      throw ArgumentError('Invalid product');
    }
    if (product.stockQuantity < 0 || product.minimumStock < 0) {
      throw ArgumentError('Invalid stock');
    }
    final barcode = product.barcode.trim().toLowerCase();
    if (barcode.isNotEmpty &&
        _products.values.any(
          (p) =>
              p.id != product.id && p.barcode.trim().toLowerCase() == barcode,
        )) {
      throw StateError('Barcode already exists');
    }
    await _products.put(product.id, product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _ensureOpen();
    if (_saleItems.values.any((item) => item.productId == id)) {
      throw StateError('Product has sales');
    }
    await _products.delete(id);
  }

  @override
  Future<List<InventoryMovement>> getInventoryMovements({
    String? productId,
  }) async {
    await _ensureOpen();
    return _inventoryMovements.values
        .where((m) => productId == null || m.productId == productId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveInventoryMovement(InventoryMovement movement) async {
    await _ensureOpen();
    if (movement.quantity == 0) throw ArgumentError('Movement is empty');
    final product = _products.get(movement.productId);
    if (product == null) throw StateError('Product not found');
    final before = product.stockQuantity;
    final after = before + movement.quantity;
    if (after < 0) throw StateError('Insufficient stock');
    final stored = InventoryMovement(
      id: movement.id,
      productId: movement.productId,
      type: movement.type,
      quantity: movement.quantity,
      stockBefore: before,
      stockAfter: after,
      unitCostIQD: movement.unitCostIQD,
      referenceId: movement.referenceId,
      note: movement.note,
      createdAt: movement.createdAt,
    );
    await _products.put(product.id, product.copyWith(stockQuantity: after));
    await _inventoryMovements.put(stored.id, stored);
  }

  @override
  Future<void> saveInventoryMovementRecord(InventoryMovement movement) async {
    await _ensureOpen();
    await _inventoryMovements.put(movement.id, movement);
  }

  @override
  Future<List<Sale>> getSales() async {
    await _ensureOpen();
    return _sales.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Sale?> getSale(String id) async {
    await _ensureOpen();
    return _sales.get(id);
  }

  @override
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    await _ensureOpen();
    return _saleItems.values.where((i) => i.saleId == saleId).toList();
  }

  @override
  Future<void> saveSale(Sale sale) async {
    await _ensureOpen();
    await _sales.put(sale.id, sale);
  }

  @override
  Future<void> saveSaleItem(SaleItem item) async {
    await _ensureOpen();
    await _saleItems.put(item.id, item);
  }

  @override
  Future<void> createSaleAtomic(Sale sale, List<SaleItem> items) async {
    await _ensureOpen();
    if (_sales.containsKey(sale.id)) throw StateError('Sale already exists');
    if (items.isEmpty ||
        sale.totalIQD <= 0 ||
        sale.paidAmountIQD < 0 ||
        sale.paidAmountIQD > sale.totalIQD) {
      throw ArgumentError('Invalid sale');
    }
    final totals = <String, int>{};
    for (final item in items) {
      if (item.saleId != sale.id ||
          item.quantity <= 0 ||
          item.unitPriceIQD < 0 ||
          item.totalIQD != item.quantity * item.unitPriceIQD) {
        throw ArgumentError('Invalid sale item');
      }
      totals[item.productId] = (totals[item.productId] ?? 0) + item.quantity;
    }
    final products = <String, Product>{};
    for (final entry in totals.entries) {
      final product = _products.get(entry.key);
      if (product == null || !product.isActive) {
        throw StateError('Product not found');
      }
      if (product.stockQuantity < entry.value) {
        throw StateError('Insufficient stock');
      }
      products[entry.key] = product;
    }
    final movementIds = <String>[];
    try {
      await _sales.put(sale.id, sale);
      for (final item in items) {
        await _saleItems.put(item.id, item);
      }
      final now = sale.createdAt;
      for (final entry in totals.entries) {
        final product = products[entry.key]!;
        final movement = InventoryMovement(
          id: 'sale-${sale.id}-${entry.key}',
          productId: entry.key,
          type: InventoryMovementType.sale,
          quantity: -entry.value,
          stockBefore: product.stockQuantity,
          stockAfter: product.stockQuantity - entry.value,
          referenceId: sale.id,
          createdAt: now,
        );
        movementIds.add(movement.id);
        await _products.put(
          product.id,
          product.copyWith(stockQuantity: movement.stockAfter),
        );
        await _inventoryMovements.put(movement.id, movement);
      }
    } catch (error, stack) {
      await _sales.delete(sale.id);
      for (final item in items) {
        await _saleItems.delete(item.id);
      }
      for (final entry in products.entries) {
        await _products.put(entry.key, entry.value);
      }
      for (final id in movementIds) {
        await _inventoryMovements.delete(id);
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    await _ensureOpen();
    final sale = _sales.get(id);
    if (sale == null) return;
    final movements = _inventoryMovements.values
        .where(
          (m) => m.referenceId == id && m.type == InventoryMovementType.sale,
        )
        .toList();
    for (final movement in movements) {
      final product = _products.get(movement.productId);
      if (product != null) {
        await _products.put(
          product.id,
          product.copyWith(
            stockQuantity: product.stockQuantity - movement.quantity,
          ),
        );
      }
      await _inventoryMovements.delete(movement.id);
    }
    await _saleItems.deleteAll(
      _saleItems.values
          .where((item) => item.saleId == id)
          .map((item) => item.id)
          .toList(),
    );
    await _sales.delete(id);
  }

  @override
  Future<List<SaleReturn>> getReturns({String? saleId}) async {
    await _ensureOpen();
    return _returns.values
        .where((r) => saleId == null || r.saleId == saleId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> registerReturnAtomic(SaleReturn saleReturn) async {
    await _ensureOpen();
    if (_returns.containsKey(saleReturn.id) || saleReturn.quantity <= 0) {
      throw StateError('Invalid return');
    }
    final sale = _sales.get(saleReturn.saleId);
    final item = _saleItems.get(saleReturn.saleItemId);
    final product = _products.get(saleReturn.productId);
    if (sale == null ||
        item == null ||
        product == null ||
        item.saleId != sale.id ||
        item.productId != product.id ||
        saleReturn.quantity > item.quantity) {
      throw StateError('Sale item not found');
    }
    final returned = _returns.values
        .where((r) => r.saleItemId == item.id)
        .fold<int>(0, (sum, r) => sum + r.quantity);
    if (returned + saleReturn.quantity > item.quantity) {
      throw StateError('Return exceeds sold quantity');
    }
    final movement = InventoryMovement(
      id: 'return-${saleReturn.id}',
      productId: product.id,
      type: InventoryMovementType.returned,
      quantity: saleReturn.quantity,
      stockBefore: product.stockQuantity,
      stockAfter: product.stockQuantity + saleReturn.quantity,
      referenceId: saleReturn.id,
      createdAt: saleReturn.createdAt,
    );
    await _products.put(
      product.id,
      product.copyWith(stockQuantity: movement.stockAfter),
    );
    await _inventoryMovements.put(movement.id, movement);
    try {
      await _returns.put(saleReturn.id, saleReturn);
    } catch (error, stack) {
      await _products.put(product.id, product);
      await _inventoryMovements.delete(movement.id);
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  Future<void> saveReturn(SaleReturn saleReturn) async {
    await _ensureOpen();
    await _returns.put(saleReturn.id, saleReturn);
  }

  @override
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    await _ensureOpen();
    return _settings.get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> setSetting(String key, dynamic value) async {
    await _ensureOpen();
    await _settings.put(key, value);
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _ensureOpen();
    await _notifications.delete(id);
  }

  @override
  Future<void> clearData() async {
    await _ensureOpen();
    await Future.wait([
      _customers.clear(),
      _plans.clear(),
      _installments.clear(),
      _payments.clear(),
      _receipts.clear(),
      _notifications.clear(),
      _categories.clear(),
      _products.clear(),
      _inventoryMovements.clear(),
      _sales.clear(),
      _saleItems.clear(),
      _returns.clear(),
    ]);
    await _settings.delete('receiptSequence');
  }
}

final class InMemoryDatabaseService implements DatabaseService {
  bool _isOpen = false;
  final Map<String, Customer> _customers = {};
  final Map<String, InstallmentPlan> _plans = {};
  final Map<String, Installment> _installments = {};
  final Map<String, Payment> _payments = {};
  final Map<String, Receipt> _receipts = {};
  final Map<String, AppNotification> _notifications = {};
  final Map<String, Category> _categories = {};
  final Map<String, Product> _products = {};
  final Map<String, InventoryMovement> _inventoryMovements = {};
  final Map<String, Sale> _sales = {};
  final Map<String, SaleItem> _saleItems = {};
  final Map<String, SaleReturn> _returns = {};
  int _receiptSequence = 0;
  final Map<String, dynamic> _settings = {};
  Future<void> _paymentQueue = Future.value();
  bool get isOpen => _isOpen;
  @override
  Future<void> open() async => _isOpen = true;
  @override
  Future<void> close() async => _isOpen = false;
  void _ensure() {
    if (!_isOpen) throw StateError('Database is closed');
  }

  @override
  Future<List<Customer>> getCustomers({String query = ''}) async {
    _ensure();
    final q = query.toLowerCase();
    return _customers.values
        .where(
          (c) =>
              q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q),
        )
        .toList();
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    _ensure();
    return _customers[id];
  }

  @override
  Future<void> saveCustomer(Customer c) async {
    _ensure();
    _customers[c.id] = c;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    _ensure();
    if (_plans.values.any((p) => p.customerId == id)) {
      throw StateError('Cannot delete a customer with installment plans');
    }
    _customers.remove(id);
  }

  @override
  Future<List<InstallmentPlan>> getPlans({String? customerId}) async {
    _ensure();
    return _plans.values
        .where((p) => customerId == null || p.customerId == customerId)
        .toList();
  }

  @override
  Future<InstallmentPlan?> getPlan(String id) async {
    _ensure();
    return _plans[id];
  }

  @override
  Future<void> savePlan(InstallmentPlan p) async {
    _ensure();
    _plans[p.id] = p;
  }

  @override
  Future<void> deletePlan(String id) async {
    _ensure();
    _plans.remove(id);
    _installments.removeWhere((_, i) => i.planId == id);
    _payments.removeWhere((_, p) => p.planId == id);
    _receipts.removeWhere((_, r) => r.planId == id);
    _notifications.removeWhere((_, n) => n.relatedId == id);
  }

  @override
  Future<List<Installment>> getInstallments({String? planId}) async {
    _ensure();
    return _installments.values
        .where((i) => planId == null || i.planId == planId)
        .map(
          (i) => Installment(
            id: i.id,
            planId: i.planId,
            sequence: i.sequence,
            amountIQD: i.amountIQD,
            dueDate: i.dueDate,
            paidAmountIQD: i.paidAmountIQD,
            status: i.statusAt(DateTime.now()),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveInstallment(Installment i) async {
    _ensure();
    _installments[i.id] = i;
  }

  @override
  Future<List<Payment>> getPayments({String? planId}) async {
    _ensure();
    return _payments.values
        .where((p) => planId == null || p.planId == planId)
        .toList();
  }

  @override
  Future<void> savePayment(Payment payment) async {
    _ensure();
    _payments[payment.id] = payment;
  }

  @override
  Future<List<Receipt>> getReceipts({String? paymentId}) async {
    _ensure();
    return _receipts.values
        .where((r) => paymentId == null || r.paymentId == paymentId)
        .toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    _ensure();
    _receipts[receipt.id] = receipt;
  }

  @override
  Future<Receipt?> getReceipt(String id) async {
    _ensure();
    return _receipts[id];
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    _ensure();
    return _searchResults(
      query,
      customers: _customers.values,
      plans: _plans.values,
      installments: _installments.values,
      payments: _payments.values,
      receipts: _receipts.values,
      products: _products.values,
      sales: _sales.values,
    );
  }

  @override
  Future<void> saveInventoryMovementRecord(InventoryMovement movement) async {
    _ensure();
    _inventoryMovements[movement.id] = movement;
  }

  @override
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
  }) async {
    _ensure();
    final notifications = <String, AppNotification>{
      for (final item in _notifications.values) item.id: item,
    };
    final now = DateTime.now();
    for (final installment in _installments.values) {
      final status = installment.statusAt(now);
      final type = status == InstallmentStatus.overdue
          ? NotificationType.overdue
          : _sameDay(installment.dueDate, now) && installment.remainingIQD > 0
          ? NotificationType.dueToday
          : null;
      if (type != null) {
        final id = 'installment-${installment.id}';
        final existing = notifications[id];
        if (existing == null ||
            existing.type != type ||
            existing.amountIQD != installment.remainingIQD) {
          final notification = AppNotification(
            id: id,
            type: type,
            relatedId: installment.id,
            createdAt: now,
            amountIQD: installment.remainingIQD,
          );
          notifications[id] = notification;
        }
      }
    }
    return notifications.values
        .where((item) => !unreadOnly || !item.isRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveNotification(AppNotification notification) async {
    _ensure();
    _notifications[notification.id] = notification;
  }

  @override
  Future<void> markNotificationRead(String id) async {
    _ensure();
    final notification = _notifications[id];
    if (notification != null) {
      _notifications[id] = notification.copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    _ensure();
    for (final item in _notifications.values.where((item) => !item.isRead)) {
      _notifications[item.id] = item.copyWith(isRead: true);
    }
  }

  @override
  Future<void> registerPayment(Payment p) async {
    await registerPaymentAtomic(p);
  }

  @override
  Future<Receipt> registerPaymentAtomic(Payment p) {
    final completer = Completer<Receipt>();
    final previous = _paymentQueue;
    _paymentQueue = () async {
      try {
        await previous;
      } on Object {
        // A failed operation must not prevent independent queued payments.
      }
      try {
        completer.complete(await _registerPayment(p));
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    }();
    return completer.future;
  }

  Future<Receipt> _registerPayment(Payment p) async {
    _ensure();
    final i = _installments[p.installmentId];
    if (i == null || i.planId != p.planId) {
      throw StateError('Installment not found');
    }
    if (_payments.containsKey(p.id)) throw StateError('Payment already exists');
    if (p.amountIQD <= 0 || p.amountIQD + i.paidAmountIQD > i.amountIQD) {
      if (p.amountIQD <= 0) throw ArgumentError('Payment must be positive');
      throw StateError('Payment exceeds remaining balance');
    }
    final sequence = ++_receiptSequence;
    final receiptNumber =
        p.receiptNumber ?? 'R-${sequence.toString().padLeft(6, '0')}';
    final receiptId = p.receiptId ?? 'receipt-${p.id}';
    if (_receipts.containsKey(receiptId)) {
      throw StateError('Receipt already exists');
    }
    final plan = _plans[p.planId];
    final storedPayment = Payment(
      id: p.id,
      planId: p.planId,
      installmentId: p.installmentId,
      amountIQD: p.amountIQD,
      paidAt: p.paidAt,
      note: p.note,
      paymentMethod: p.paymentMethod,
      receiptId: receiptId,
      receiptNumber: receiptNumber,
      customerId: p.customerId ?? plan?.customerId,
      paymentDate: p.paymentDate,
      createdAt: p.createdAt,
    );
    final receipt = Receipt(
      id: receiptId,
      paymentId: p.id,
      receiptNumber: receiptNumber,
      issuedAt: p.paidAt,
      amountIQD: p.amountIQD,
      paymentMethod: p.paymentMethod,
      planId: p.planId,
      installmentId: p.installmentId,
      note: p.note,
    );
    _installments[i.id] = Installment(
      id: i.id,
      planId: i.planId,
      sequence: i.sequence,
      amountIQD: i.amountIQD,
      dueDate: i.dueDate,
      paidAmountIQD: i.paidAmountIQD + p.amountIQD,
      status: i.status,
    );
    _payments[p.id] = storedPayment;
    _receipts[receipt.id] = receipt;
    _notifications['payment-${p.id}'] = AppNotification(
      id: 'payment-${p.id}',
      type: NotificationType.paymentReceived,
      relatedId: p.id,
      createdAt: p.paidAt,
      amountIQD: p.amountIQD,
    );
    final planInstallments = _installments.values.where(
      (item) => item.planId == p.planId,
    );
    if (plan != null &&
        planInstallments.isNotEmpty &&
        planInstallments.every(
          (item) => item.paidAmountIQD >= item.amountIQD,
        )) {
      _plans[p.planId] = _completedPlan(plan);
      _notifications['plan-completed-${plan.id}'] = AppNotification(
        id: 'plan-completed-${plan.id}',
        type: NotificationType.planCompleted,
        relatedId: plan.id,
        createdAt: DateTime.now(),
      );
    }
    return receipt;
  }

  @override
  Future<List<Category>> getCategories() async {
    _ensure();
    return _categories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Category?> getCategory(String id) async {
    _ensure();
    return _categories[id];
  }

  @override
  Future<void> saveCategory(Category category) async {
    _ensure();
    _categories[category.id] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _ensure();
    if (_products.values.any((p) => p.categoryId == id)) {
      throw StateError('Category has products');
    }
    _categories.remove(id);
  }

  @override
  Future<List<Product>> getProducts({
    String query = '',
    String? categoryId,
  }) async {
    _ensure();
    final q = query.trim().toLowerCase();
    return _products.values
        .where(
          (p) =>
              (categoryId == null || p.categoryId == categoryId) &&
              (q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.barcode.toLowerCase().contains(q)),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Product?> getProduct(String id) async {
    _ensure();
    return _products[id];
  }

  @override
  Future<void> saveProduct(Product product) async {
    _ensure();
    if (product.name.trim().isEmpty ||
        product.salePriceIQD < 0 ||
        product.stockQuantity < 0 ||
        product.minimumStock < 0) {
      throw ArgumentError('Invalid product');
    }
    final barcode = product.barcode.trim().toLowerCase();
    if (barcode.isNotEmpty &&
        _products.values.any(
          (p) =>
              p.id != product.id && p.barcode.trim().toLowerCase() == barcode,
        )) {
      throw StateError('Barcode already exists');
    }
    _products[product.id] = product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _ensure();
    if (_saleItems.values.any((item) => item.productId == id)) {
      throw StateError('Product has sales');
    }
    _products.remove(id);
  }

  @override
  Future<List<InventoryMovement>> getInventoryMovements({
    String? productId,
  }) async {
    _ensure();
    return _inventoryMovements.values
        .where((m) => productId == null || m.productId == productId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveInventoryMovement(InventoryMovement movement) async {
    _ensure();
    final product = _products[movement.productId];
    if (product == null) throw StateError('Product not found');
    final after = product.stockQuantity + movement.quantity;
    if (movement.quantity == 0 || after < 0) {
      throw StateError('Invalid stock movement');
    }
    _products[product.id] = product.copyWith(stockQuantity: after);
    _inventoryMovements[movement.id] = InventoryMovement(
      id: movement.id,
      productId: movement.productId,
      type: movement.type,
      quantity: movement.quantity,
      stockBefore: product.stockQuantity,
      stockAfter: after,
      unitCostIQD: movement.unitCostIQD,
      referenceId: movement.referenceId,
      note: movement.note,
      createdAt: movement.createdAt,
    );
  }

  @override
  Future<List<Sale>> getSales() async {
    _ensure();
    return _sales.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Sale?> getSale(String id) async {
    _ensure();
    return _sales[id];
  }

  @override
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    _ensure();
    return _saleItems.values.where((item) => item.saleId == saleId).toList();
  }

  @override
  Future<void> saveSale(Sale sale) async {
    _ensure();
    _sales[sale.id] = sale;
  }

  @override
  Future<void> saveSaleItem(SaleItem item) async {
    _ensure();
    _saleItems[item.id] = item;
  }

  @override
  Future<void> createSaleAtomic(Sale sale, List<SaleItem> items) async {
    _ensure();
    if (_sales.containsKey(sale.id)) throw StateError('Sale already exists');
    if (items.isEmpty ||
        sale.totalIQD <= 0 ||
        sale.paidAmountIQD < 0 ||
        sale.paidAmountIQD > sale.totalIQD) {
      throw ArgumentError('Invalid sale');
    }
    final totals = <String, int>{};
    for (final item in items) {
      if (item.saleId != sale.id ||
          item.quantity <= 0 ||
          item.unitPriceIQD < 0 ||
          item.totalIQD != item.quantity * item.unitPriceIQD) {
        throw ArgumentError('Invalid sale item');
      }
      totals[item.productId] = (totals[item.productId] ?? 0) + item.quantity;
    }
    final products = <String, Product>{};
    for (final entry in totals.entries) {
      final product = _products[entry.key];
      if (product == null || !product.isActive) {
        throw StateError('Product not found');
      }
      if (product.stockQuantity < entry.value) {
        throw StateError('Insufficient stock');
      }
      products[entry.key] = product;
    }
    try {
      _sales[sale.id] = sale;
      for (final item in items) {
        _saleItems[item.id] = item;
      }
      for (final entry in totals.entries) {
        final product = products[entry.key]!;
        final after = product.stockQuantity - entry.value;
        _products[product.id] = product.copyWith(stockQuantity: after);
        final movement = InventoryMovement(
          id: 'sale-${sale.id}-${entry.key}',
          productId: entry.key,
          type: InventoryMovementType.sale,
          quantity: -entry.value,
          stockBefore: product.stockQuantity,
          stockAfter: after,
          referenceId: sale.id,
          createdAt: sale.createdAt,
        );
        _inventoryMovements[movement.id] = movement;
      }
    } catch (error, stack) {
      _sales.remove(sale.id);
      for (final item in items) {
        _saleItems.remove(item.id);
      }
      for (final entry in products.entries) {
        _products[entry.key] = entry.value;
        _inventoryMovements.remove('sale-${sale.id}-${entry.key}');
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    _ensure();
    if (!_sales.containsKey(id)) return;
    final movements = _inventoryMovements.values
        .where(
          (m) => m.referenceId == id && m.type == InventoryMovementType.sale,
        )
        .toList();
    for (final movement in movements) {
      final product = _products[movement.productId];
      if (product != null) {
        _products[product.id] = product.copyWith(
          stockQuantity: product.stockQuantity - movement.quantity,
        );
      }
      _inventoryMovements.remove(movement.id);
    }
    _saleItems.removeWhere((_, item) => item.saleId == id);
    _sales.remove(id);
  }

  @override
  Future<List<SaleReturn>> getReturns({String? saleId}) async {
    _ensure();
    return _returns.values
        .where((r) => saleId == null || r.saleId == saleId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> registerReturnAtomic(SaleReturn saleReturn) async {
    _ensure();
    if (_returns.containsKey(saleReturn.id) || saleReturn.quantity <= 0) {
      throw StateError('Invalid return');
    }
    final sale = _sales[saleReturn.saleId];
    final item = _saleItems[saleReturn.saleItemId];
    final product = _products[saleReturn.productId];
    if (sale == null ||
        item == null ||
        product == null ||
        item.saleId != sale.id ||
        item.productId != product.id) {
      throw StateError('Sale item not found');
    }
    final returned = _returns.values
        .where((r) => r.saleItemId == item.id)
        .fold<int>(0, (sum, r) => sum + r.quantity);
    if (returned + saleReturn.quantity > item.quantity) {
      throw StateError('Return exceeds sold quantity');
    }
    final movement = InventoryMovement(
      id: 'return-${saleReturn.id}',
      productId: product.id,
      type: InventoryMovementType.returned,
      quantity: saleReturn.quantity,
      stockBefore: product.stockQuantity,
      stockAfter: product.stockQuantity + saleReturn.quantity,
      referenceId: saleReturn.id,
      createdAt: saleReturn.createdAt,
    );
    _products[product.id] = product.copyWith(
      stockQuantity: movement.stockAfter,
    );
    _inventoryMovements[movement.id] = movement;
    try {
      _returns[saleReturn.id] = saleReturn;
    } catch (error, stack) {
      _products[product.id] = product;
      _inventoryMovements.remove(movement.id);
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  Future<void> saveReturn(SaleReturn saleReturn) async {
    _ensure();
    _returns[saleReturn.id] = saleReturn;
  }

  @override
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    _ensure();
    return _settings[key] ?? defaultValue;
  }

  @override
  Future<void> setSetting(String key, dynamic value) async {
    _ensure();
    _settings[key] = value;
  }

  @override
  Future<void> deleteNotification(String id) async {
    _ensure();
    _notifications.remove(id);
  }

  @override
  Future<void> clearData() async {
    _ensure();
    _customers.clear();
    _plans.clear();
    _installments.clear();
    _payments.clear();
    _receipts.clear();
    _notifications.clear();
    _categories.clear();
    _products.clear();
    _inventoryMovements.clear();
    _sales.clear();
    _saleItems.clear();
    _returns.clear();
    _settings.clear();
    _receiptSequence = 0;
  }
}

InstallmentPlan _completedPlan(InstallmentPlan plan) => InstallmentPlan(
  id: plan.id,
  customerId: plan.customerId,
  title: plan.title,
  totalAmountIQD: plan.totalAmountIQD,
  downPaymentIQD: plan.downPaymentIQD,
  numberOfInstallments: plan.numberOfInstallments,
  recurringPeriod: plan.recurringPeriod,
  startDate: plan.startDate,
  status: PlanStatus.completed,
  createdAt: plan.createdAt,
);

bool _matches(String query, Iterable<String> values) =>
    values.any((value) => value.toLowerCase().contains(query));

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<SearchResult> _searchResults(
  String query, {
  required Iterable<Customer> customers,
  required Iterable<InstallmentPlan> plans,
  required Iterable<Installment> installments,
  required Iterable<Payment> payments,
  required Iterable<Receipt> receipts,
  required Iterable<Product> products,
  required Iterable<Sale> sales,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final results = <SearchResult>[];
  for (final customer in customers) {
    if (_matches(q, [customer.name, customer.phone, customer.address])) {
      results.add(
        SearchResult(
          type: SearchResultType.customer,
          id: customer.id,
          title: customer.name,
          subtitle: customer.phone,
          route: '/customers/${customer.id}',
        ),
      );
    }
  }
  for (final plan in plans) {
    if (_matches(q, [plan.title, plan.id])) {
      results.add(
        SearchResult(
          type: SearchResultType.plan,
          id: plan.id,
          title: plan.title,
          subtitle: '${plan.totalAmountIQD} IQD',
          route: '/plans/${plan.id}',
        ),
      );
    }
  }
  for (final installment in installments) {
    if (_matches(q, [installment.id, '${installment.sequence}'])) {
      results.add(
        SearchResult(
          type: SearchResultType.installment,
          id: installment.id,
          title: 'Installment ${installment.sequence}',
          subtitle: '${installment.amountIQD} IQD',
          route: '/plans/${installment.planId}',
        ),
      );
    }
  }
  for (final payment in payments) {
    if (_matches(q, [
      payment.id,
      payment.receiptNumber ?? '',
      payment.note,
      payment.customerId ?? '',
    ])) {
      results.add(
        SearchResult(
          type: SearchResultType.payment,
          id: payment.id,
          title: payment.receiptNumber ?? payment.id,
          subtitle: '${payment.amountIQD} IQD',
          route: payment.receiptId == null
              ? '/payments'
              : '/receipts/${payment.receiptId}',
        ),
      );
    }
  }
  for (final receipt in receipts) {
    if (_matches(q, [
      receipt.receiptNumber,
      receipt.id,
      receipt.customerId ?? '',
    ])) {
      results.add(
        SearchResult(
          type: SearchResultType.receipt,
          id: receipt.id,
          title: receipt.receiptNumber,
          subtitle: '${receipt.amountIQD} IQD',
          route: '/receipts/${receipt.id}',
        ),
      );
    }
  }
  for (final product in products) {
    if (_matches(q, [product.name, product.barcode, product.id])) {
      results.add(
        SearchResult(
          type: SearchResultType.product,
          id: product.id,
          title: product.name,
          subtitle: '${product.salePriceIQD} IQD',
          route: '/products',
        ),
      );
    }
  }
  for (final sale in sales) {
    if (_matches(q, [sale.id, sale.customerId ?? ''])) {
      results.add(
        SearchResult(
          type: SearchResultType.sale,
          id: sale.id,
          title: sale.id,
          subtitle: '${sale.totalIQD} IQD',
          route: '/sales/${sale.id}',
        ),
      );
    }
  }
  return results;
}
