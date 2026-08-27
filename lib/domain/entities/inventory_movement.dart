enum InventoryMovementType { purchase, sale, returned, adjustment }

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.unitCostIQD = 0,
    this.referenceId,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String productId;
  final InventoryMovementType type;
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final int unitCostIQD;
  final String? referenceId;
  final String note;
  final DateTime createdAt;

  int get deltaQuantity => quantity;
}
