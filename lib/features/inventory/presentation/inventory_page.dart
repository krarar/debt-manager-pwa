import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/inventory_movement.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider(''));
    final movements = ref.watch(inventoryMovementsProvider(null));
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.inventory,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/products'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(context.l10n.products),
                ),
              ],
            ),
            const SizedBox(height: 16),
            products.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
              data: (items) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (product) => Chip(
                        avatar: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                        ),
                        label: Text(
                          '${product.name}: ${product.stockQuantity}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.l10n.inventory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            movements.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
              data: (items) => items.isEmpty
                  ? Text(context.l10n.noProducts)
                  : Column(
                      children: items
                          .map(
                            (movement) => ListTile(
                              leading: Icon(_icon(movement.type)),
                              title: Text(
                                '${movement.quantity > 0 ? '+' : ''}${movement.quantity} · ${movement.productId}',
                              ),
                              subtitle: Text(
                                movement.createdAt.toLocal().toString(),
                              ),
                              trailing: Text('${movement.stockAfter}'),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(InventoryMovementType type) => switch (type) {
    InventoryMovementType.purchase => Icons.add_box_outlined,
    InventoryMovementType.sale => Icons.remove_shopping_cart_outlined,
    InventoryMovementType.returned => Icons.assignment_return_outlined,
    InventoryMovementType.adjustment => Icons.tune,
  };
}
