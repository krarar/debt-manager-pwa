import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/search_result.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(globalSearchProvider(_query));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.search)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _query.trim().isEmpty
                  ? Center(child: Text(context.l10n.searchPrompt))
                  : results.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) =>
                          Center(child: Text(error.toString())),
                      data: (items) => items.isEmpty
                          ? Center(child: Text(context.l10n.noSearchResults))
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final item = items[index];
                                return Card(
                                  child: ListTile(
                                    leading: Icon(_icon(item.type)),
                                    title: Text(item.title),
                                    subtitle: Text(
                                      '${_typeName(context, item.type)} • '
                                      '${item.subtitle}',
                                    ),
                                    onTap: () => context.push(item.route),
                                  ),
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

  IconData _icon(SearchResultType type) => switch (type) {
    SearchResultType.customer => Icons.person_outline,
    SearchResultType.plan => Icons.assignment_outlined,
    SearchResultType.installment => Icons.calendar_month_outlined,
    SearchResultType.payment => Icons.payments_outlined,
    SearchResultType.receipt => Icons.receipt_long_outlined,
    SearchResultType.product => Icons.inventory_2_outlined,
    SearchResultType.sale => Icons.point_of_sale,
  };

  String _typeName(BuildContext context, SearchResultType type) =>
      switch (type) {
        SearchResultType.customer => context.l10n.customers,
        SearchResultType.plan => context.l10n.installmentPlan,
        SearchResultType.installment => context.l10n.installments,
        SearchResultType.payment => context.l10n.payments,
        SearchResultType.receipt => context.l10n.receipts,
        SearchResultType.product => context.l10n.products,
        SearchResultType.sale => context.l10n.sales,
      };
}
