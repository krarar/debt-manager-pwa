import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/customers/presentation/customers_page.dart';
import '../../features/customers/presentation/customer_details_page.dart';
import '../../features/customers/presentation/add_customer_page.dart';
import '../../features/installments/presentation/add_plan_page.dart';
import '../../features/installments/presentation/add_debt_page.dart';
import '../../features/installments/presentation/debt_entry_page.dart';
import '../../features/installments/presentation/plan_details_page.dart';
import '../../features/installments/presentation/edit_plan_page.dart';
import '../../features/installments/presentation/installments_page.dart';
import '../../features/payments/presentation/payments_page.dart';
import '../../features/receipts/presentation/receipts_page.dart';
import '../../features/receipts/presentation/receipt_details_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/products/presentation/products_page.dart';
import '../../features/sales/presentation/sales_page.dart';
import '../../features/inventory/presentation/inventory_page.dart';
import '../../features/backup/presentation/backup_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/splash'),
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/add-debt',
          builder: (context, state) => const DebtEntryPage(),
          routes: [
            GoRoute(
              path: 'form',
              builder: (context, state) => AddDebtPage(
                customerId: state.uri.queryParameters['customerId'],
              ),
            ),
            GoRoute(
              path: 'existing',
              builder: (context, state) => const ExistingCustomerPage(),
            ),
            GoRoute(
              path: 'new-customer',
              builder: (context, state) =>
                  const AddCustomerPage(continueToDebt: true),
            ),
          ],
        ),
        GoRoute(
          path: '/installments',
          builder: (context, state) => const InstallmentsPage(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersPage(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddCustomerPage(),
            ),
            GoRoute(
              path: ':customerId',
              builder: (context, state) => CustomerDetailsPage(
                customerId: state.pathParameters['customerId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => AddCustomerPage(
                    customerId: state.pathParameters['customerId']!,
                  ),
                ),
                GoRoute(
                  path: 'add-plan',
                  builder: (context, state) => AddPlanPage(
                    customerId: state.pathParameters['customerId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/plans/:planId',
          builder: (context, state) =>
              PlanDetailsPage(planId: state.pathParameters['planId']!),
        ),
        GoRoute(
          path: '/plans/:planId/edit',
          builder: (context, state) =>
              EditPlanPage(planId: state.pathParameters['planId']!),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsPage(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/sales',
          builder: (context, state) => const SalesPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const NewSalePage(),
            ),
            GoRoute(
              path: ':saleId',
              builder: (context, state) =>
                  SaleDetailsPage(saleId: state.pathParameters['saleId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsPage(),
        ),
        GoRoute(
          path: '/receipts',
          builder: (context, state) => const ReceiptsPage(),
          routes: [
            GoRoute(
              path: ':receiptId',
              builder: (context, state) => ReceiptDetailsPage(
                receiptId: state.pathParameters['receiptId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/backup',
          builder: (context, state) => const BackupPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
