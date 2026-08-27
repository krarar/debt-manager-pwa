class SaleReturn {
  const SaleReturn({
    required this.id,
    required this.saleId,
    required this.saleItemId,
    required this.productId,
    required this.quantity,
    required this.amountIQD,
    required this.createdAt,
    this.reason = '',
  });

  final String id;
  final String saleId;
  final String saleItemId;
  final String productId;
  final int quantity;
  final int amountIQD;
  final DateTime createdAt;
  final String reason;

  int get returnedQuantity => quantity;
}
