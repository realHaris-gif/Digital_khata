import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/screens/auth/login_screen.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';


import 'package:digital_khata/screens/content/inventory/inventory_dashboard_screen.dart';
import 'package:digital_khata/screens/content/inventory/products_list_screen.dart';
import 'package:digital_khata/screens/content/inventory/product_detail_screen.dart';
import 'package:digital_khata/screens/content/inventory/add_edit_product_screen.dart';
import 'package:digital_khata/screens/content/inventory/categories_screen.dart';
import 'package:digital_khata/screens/content/inventory/inventory_analytics_screen.dart';


import 'package:digital_khata/screens/content/account/accounts_screen.dart';
import 'package:digital_khata/screens/content/account/account_detail_screen.dart';
import 'package:digital_khata/screens/content/account/add_account_screen.dart';

// Expense, Supplier & Ledger Screens
import 'package:digital_khata/screens/content/expense/expense_screen.dart';
import 'package:digital_khata/screens/content/supplier/suppliers_screen.dart';
import 'package:digital_khata/screens/content/ledger/unified_ledger_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.uri.toString() == '/login';

      if (session == null && !isLoggingIn) {
        return '/login';
      }
      if (session != null && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
  path: '/login',
  builder: (context, state) => LoginScreen(
    onTap: () {},
    onCustomerTap: () {},
  ),
),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // =========================================================
      // PHASE 3: STOCK BOOK (INVENTORY MANAGEMENT) ROUTES
      // =========================================================
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryDashboardScreen(),
      ),
      GoRoute(
        path: '/inventory/products',
        builder: (context, state) => const ProductsListScreen(),
      ),
      GoRoute(
        path: '/inventory/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/inventory/add-product',
        builder: (context, state) {
          final productToEdit = state.extra as Product?;
          return AddEditProductScreen(productToEdit: productToEdit);
        },
      ),
      GoRoute(
        path: '/inventory/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/inventory/analytics',
        builder: (context, state) => const InventoryAnalyticsScreen(),
      ),

      // =========================================================
      // ACCOUNTS & OTHER MODULE ROUTES
      // =========================================================
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/add-account',
        builder: (context, state) {
          final accountId = state.extra as String?;
          return AddEditAccountScreen(accountId: accountId);
        },
      ),
      GoRoute(
        path: '/account/:id',
        builder: (context, state) {
          final accountId = state.pathParameters['id'] ?? '';
          return AccountDetailScreen(accountId: accountId);
        },
      ),
      GoRoute(
        path: '/expense_screen',
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/ledger',
        builder: (context, state) => const UnifiedLedgerScreen(),
      ),
    ],
  );
}