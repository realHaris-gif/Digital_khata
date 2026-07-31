import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Controllers & Auth
import 'package:digital_khata/controller/auth.dart';
import 'package:digital_khata/controller/toggle_login_signup.dart';

// Core Content Screens
import 'package:digital_khata/screens/content/home/home_screen.dart';
import 'package:digital_khata/screens/content/people/list_people_screen.dart';
import 'package:digital_khata/screens/content/expense/analytics_screen.dart';
import 'package:digital_khata/screens/content/expense/expense_screen.dart';
import 'package:digital_khata/screens/customer/customer_screen.dart';

// Phase 2 Module Screens (Suppliers, Accounts, Unified Ledger)
import 'package:digital_khata/screens/content/supplier/suppliers_screen.dart';
import 'package:digital_khata/screens/content/supplier/add_supplier_screen.dart';
import 'package:digital_khata/screens/content/supplier/supplier_detail_screen.dart';
import 'package:digital_khata/screens/content/account/accounts_screen.dart';
import 'package:digital_khata/screens/content/account/add_account_screen.dart';
import 'package:digital_khata/screens/content/account/account_detail_screen.dart';
import 'package:digital_khata/screens/content/ledger/unified_ledger_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 1. Root / Auth Check Route
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const AuthController();
        },
      ),

      // 2. Auth Flow
      GoRoute(
        path: '/toggle_login_signup_screen',
        builder: (BuildContext context, GoRouterState state) {
          return const ToggleLoginSignup();
        },
      ),

      // 3. Core App Home & Dashboard
      GoRoute(
        path: '/home_screen',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),

      // 4. Customers Module
      GoRoute(
        path: '/list_people_screen',
        builder: (BuildContext context, GoRouterState state) {
          return const ListPeopleScreen();
        },
      ),
      GoRoute(
        path: '/customers',
        builder: (BuildContext context, GoRouterState state) {
          return const ListPeopleScreen();
        },
      ),
      GoRoute(
        path: '/customer/:customerId',
        builder: (BuildContext context, GoRouterState state) {
          final customerId = state.pathParameters['customerId'] ?? '';
          final extra = state.extra;
          String customerName = 'Customer';
          String? customerPhone;
          if (extra is Map) {
            customerName = extra['name']?.toString() ?? customerName;
            customerPhone = extra['phone']?.toString();
          } else {
            customerName =
                state.uri.queryParameters['name'] ?? customerName;
            customerPhone = state.uri.queryParameters['phone'];
          }
          return CustomerDetailScreen(
            customerId: customerId,
            customerName: customerName,
            customerPhone: customerPhone,
          );
        },
      ),

      // 5. Suppliers Module (Phase 2)
      GoRoute(
        path: '/suppliers',
        builder: (BuildContext context, GoRouterState state) {
          return const SuppliersScreen();
        },
      ),
      GoRoute(
        path: '/add-supplier',
        builder: (BuildContext context, GoRouterState state) {
          return const AddEditSupplierScreen();
        },
      ),
      GoRoute(
        path: '/edit-supplier/:supplierId',
        builder: (BuildContext context, GoRouterState state) {
          final supplierId = state.pathParameters['supplierId'];
          return AddEditSupplierScreen(
            supplierId: supplierId,
          );
        },
      ),
      GoRoute(
        path: '/supplier/:supplierId',
        builder: (BuildContext context, GoRouterState state) {
          final supplierId = state.pathParameters['supplierId'] ?? '';
          return SupplierDetailScreen(
            supplierId: supplierId,
          );
        },
      ),

      // 6. Cash & Bank Accounts Module (Phase 2)
      GoRoute(
        path: '/accounts',
        builder: (BuildContext context, GoRouterState state) {
          return const AccountsScreen();
        },
      ),
      GoRoute(
        path: '/add-account',
        builder: (BuildContext context, GoRouterState state) {
          return const AddEditAccountScreen();
        },
      ),
      GoRoute(
        path: '/edit-account/:accountId',
        builder: (BuildContext context, GoRouterState state) {
          final accountId = state.pathParameters['accountId'];
          return AddEditAccountScreen(
            accountId: accountId,
          );
        },
      ),
      GoRoute(
        path: '/account/:accountId',
        builder: (BuildContext context, GoRouterState state) {
          final accountId = state.pathParameters['accountId'] ?? '';
          return AccountDetailScreen(
            accountId: accountId,
          );
        },
      ),

      // 7. Unified Party Ledger (Phase 2)
      GoRoute(
        path: '/ledger',
        builder: (BuildContext context, GoRouterState state) {
          return const UnifiedLedgerScreen();
        },
      ),

      // 8. Analytics & Expenses
      GoRoute(
        path: '/analytics_screen',
        builder: (BuildContext context, GoRouterState state) {
          return const AnalyticsScreen();
        },
      ),
      GoRoute(
        path: '/expense_screen',
        builder: (BuildContext context, GoRouterState state) {
          return const ExpenseScreen();
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.error}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}