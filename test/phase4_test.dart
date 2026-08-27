import 'package:flutter_test/flutter_test.dart';
import 'package:qisti/core/database/database_service.dart';
import 'package:qisti/data/repositories/qisti_repository_impl.dart';
import 'package:qisti/domain/entities/product.dart';
import 'package:qisti/domain/entities/sale.dart';
import 'package:qisti/domain/entities/sale_item.dart';
import 'package:qisti/domain/entities/inventory_movement.dart';
import 'package:qisti/domain/entities/sale_return.dart';

void main() {
  test('sales atomically validate and move stock', () async {
    final database = InMemoryDatabaseService()..open();
    final repository = QistiRepositoryImpl(database);
    final now = DateTime.now();
    await repository.saveProduct(
      Product(
        id: 'p',
        name: 'Phone',
        barcode: '123',
        salePriceIQD: 100,
        stockQuantity: 2,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final sale = Sale(
      id: 's',
      subtotalIQD: 100,
      totalIQD: 100,
      paidAmountIQD: 100,
      type: SaleType.cash,
      createdAt: now,
    );
    await repository.createSale(sale, [
      const SaleItem(
        id: 's-p',
        saleId: 's',
        productId: 'p',
        quantity: 1,
        unitPriceIQD: 100,
        totalIQD: 100,
      ),
    ]);
    expect((await repository.product('p'))!.stockQuantity, 1);
    expect(
      (await repository.inventoryMovements(productId: 'p')).single.type,
      InventoryMovementType.sale,
    );
  });

  test('duplicate barcodes and insufficient stock are rejected', () async {
    final database = InMemoryDatabaseService()..open();
    final repository = QistiRepositoryImpl(database);
    final now = DateTime.now();
    await repository.saveProduct(
      Product(
        id: 'one',
        name: 'One',
        barcode: 'same',
        salePriceIQD: 10,
        stockQuantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await expectLater(
      repository.saveProduct(
        Product(
          id: 'two',
          name: 'Two',
          barcode: 'same',
          salePriceIQD: 10,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      repository.createSale(
        Sale(
          id: 'too-many',
          subtotalIQD: 20,
          totalIQD: 20,
          paidAmountIQD: 20,
          type: SaleType.cash,
          createdAt: now,
        ),
        [
          const SaleItem(
            id: 'too-many-one',
            saleId: 'too-many',
            productId: 'one',
            quantity: 2,
            unitPriceIQD: 10,
            totalIQD: 20,
          ),
        ],
      ),
      throwsStateError,
    );
    expect((await repository.sales()), isEmpty);
    expect((await repository.product('one'))!.stockQuantity, 1);
  });

  test('returns restore stock and cannot exceed sold quantity', () async {
    final database = InMemoryDatabaseService()..open();
    final repository = QistiRepositoryImpl(database);
    final now = DateTime.now();
    await repository.saveProduct(
      Product(
        id: 'p',
        name: 'Item',
        barcode: '',
        salePriceIQD: 25,
        stockQuantity: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.createSale(
      Sale(
        id: 's',
        subtotalIQD: 25,
        totalIQD: 25,
        paidAmountIQD: 25,
        type: SaleType.cash,
        createdAt: now,
      ),
      [
        const SaleItem(
          id: 'item',
          saleId: 's',
          productId: 'p',
          quantity: 1,
          unitPriceIQD: 25,
          totalIQD: 25,
        ),
      ],
    );
    final returned = DateTime.now();
    await repository.registerReturn(
      SaleReturn(
        id: 'r',
        saleId: 's',
        saleItemId: 'item',
        productId: 'p',
        quantity: 1,
        amountIQD: 25,
        createdAt: returned,
      ),
    );
    expect((await repository.product('p'))!.stockQuantity, 1);
    await expectLater(
      repository.registerReturn(
        SaleReturn(
          id: 'r2',
          saleId: 's',
          saleItemId: 'item',
          productId: 'p',
          quantity: 1,
          amountIQD: 25,
          createdAt: returned,
        ),
      ),
      throwsStateError,
    );
  });
}
