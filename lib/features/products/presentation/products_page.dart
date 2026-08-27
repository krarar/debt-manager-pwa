import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/inventory_movement.dart';
import '../../../domain/entities/product.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider(query));
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.products,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _editProduct(context),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addProduct),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: context.l10n.categories,
                  onPressed: () => _addCategory(context),
                  icon: const Icon(Icons.category_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.search,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => items.isEmpty
                    ? Center(child: Text(context.l10n.noProducts))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          final product = items[index];
                          final low =
                              product.stockQuantity <= product.minimumStock;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: low
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.errorContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                child: Icon(
                                  low ? Icons.warning_amber : Icons.inventory_2,
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                '${product.barcode.isEmpty ? '' : '${product.barcode} · '}${product.salePriceIQD} ${context.l10n.currency}',
                              ),
                              trailing: IconButton(
                                tooltip: context.l10n.addStock,
                                onPressed: () => _addStock(context, product),
                                icon: const Icon(Icons.add_box_outlined),
                              ),
                              onTap: () => _editProduct(context, product),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/sales/new'),
        icon: const Icon(Icons.point_of_sale),
        label: Text(context.l10n.newSale),
      ),
    );
  }

  Future<void> _editProduct(BuildContext context, [Product? existing]) async {
    final name = TextEditingController(text: existing?.name);
    final barcode = TextEditingController(text: existing?.barcode);
    final price = TextEditingController(
      text: '${existing?.salePriceIQD ?? ''}',
    );
    final cost = TextEditingController(text: '${existing?.costPriceIQD ?? 0}');
    final stock = TextEditingController(
      text: '${existing?.stockQuantity ?? 0}',
    );
    final minimum = TextEditingController(
      text: '${existing?.minimumStock ?? 0}',
    );
    final categories =
        ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    String? categoryId = existing?.categoryId;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? context.l10n.addProduct
                : context.l10n.editProduct,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: context.l10n.productName,
                  ),
                ),
                TextField(
                  controller: barcode,
                  decoration: InputDecoration(labelText: context.l10n.barcode),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.salePrice,
                  ),
                ),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.costPrice,
                  ),
                ),
                TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: existing == null,
                  decoration: InputDecoration(labelText: context.l10n.stock),
                ),
                TextField(
                  controller: minimum,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.minimumStock,
                  ),
                ),
                DropdownButtonFormField<String?>(
                  value: categoryId,
                  decoration: InputDecoration(labelText: context.l10n.category),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.l10n.uncategorized),
                    ),
                    ...categories.map(
                      (item) => DropdownMenuItem<String?>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => categoryId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final now = DateTime.now();
                final product = Product(
                  id: existing?.id ?? 'product-${now.microsecondsSinceEpoch}',
                  name: name.text.trim(),
                  barcode: barcode.text.trim(),
                  categoryId: categoryId,
                  salePriceIQD: int.tryParse(price.text) ?? -1,
                  costPriceIQD: int.tryParse(cost.text) ?? 0,
                  stockQuantity: int.tryParse(stock.text) ?? -1,
                  minimumStock: int.tryParse(minimum.text) ?? 0,
                  createdAt: existing?.createdAt ?? now,
                  updatedAt: now,
                );
                try {
                  await ref.read(repositoryProvider).saveProduct(product);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on StateError {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.barcodeExists)),
                    );
                  }
                }
              },
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    barcode.dispose();
    price.dispose();
    cost.dispose();
    stock.dispose();
    minimum.dispose();
    if (saved == true) {
      ref.invalidate(productsProvider(query));
      ref.invalidate(productProvider(existing?.id ?? ''));
    }
  }

  Future<void> _addCategory(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.categories),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.l10n.category),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      final now = DateTime.now();
      await ref
          .read(repositoryProvider)
          .saveCategory(
            Category(
              id: 'category-${now.microsecondsSinceEpoch}',
              name: value,
              createdAt: now,
              updatedAt: now,
            ),
          );
      ref.invalidate(categoriesProvider);
    }
  }

  Future<void> _addStock(BuildContext context, Product product) async {
    final controller = TextEditingController();
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.addStock),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.quantity),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantity != null && quantity > 0) {
      final now = DateTime.now();
      await ref
          .read(repositoryProvider)
          .recordInventoryMovement(
            InventoryMovement(
              id: 'purchase-${now.microsecondsSinceEpoch}',
              productId: product.id,
              type: InventoryMovementType.purchase,
              quantity: quantity,
              stockBefore: product.stockQuantity,
              stockAfter: product.stockQuantity + quantity,
              createdAt: now,
            ),
          );
      ref.invalidate(productsProvider(query));
    }
  }
}
