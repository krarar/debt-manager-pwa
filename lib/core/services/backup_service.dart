import 'dart:convert';
import 'dart:typed_data';

import '../database/database_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_return.dart';

/// Creates and restores a versioned, portable JSON backup of all Qisti data.
final class BackupService {
  const BackupService(this.database);
  final DatabaseService database;

  Future<Uint8List> exportBytes() async {
    final payload = <String, Object?>{
      'format': 'qisti-backup',
      'version': 1,
      'currency': 'IQD',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'settings': {
        'locale': await database.getSetting('locale'),
        'themeMode': await database.getSetting('themeMode'),
      },
      'customers': (await database.getCustomers()).map(_customer).toList(),
      'plans': (await database.getPlans()).map(_plan).toList(),
      'installments': (await database.getInstallments())
          .map(_installment)
          .toList(),
      'payments': (await database.getPayments()).map(_payment).toList(),
      'receipts': (await database.getReceipts()).map(_receipt).toList(),
      'notifications': (await database.getNotifications())
          .map(_notification)
          .toList(),
      'categories': (await database.getCategories()).map(_category).toList(),
      'products': (await database.getProducts()).map(_product).toList(),
      'inventoryMovements': (await database.getInventoryMovements())
          .map(_movement)
          .toList(),
      'sales': (await database.getSales()).map(_sale).toList(),
      'saleItems': [
        for (final sale in await database.getSales())
          ...(await database.getSaleItems(sale.id)).map(_saleItem),
      ],
      'returns': (await database.getReturns()).map(_return).toList(),
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  Future<void> restoreBytes(Uint8List bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['format'] != 'qisti-backup') {
      throw const FormatException('Not a Qisti backup');
    }
    if (decoded['version'] != 1 || decoded['currency'] != 'IQD') {
      throw const FormatException('Unsupported Qisti backup');
    }
    final map = Map<String, dynamic>.from(decoded);
    List<Map<String, dynamic>> list(String key) =>
        (map[key] as List? ?? const [])
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList();
    final customers = list('customers').map(_readCustomer).toList();
    final plans = list('plans').map(_readPlan).toList();
    final installments = list('installments').map(_readInstallment).toList();
    final payments = list('payments').map(_readPayment).toList();
    final receipts = list('receipts').map(_readReceipt).toList();
    final notifications = list('notifications').map(_readNotification).toList();
    final categories = list('categories').map(_readCategory).toList();
    final products = list('products').map(_readProduct).toList();
    final movements = list('inventoryMovements').map(_readMovement).toList();
    final sales = list('sales').map(_readSale).toList();
    final saleItems = list('saleItems').map(_readSaleItem).toList();
    final returns = list('returns').map(_readReturn).toList();
    final settings = Map<String, dynamic>.from(
      map['settings'] as Map? ?? const {},
    );
    await database.clearData();
    for (final value in customers) {
      await database.saveCustomer(value);
    }
    for (final value in plans) {
      await database.savePlan(value);
    }
    for (final value in installments) {
      await database.saveInstallment(value);
    }
    for (final value in payments) {
      await database.savePayment(value);
    }
    for (final value in receipts) {
      await database.saveReceipt(value);
    }
    for (final value in notifications) {
      await database.saveNotification(value);
    }
    for (final value in categories) {
      await database.saveCategory(value);
    }
    for (final value in products) {
      await database.saveProduct(value);
    }
    for (final value in movements) {
      await database.saveInventoryMovementRecord(value);
    }
    for (final value in sales) {
      await database.saveSale(value);
    }
    for (final value in saleItems) {
      await database.saveSaleItem(value);
    }
    for (final value in returns) {
      await database.saveReturn(value);
    }
    for (final entry in settings.entries) {
      if (entry.value is String) {
        await database.setSetting(entry.key, entry.value);
      }
    }
  }

  static String _date(DateTime value) => value.toUtc().toIso8601String();
  static DateTime _readDate(Object? value) => DateTime.parse('$value');
  static String? _nullable(Object? value) => value == null ? null : '$value';
  static int _int(Object? value) => (value as num).toInt();
  static int _enumIndex(Object? value, int length) {
    final index = _int(value);
    if (index < 0 || index >= length) {
      throw const FormatException('Invalid enum');
    }
    return index;
  }

  static Map<String, Object?> _customer(Customer value) => {
    'id': value.id,
    'name': value.name,
    'phone': value.phone,
    'address': value.address,
    'notes': value.notes,
    'createdAt': _date(value.createdAt),
    'updatedAt': _date(value.updatedAt),
  };
  static Customer _readCustomer(Map<String, dynamic> value) => Customer(
    id: '${value['id']}',
    name: '${value['name']}',
    phone: '${value['phone'] ?? ''}',
    address: '${value['address'] ?? ''}',
    notes: '${value['notes'] ?? ''}',
    createdAt: _readDate(value['createdAt']),
    updatedAt: _readDate(value['updatedAt']),
  );
  static Map<String, Object?> _plan(InstallmentPlan value) => {
    'id': value.id,
    'customerId': value.customerId,
    'title': value.title,
    'totalAmountIQD': value.totalAmountIQD,
    'downPaymentIQD': value.downPaymentIQD,
    'numberOfInstallments': value.numberOfInstallments,
    'recurringPeriod': value.recurringPeriod.index,
    'startDate': _date(value.startDate),
    'status': value.status.index,
    'createdAt': _date(value.createdAt),
    'notes': value.notes,
  };
  static InstallmentPlan _readPlan(Map<String, dynamic> value) =>
      InstallmentPlan(
        id: '${value['id']}',
        customerId: '${value['customerId']}',
        title: '${value['title']}',
        totalAmountIQD: _int(value['totalAmountIQD']),
        downPaymentIQD: _int(value['downPaymentIQD']),
        numberOfInstallments: _int(value['numberOfInstallments']),
        recurringPeriod:
            RecurringPeriod.values[_enumIndex(
              value['recurringPeriod'],
              RecurringPeriod.values.length,
            )],
        startDate: _readDate(value['startDate']),
        status: PlanStatus
            .values[_enumIndex(value['status'], PlanStatus.values.length)],
        createdAt: _readDate(value['createdAt']),
        notes: '${value['notes'] ?? ''}',
      );
  static Map<String, Object?> _installment(Installment value) => {
    'id': value.id,
    'planId': value.planId,
    'sequence': value.sequence,
    'amountIQD': value.amountIQD,
    'dueDate': _date(value.dueDate),
    'paidAmountIQD': value.paidAmountIQD,
    'status': value.status.index,
  };
  static Installment _readInstallment(Map<String, dynamic> value) =>
      Installment(
        id: '${value['id']}',
        planId: '${value['planId']}',
        sequence: _int(value['sequence']),
        amountIQD: _int(value['amountIQD']),
        dueDate: _readDate(value['dueDate']),
        paidAmountIQD: _int(value['paidAmountIQD']),
        status:
            InstallmentStatus.values[_enumIndex(
              value['status'],
              InstallmentStatus.values.length,
            )],
      );
  static Map<String, Object?> _payment(Payment value) => {
    'id': value.id,
    'planId': value.planId,
    'installmentId': value.installmentId,
    'amountIQD': value.amountIQD,
    'paidAt': _date(value.paidAt),
    'note': value.note,
    'paymentMethod': value.paymentMethod.index,
    'receiptId': value.receiptId,
    'receiptNumber': value.receiptNumber,
    'customerId': value.customerId,
    'paymentDate': _date(value.paymentDate),
    'createdAt': _date(value.createdAt),
  };
  static Payment _readPayment(Map<String, dynamic> value) => Payment(
    id: '${value['id']}',
    planId: '${value['planId']}',
    installmentId: '${value['installmentId']}',
    amountIQD: _int(value['amountIQD']),
    paidAt: _readDate(value['paidAt']),
    note: '${value['note'] ?? ''}',
    paymentMethod:
        PaymentMethod.values[_enumIndex(
          value['paymentMethod'],
          PaymentMethod.values.length,
        )],
    receiptId: _nullable(value['receiptId']),
    receiptNumber: _nullable(value['receiptNumber']),
    customerId: _nullable(value['customerId']),
    paymentDate: _readDate(value['paymentDate']),
    createdAt: _readDate(value['createdAt']),
  );
  static Map<String, Object?> _receipt(Receipt value) => {
    'id': value.id,
    'paymentId': value.paymentId,
    'receiptNumber': value.receiptNumber,
    'issuedAt': _date(value.issuedAt),
    'amountIQD': value.amountIQD,
    'paymentMethod': value.paymentMethod.index,
    'planId': value.planId,
    'installmentId': value.installmentId,
    'note': value.note,
    'customerId': value.customerId,
  };
  static Receipt _readReceipt(Map<String, dynamic> value) => Receipt(
    id: '${value['id']}',
    paymentId: '${value['paymentId']}',
    receiptNumber: '${value['receiptNumber']}',
    issuedAt: _readDate(value['issuedAt']),
    amountIQD: _int(value['amountIQD']),
    paymentMethod:
        PaymentMethod.values[_enumIndex(
          value['paymentMethod'],
          PaymentMethod.values.length,
        )],
    planId: '${value['planId']}',
    installmentId: '${value['installmentId']}',
    note: '${value['note'] ?? ''}',
    customerId: _nullable(value['customerId']),
  );
  static Map<String, Object?> _notification(AppNotification value) => {
    'id': value.id,
    'type': value.type.index,
    'relatedId': value.relatedId,
    'createdAt': _date(value.createdAt),
    'amountIQD': value.amountIQD,
    'isRead': value.isRead,
  };
  static AppNotification _readNotification(Map<String, dynamic> value) =>
      AppNotification(
        id: '${value['id']}',
        type: NotificationType
            .values[_enumIndex(value['type'], NotificationType.values.length)],
        relatedId: '${value['relatedId']}',
        createdAt: _readDate(value['createdAt']),
        amountIQD: value['amountIQD'] == null ? null : _int(value['amountIQD']),
        isRead: value['isRead'] == true,
      );
  static Map<String, Object?> _category(Category value) => {
    'id': value.id,
    'name': value.name,
    'description': value.description,
    'createdAt': _date(value.createdAt),
    'updatedAt': _date(value.updatedAt),
  };
  static Category _readCategory(Map<String, dynamic> value) => Category(
    id: '${value['id']}',
    name: '${value['name']}',
    description: '${value['description'] ?? ''}',
    createdAt: _readDate(value['createdAt']),
    updatedAt: _readDate(value['updatedAt']),
  );
  static Map<String, Object?> _product(Product value) => {
    'id': value.id,
    'name': value.name,
    'barcode': value.barcode,
    'categoryId': value.categoryId,
    'salePriceIQD': value.salePriceIQD,
    'costPriceIQD': value.costPriceIQD,
    'stockQuantity': value.stockQuantity,
    'minimumStock': value.minimumStock,
    'isActive': value.isActive,
    'createdAt': _date(value.createdAt),
    'updatedAt': _date(value.updatedAt),
  };
  static Product _readProduct(Map<String, dynamic> value) => Product(
    id: '${value['id']}',
    name: '${value['name']}',
    barcode: '${value['barcode'] ?? ''}',
    categoryId: _nullable(value['categoryId']),
    salePriceIQD: _int(value['salePriceIQD']),
    costPriceIQD: _int(value['costPriceIQD']),
    stockQuantity: _int(value['stockQuantity']),
    minimumStock: _int(value['minimumStock']),
    isActive: value['isActive'] != false,
    createdAt: _readDate(value['createdAt']),
    updatedAt: _readDate(value['updatedAt']),
  );
  static Map<String, Object?> _movement(InventoryMovement value) => {
    'id': value.id,
    'productId': value.productId,
    'type': value.type.index,
    'quantity': value.quantity,
    'stockBefore': value.stockBefore,
    'stockAfter': value.stockAfter,
    'unitCostIQD': value.unitCostIQD,
    'referenceId': value.referenceId,
    'note': value.note,
    'createdAt': _date(value.createdAt),
  };
  static InventoryMovement _readMovement(Map<String, dynamic> value) =>
      InventoryMovement(
        id: '${value['id']}',
        productId: '${value['productId']}',
        type:
            InventoryMovementType.values[_enumIndex(
              value['type'],
              InventoryMovementType.values.length,
            )],
        quantity: _int(value['quantity']),
        stockBefore: _int(value['stockBefore']),
        stockAfter: _int(value['stockAfter']),
        unitCostIQD: _int(value['unitCostIQD']),
        referenceId: _nullable(value['referenceId']),
        note: '${value['note'] ?? ''}',
        createdAt: _readDate(value['createdAt']),
      );
  static Map<String, Object?> _sale(Sale value) => {
    'id': value.id,
    'customerId': value.customerId,
    'subtotalIQD': value.subtotalIQD,
    'discountIQD': value.discountIQD,
    'totalIQD': value.totalIQD,
    'paidAmountIQD': value.paidAmountIQD,
    'type': value.type.index,
    'createdAt': _date(value.createdAt),
    'note': value.note,
    'paymentMethod': value.paymentMethod.index,
    'installmentPlanId': value.installmentPlanId,
  };
  static Sale _readSale(Map<String, dynamic> value) => Sale(
    id: '${value['id']}',
    customerId: _nullable(value['customerId']),
    subtotalIQD: _int(value['subtotalIQD']),
    discountIQD: _int(value['discountIQD']),
    totalIQD: _int(value['totalIQD']),
    paidAmountIQD: _int(value['paidAmountIQD']),
    type: SaleType.values[_enumIndex(value['type'], SaleType.values.length)],
    createdAt: _readDate(value['createdAt']),
    note: '${value['note'] ?? ''}',
    paymentMethod:
        PaymentMethod.values[_enumIndex(
          value['paymentMethod'],
          PaymentMethod.values.length,
        )],
    installmentPlanId: _nullable(value['installmentPlanId']),
  );
  static Map<String, Object?> _saleItem(SaleItem value) => {
    'id': value.id,
    'saleId': value.saleId,
    'productId': value.productId,
    'quantity': value.quantity,
    'unitPriceIQD': value.unitPriceIQD,
    'totalIQD': value.totalIQD,
  };
  static SaleItem _readSaleItem(Map<String, dynamic> value) => SaleItem(
    id: '${value['id']}',
    saleId: '${value['saleId']}',
    productId: '${value['productId']}',
    quantity: _int(value['quantity']),
    unitPriceIQD: _int(value['unitPriceIQD']),
    totalIQD: _int(value['totalIQD']),
  );
  static Map<String, Object?> _return(SaleReturn value) => {
    'id': value.id,
    'saleId': value.saleId,
    'saleItemId': value.saleItemId,
    'productId': value.productId,
    'quantity': value.quantity,
    'amountIQD': value.amountIQD,
    'createdAt': _date(value.createdAt),
    'reason': value.reason,
  };
  static SaleReturn _readReturn(Map<String, dynamic> value) => SaleReturn(
    id: '${value['id']}',
    saleId: '${value['saleId']}',
    saleItemId: '${value['saleItemId']}',
    productId: '${value['productId']}',
    quantity: _int(value['quantity']),
    amountIQD: _int(value['amountIQD']),
    createdAt: _readDate(value['createdAt']),
    reason: '${value['reason'] ?? ''}',
  );
}
