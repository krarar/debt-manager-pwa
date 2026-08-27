import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/sale_return.dart';
import '../../../domain/entities/installment_plan.dart';
import '../../../domain/entities/payment.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
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
                    context.l10n.sales,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/sales/new'),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.newSale),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sales.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => items.isEmpty
                    ? Center(child: Text(context.l10n.noSales))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          final sale = items[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.point_of_sale),
                            ),
                            title: Text(
                              '${context.l10n.saleDetails} · ${sale.id}',
                            ),
                            subtitle: Text(
                              '${_localizedSaleType(context, sale.type)} · '
                              '${sale.createdAt.toLocal().toString().split(' ').first}',
                            ),
                            trailing: Text(
                              '${sale.totalIQD} ${context.l10n.currency}',
                            ),
                            onTap: () => context.push('/sales/${sale.id}'),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewSalePage extends ConsumerStatefulWidget {
  const NewSalePage({super.key});
  @override
  ConsumerState<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends ConsumerState<NewSalePage> {
  final Map<String, int> quantities = {};
  SaleType type = SaleType.cash;
  String? customerId;
  PaymentMethod paymentMethod = PaymentMethod.cash;
  final paid = TextEditingController();
  final discount = TextEditingController(text: '0');
  final count = TextEditingController(text: '3');
  bool saving = false;
  String? error;

  @override
  void dispose() {
    paid.dispose();
    discount.dispose();
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider(''));
    final customers = ref.watch(customersProvider(''));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newSale)),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => LayoutBuilder(
          builder: (context, constraints) {
            final selected = items
                .where((p) => (quantities[p.id] ?? 0) > 0)
                .toList();
            final total = selected.fold<int>(
              0,
              (sum, p) => sum + p.salePriceIQD * (quantities[p.id] ?? 0),
            );
            final discountAmount = int.tryParse(discount.text.trim()) ?? 0;
            final finalAmount = total - discountAmount;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  context.l10n.addItem,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (product) => _ProductQuantityRow(
                    product: product,
                    quantity: quantities[product.id] ?? 0,
                    onChanged: (value) =>
                        setState(() => quantities[product.id] = value),
                  ),
                ),
                const Divider(height: 28),
                TextField(
                  controller: discount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: context.l10n.discount),
                ),
                const SizedBox(height: 12),
                customers.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (items) => DropdownButtonFormField<String?>(
                    value: customerId,
                    decoration: InputDecoration(
                      labelText: context.l10n.customerOptional,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(context.l10n.selectCustomer),
                      ),
                      ...items.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => customerId = value),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SaleType>(
                  value: type,
                  decoration: InputDecoration(labelText: context.l10n.saleType),
                  items: [
                    DropdownMenuItem(
                      value: SaleType.cash,
                      child: Text(context.l10n.cashSale),
                    ),
                    DropdownMenuItem(
                      value: SaleType.partial,
                      child: Text(context.l10n.partialSale),
                    ),
                    DropdownMenuItem(
                      value: SaleType.installment,
                      child: Text(context.l10n.installmentSale),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    if (value != null) type = value;
                    if (type == SaleType.cash) paid.text = '$total';
                  }),
                ),
                if (type != SaleType.cash) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: paid,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.paidAmount,
                    ),
                  ),
                ],
                if (type == SaleType.installment) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: count,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.installmentCountSales,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  '${context.l10n.amount}: $finalAmount ${context.l10n.currency}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () => _save(selected, total, discountAmount),
                  icon: const Icon(Icons.check),
                  label: Text(context.l10n.completeSale),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(
    List<Product> selected,
    int total,
    int discountAmount,
  ) async {
    if (discountAmount < 0 || discountAmount > total) {
      setState(() => error = context.l10n.invalidDiscount);
      return;
    }
    final finalAmount = total - discountAmount;
    final paidAmount = type == SaleType.cash
        ? finalAmount
        : int.tryParse(paid.text) ?? 0;
    if (selected.isEmpty) {
      setState(() => error = context.l10n.noSaleItems);
      return;
    }
    if (type == SaleType.installment && customerId == null) {
      setState(() => error = context.l10n.selectCustomer);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final now = DateTime.now();
    final saleId = 'sale-${now.microsecondsSinceEpoch}';
    final items = selected.map((product) {
      final quantity = quantities[product.id]!;
      return SaleItem(
        id: '$saleId-${product.id}',
        saleId: saleId,
        productId: product.id,
        quantity: quantity,
        unitPriceIQD: product.salePriceIQD,
        totalIQD: product.salePriceIQD * quantity,
      );
    }).toList();
    final sale = Sale(
      id: saleId,
      customerId: customerId,
      subtotalIQD: total,
      discountIQD: discountAmount,
      totalIQD: finalAmount,
      paidAmountIQD: paidAmount,
      type: type,
      createdAt: now,
      paymentMethod: paymentMethod,
    );
    try {
      final result = await ref
          .read(repositoryProvider)
          .createSale(
            sale,
            items,
            installmentCount: int.tryParse(count.text) ?? 1,
            recurringPeriod: RecurringPeriod.monthly,
          );
      ref.invalidate(salesProvider);
      ref.invalidate(productsProvider(''));
      if (mounted) context.go('/sales/${result.id}');
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e.toString();
        });
      }
    }
  }
}

class _ProductQuantityRow extends StatelessWidget {
  const _ProductQuantityRow({
    required this.product,
    required this.quantity,
    required this.onChanged,
  });
  final Product product;
  final int quantity;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(product.name),
      subtitle: Text(
        '${product.salePriceIQD} ${context.l10n.currency} · ${product.stockQuantity} ${context.l10n.stock}',
      ),
      trailing: SizedBox(
        width: 130,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$quantity'),
            IconButton(
              onPressed: quantity < product.stockQuantity
                  ? () => onChanged(quantity + 1)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    ),
  );
}

class SaleDetailsPage extends ConsumerWidget {
  const SaleDetailsPage({required this.saleId, super.key});
  final String saleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sale = ref.watch(saleProvider(saleId));
    final items = ref.watch(saleItemsProvider(saleId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.saleDetails)),
      body: sale.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (value) {
          if (value == null) return Center(child: Text(context.l10n.noSales));
          return items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (saleItems) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${value.totalIQD} ${context.l10n.currency}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${_localizedSaleType(context, value.type)} · '
                  '${value.createdAt.toLocal()}',
                ),
                const SizedBox(height: 16),
                ...saleItems.map(
                  (item) => ListTile(
                    title: Text(item.productId),
                    subtitle: Text(
                      '${item.quantity} × ${item.unitPriceIQD} ${context.l10n.currency}',
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _returnItem(context, ref, value, item),
                      child: Text(context.l10n.returnItem),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _returnItem(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    SaleItem item,
  ) async {
    final controller = TextEditingController(text: '1');
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.returnItem),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.returnQuantity),
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
    if (quantity == null || quantity <= 0) return;
    try {
      await ref
          .read(repositoryProvider)
          .registerReturn(
            SaleReturn(
              id: 'return-${DateTime.now().microsecondsSinceEpoch}',
              saleId: sale.id,
              saleItemId: item.id,
              productId: item.productId,
              quantity: quantity,
              amountIQD: quantity * item.unitPriceIQD,
              createdAt: DateTime.now(),
            ),
          );
      ref.invalidate(productsProvider(''));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.returnSaved)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

String _localizedSaleType(BuildContext context, SaleType type) =>
    switch (type) {
      SaleType.cash => context.l10n.cashSale,
      SaleType.partial => context.l10n.partialSale,
      SaleType.installment => context.l10n.installmentSale,
    };
