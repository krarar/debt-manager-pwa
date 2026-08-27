class SaleItem {
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPriceIQD,
    required this.totalIQD,
  });

  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final int unitPriceIQD;
  final int totalIQD;
}
