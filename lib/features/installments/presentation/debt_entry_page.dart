import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';

class DebtEntryPage extends StatelessWidget {
  const DebtEntryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.addDebt)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.l10n.chooseDebtType,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(context.l10n.addDebtSubtitle),
        const SizedBox(height: 24),
        _ChoiceCard(
          icon: Icons.person_add_alt_1_outlined,
          title: context.l10n.newDebt,
          description: context.l10n.newDebtDescription,
          onTap: () => context.push('/add-debt/new-customer'),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          icon: Icons.people_alt_outlined,
          title: context.l10n.existingCustomer,
          description: context.l10n.existingCustomerDescription,
          onTap: () => context.push('/add-debt/existing'),
        ),
      ],
    ),
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class ExistingCustomerPage extends ConsumerStatefulWidget {
  const ExistingCustomerPage({super.key});

  @override
  ConsumerState<ExistingCustomerPage> createState() =>
      _ExistingCustomerPageState();
}

class _ExistingCustomerPageState extends ConsumerState<ExistingCustomerPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider(_query));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.selectExistingCustomer)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: context.l10n.searchCustomers,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: customers.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text(context.l10n.saveFailed)),
                data: (items) => items.isEmpty
                    ? Center(child: Text(context.l10n.noMatchingCustomers))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final customer = items[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  customer.name.isEmpty
                                      ? '?'
                                      : customer.name[0].toUpperCase(),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: customer.phone.isEmpty
                                  ? null
                                  : Text(customer.phone),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                '/add-debt/form?customerId=${customer.id}',
                              ),
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
}
