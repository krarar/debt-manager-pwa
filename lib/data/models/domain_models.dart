import 'package:hive_ce/hive.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_return.dart';

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 1;
  @override
  Customer read(BinaryReader r) => Customer(
    id: r.readString(),
    name: r.readString(),
    phone: r.readString(),
    address: r.readString(),
    notes: r.readString(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
  );
  @override
  void write(BinaryWriter w, Customer o) {
    w
      ..writeString(o.id)
      ..writeString(o.name)
      ..writeString(o.phone)
      ..writeString(o.address)
      ..writeString(o.notes)
      ..writeInt(o.createdAt.millisecondsSinceEpoch)
      ..writeInt(o.updatedAt.millisecondsSinceEpoch);
  }
}

class PlanAdapter extends TypeAdapter<InstallmentPlan> {
  @override
  final int typeId = 2;
  @override
  InstallmentPlan read(BinaryReader r) => InstallmentPlan(
    id: r.readString(),
    customerId: r.readString(),
    title: r.readString(),
    totalAmountIQD: r.readInt(),
    downPaymentIQD: r.readInt(),
    numberOfInstallments: r.readInt(),
    recurringPeriod: RecurringPeriod.values[r.readInt()],
    startDate: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    status: PlanStatus.values[r.readInt()],
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    notes: r.availableBytes > 0 ? r.readString() : '',
  );
  @override
  void write(BinaryWriter w, InstallmentPlan o) {
    w
      ..writeString(o.id)
      ..writeString(o.customerId)
      ..writeString(o.title)
      ..writeInt(o.totalAmountIQD)
      ..writeInt(o.downPaymentIQD)
      ..writeInt(o.numberOfInstallments)
      ..writeInt(o.recurringPeriod.index)
      ..writeInt(o.startDate.millisecondsSinceEpoch)
      ..writeInt(o.status.index)
      ..writeInt(o.createdAt.millisecondsSinceEpoch)
      ..writeString(o.notes);
  }
}

class InstallmentAdapter extends TypeAdapter<Installment> {
  @override
  final int typeId = 3;
  @override
  Installment read(BinaryReader r) => Installment(
    id: r.readString(),
    planId: r.readString(),
    sequence: r.readInt(),
    amountIQD: r.readInt(),
    dueDate: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    paidAmountIQD: r.readInt(),
    status: InstallmentStatus.values[r.readInt()],
  );
  @override
  void write(BinaryWriter w, Installment o) {
    w
      ..writeString(o.id)
      ..writeString(o.planId)
      ..writeInt(o.sequence)
      ..writeInt(o.amountIQD)
      ..writeInt(o.dueDate.millisecondsSinceEpoch)
      ..writeInt(o.paidAmountIQD)
      ..writeInt(o.status.index);
  }
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 4;
  @override
  Payment read(BinaryReader r) {
    final id = r.readString();
    final planId = r.readString();
    final installmentId = r.readString();
    final amountIQD = r.readInt();
    final paidAt = DateTime.fromMillisecondsSinceEpoch(r.readInt());
    final note = r.readString();
    // These fields were added after the initial schema. Keeping the fallback
    // makes existing stage 2 databases readable.
    var method = PaymentMethod.cash;
    String? receiptId;
    String? receiptNumber;
    String? customerId;
    DateTime? paymentDate;
    DateTime? createdAt;
    if (r.availableBytes > 0) {
      final index = r.readInt();
      if (index >= 0 && index < PaymentMethod.values.length) {
        method = PaymentMethod.values[index];
      }
      final storedReceiptId = r.readString();
      final storedReceiptNumber = r.readString();
      receiptId = storedReceiptId.isEmpty ? null : storedReceiptId;
      receiptNumber = storedReceiptNumber.isEmpty ? null : storedReceiptNumber;
      if (r.availableBytes > 0) {
        final storedCustomerId = r.readString();
        customerId = storedCustomerId.isEmpty ? null : storedCustomerId;
      }
      if (r.availableBytes >= 8) {
        paymentDate = DateTime.fromMillisecondsSinceEpoch(r.readInt());
      }
      if (r.availableBytes >= 8) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(r.readInt());
      }
    }
    return Payment(
      id: id,
      planId: planId,
      installmentId: installmentId,
      amountIQD: amountIQD,
      paidAt: paidAt,
      note: note,
      paymentMethod: method,
      receiptId: receiptId,
      receiptNumber: receiptNumber,
      customerId: customerId,
      paymentDate: paymentDate,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter w, Payment o) {
    w
      ..writeString(o.id)
      ..writeString(o.planId)
      ..writeString(o.installmentId)
      ..writeInt(o.amountIQD)
      ..writeInt(o.paidAt.millisecondsSinceEpoch)
      // Keep all payment timestamps; paymentDate and createdAt default to paidAt.
      ..writeString(o.note)
      ..writeInt(o.paymentMethod.index)
      ..writeString(o.receiptId ?? '')
      ..writeString(o.receiptNumber ?? '')
      ..writeString(o.customerId ?? '')
      ..writeInt(o.paymentDate.millisecondsSinceEpoch)
      ..writeInt(o.createdAt.millisecondsSinceEpoch);
  }
}

