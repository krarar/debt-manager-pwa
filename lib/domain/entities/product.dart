class Product {
  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    this.categoryId,
    required this.salePriceIQD,
    this.costPriceIQD = 0,
    this.stockQuantity = 0,
    this.minimumStock = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String barcode;
  final String? categoryId;
  final int salePriceIQD;
  final int costPriceIQD;
  final int stockQuantity;
  final int minimumStock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get priceIQD => salePriceIQD;
  int get stock => stockQuantity;

  Product copyWith({
    String? name,
    String? barcode,
    String? categoryId,
    int? salePriceIQD,
    int? costPriceIQD,
    int? stockQuantity,
    int? minimumStock,
    bool? isActive,
  }) => Product(
    id: id,
    name: name ?? this.name,
    barcode: barcode ?? this.barcode,
    categoryId: categoryId ?? this.categoryId,
    salePriceIQD: salePriceIQD ?? this.salePriceIQD,
    costPriceIQD: costPriceIQD ?? this.costPriceIQD,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    minimumStock: minimumStock ?? this.minimumStock,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