class ReceiptAdapter extends TypeAdapter<Receipt> {
  @override
  final int typeId = 5;

  @override
  Receipt read(BinaryReader r) {
    final id = r.readString();
    final paymentId = r.readString();
    final receiptNumber = r.readString();
    final issuedAt = DateTime.fromMillisecondsSinceEpoch(r.readInt());
    final amountIQD = r.readInt();
    final methodIndex = r.readInt();
    final planId = r.readString();
    final installmentId = r.readString();
    final note = r.readString();
    String? customerId;
    if (r.availableBytes > 0) {
      final storedCustomerId = r.readString();
      customerId = storedCustomerId.isEmpty ? null : storedCustomerId;
    }
    return Receipt(
      id: id,
      paymentId: paymentId,
      receiptNumber: receiptNumber,
      issuedAt: issuedAt,
      amountIQD: amountIQD,
      paymentMethod:
          methodIndex >= 0 && methodIndex < PaymentMethod.values.length
          ? PaymentMethod.values[methodIndex]
          : PaymentMethod.cash,
      planId: planId,
      installmentId: installmentId,
      note: note,
      customerId: customerId,
    );
  }

  @override
  void write(BinaryWriter w, Receipt o) {
    w
      ..writeString(o.id)
      ..writeString(o.paymentId)
      ..writeString(o.receiptNumber)
      ..writeInt(o.issuedAt.millisecondsSinceEpoch)
      ..writeInt(o.amountIQD)
      ..writeInt(o.paymentMethod.index)
      ..writeString(o.planId)
      ..writeString(o.installmentId)
      ..writeString(o.note)
      ..writeString(o.customerId ?? '');
  }
}

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 6;

  @override
  AppNotification read(BinaryReader r) {
    final hasAmount = r.readBool();
    return AppNotification(
      id: r.readString(),
      type: NotificationType.values[r.readInt()],
      relatedId: r.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
      amountIQD: hasAmount ? r.readInt() : null,
      isRead: r.readBool(),
    );
  }

  @override
  void write(BinaryWriter w, AppNotification o) {
    w
      ..writeBool(o.amountIQD != null)
      ..writeString(o.id)
      ..writeInt(o.type.index)
      ..writeString(o.relatedId)
      ..writeInt(o.createdAt.millisecondsSinceEpoch);
    if (o.amountIQD != null) w.writeInt(o.amountIQD!);
    w.writeBool(o.isRead);
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 7;
  @override
  Category read(BinaryReader r) => Category(
    id: r.readString(),
    name: r.readString(),
    description: r.readString(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
  );
  @override
  void write(BinaryWriter w, Category o) => w
    ..writeString(o.id)
    ..writeString(o.name)
    ..writeString(o.description)
    ..writeInt(o.createdAt.millisecondsSinceEpoch)
    ..writeInt(o.updatedAt.millisecondsSinceEpoch);
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 8;
  @override
  Product read(BinaryReader r) => Product(
    id: r.readString(),
    name: r.readString(),
    barcode: r.readString(),
    categoryId: _nullable(r.readString()),
    salePriceIQD: r.readInt(),
    costPriceIQD: r.readInt(),
    stockQuantity: r.readInt(),
    minimumStock: r.readInt(),
    isActive: r.readBool(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
  );
  @override
  void write(BinaryWriter w, Product o) => w
    ..writeString(o.id)
    ..writeString(o.name)
    ..writeString(o.barcode)
    ..writeString(o.categoryId ?? '')
    ..writeInt(o.salePriceIQD)
    ..writeInt(o.costPriceIQD)
    ..writeInt(o.stockQuantity)
    ..writeInt(o.minimumStock)
    ..writeBool(o.isActive)
    ..writeInt(o.createdAt.millisecondsSinceEpoch)
    ..writeInt(o.updatedAt.millisecondsSinceEpoch);
}

class InventoryMovementAdapter extends TypeAdapter<InventoryMovement> {
  @override
  final int typeId = 9;
  @override
  InventoryMovement read(BinaryReader r) => InventoryMovement(
    id: r.readString(),
    productId: r.readString(),
    type: InventoryMovementType.values[r.readInt()],
    quantity: r.readInt(),
    stockBefore: r.readInt(),
    stockAfter: r.readInt(),
    unitCostIQD: r.readInt(),
    referenceId: _nullable(r.readString()),
    note: r.readString(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
  );
  @override
  void write(BinaryWriter w, InventoryMovement o) => w
    ..writeString(o.id)
    ..writeString(o.productId)
    ..writeInt(o.type.index)
    ..writeInt(o.quantity)
    ..writeInt(o.stockBefore)
    ..writeInt(o.stockAfter)
    ..writeInt(o.unitCostIQD)
    ..writeString(o.referenceId ?? '')
    ..writeString(o.note)
    ..writeInt(o.createdAt.millisecondsSinceEpoch);
}

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 10;
  @override
  Sale read(BinaryReader r) => Sale(
    id: r.readString(),
    customerId: _nullable(r.readString()),
    subtotalIQD: r.readInt(),
    discountIQD: r.readInt(),
    totalIQD: r.readInt(),
    paidAmountIQD: r.readInt(),
    type: SaleType.values[r.readInt()],
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    note: r.readString(),
    paymentMethod: PaymentMethod.values[r.readInt()],
    installmentPlanId: _nullable(r.readString()),
  );
  @override
  void write(BinaryWriter w, Sale o) => w
    ..writeString(o.id)
    ..writeString(o.customerId ?? '')
    ..writeInt(o.subtotalIQD)
    ..writeInt(o.discountIQD)
    ..writeInt(o.totalIQD)
    ..writeInt(o.paidAmountIQD)
    ..writeInt(o.type.index)
    ..writeInt(o.createdAt.millisecondsSinceEpoch)
    ..writeString(o.note)
    ..writeInt(o.paymentMethod.index)
    ..writeString(o.installmentPlanId ?? '');
}

class SaleItemAdapter extends TypeAdapter<SaleItem> {
  @override
  final int typeId = 11;
  @override
  SaleItem read(BinaryReader r) => SaleItem(
    id: r.readString(),
    saleId: r.readString(),
    productId: r.readString(),
    quantity: r.readInt(),
    unitPriceIQD: r.readInt(),
    totalIQD: r.readInt(),
  );
  @override
  void write(BinaryWriter w, SaleItem o) => w
    ..writeString(o.id)
    ..writeString(o.saleId)
    ..writeString(o.productId)
    ..writeInt(o.quantity)
    ..writeInt(o.unitPriceIQD)
    ..writeInt(o.totalIQD);
}

class SaleReturnAdapter extends TypeAdapter<SaleReturn> {
  @override
  final int typeId = 12;
  @override
  SaleReturn read(BinaryReader r) => SaleReturn(
    id: r.readString(),
    saleId: r.readString(),
    saleItemId: r.readString(),
    productId: r.readString(),
    quantity: r.readInt(),
    amountIQD: r.readInt(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
    reason: r.readString(),
  );
  @override
  void write(BinaryWriter w, SaleReturn o) => w
    ..writeString(o.id)
    ..writeString(o.saleId)
    ..writeString(o.saleItemId)
    ..writeString(o.productId)
    ..writeInt(o.quantity)
    ..writeInt(o.amountIQD)
    ..writeInt(o.createdAt.millisecondsSinceEpoch)
    ..writeString(o.reason);
}

String? _nullable(String value) => value.isEmpty ? null : value;

List<int> allocateInstallments(int totalIQD, int count) {
  if (count <= 0 || totalIQD < 0) {
    throw ArgumentError('Installment count and amount must be valid');
  }
  final base = totalIQD ~/ count;
  return List<int>.generate(
    count,
    (index) => index == count - 1 ? totalIQD - base * (count - 1) : base,
  );
}
