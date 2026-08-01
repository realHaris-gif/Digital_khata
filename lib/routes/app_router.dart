import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/screens/content/admin/super_admin_screen.dart';
import 'package:digital_khata/screens/tools/qr_generator_screen.dart';

import 'package:digital_khata/screens/tools/global_search_screen.dart';
import 'package:digital_khata/screens/content/settings/settings_screen.dart';
import 'package:digital_khata/screens/content/store/store_dashboard_screen.dart';
import 'package:digital_khata/screens/content/store/public_storefront_screen.dart';

// Models
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/staff_model.dart';

// Auth & Core Screens
import 'package:digital_khata/screens/auth/auth_screen.dart';
import 'package:digital_khata/screens/auth/login_screen.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';

// Tools Module Screens
import 'package:digital_khata/screens/tools/ios_calculator_screen.dart';
import 'package:digital_khata/screens/tools/business_card_screen.dart';

// Staff Book Module Screens (Phase 5)
import 'package:digital_khata/screens/content/staff/staff_dashboard_screen.dart';
import 'package:digital_khata/screens/content/staff/add_edit_employee_screen.dart';
import 'package:digital_khata/screens/content/staff/attendence_screen.dart';
import 'package:digital_khata/screens/content/staff/payroll_screen.dart';

// Inventory Module Screens (Phase 3)
import 'package:digital_khata/screens/content/inventory/inventory_dashboard_screen.dart';
import 'package:digital_khata/screens/content/inventory/products_list_screen.dart';
import 'package:digital_khata/screens/content/inventory/product_detail_screen.dart';
import 'package:digital_khata/screens/content/inventory/add_edit_product_screen.dart';
import 'package:digital_khata/screens/content/inventory/categories_screen.dart';
import 'package:digital_khata/screens/content/inventory/inventory_analytics_screen.dart';

// Bill Book Module Screens (Phase 4)
import 'package:digital_khata/screens/content/bill_book/invoice_dashboard_screen.dart';
import 'package:digital_khata/screens/content/bill_book/invoices_list_screen.dart';
import 'package:digital_khata/screens/content/bill_book/add_edit_invoice_screen.dart';
import 'package:digital_khata/screens/content/bill_book/invoice_detail_screen.dart';
import 'package:digital_khata/screens/content/bill_book/bill_analytics_screen.dart';

// Account Screens
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
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/toggle_login_signup_screen',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // =========================================================
      // TOOLS MODULE ROUTES (CALCULATOR & BUSINESS CARD)
      // =========================================================
      GoRoute(
        path: '/tools/calculator',
        builder: (context, state) => const IosCalculatorScreen(),
      ),
      GoRoute(
        path: '/tools/business-card',
        builder: (context, state) => const BusinessCardScreen(),
      ),

      // =========================================================
      // PHASE 5: STAFF BOOK (EMPLOYEE MANAGEMENT) ROUTES
      // =========================================================
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/add',
        builder: (context, state) {
          final employeeToEdit = state.extra as Employee?;
          return AddEditEmployeeScreen(employeeToEdit: employeeToEdit);
        },
      ),
      GoRoute(
        path: '/staff/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/staff/payroll',
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
  path: '/admin',
  builder: (context, state) => const SuperAdminScreen(),
),
GoRoute(
  path: '/tools/qr-generator',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    final data = extra?['data'] ?? 'https://digitalkhata.app';
    final title = extra?['title'] ?? 'Digital Khata QR';
    return QrGeneratorScreen(qrData: data, title: title);
  },
),
      // =========================================================
      // PHASE 4: BILL BOOK (INVOICE MANAGEMENT) ROUTES
      // =========================================================
      GoRoute(
        path: '/bill-book',
        builder: (context, state) => const InvoiceDashboardScreen(),
      ),
      GoRoute(
        path: '/bill-book/invoices',
        builder: (context, state) => const InvoicesListScreen(),
      ),
      GoRoute(
        path: '/bill-book/create',
        builder: (context, state) {
          final invoiceToEdit = state.extra as Invoice?;
          return AddEditInvoiceScreen(invoiceToEdit: invoiceToEdit);
        },
      ),
      GoRoute(
        path: '/bill-book/invoice/:id',
        builder: (context, state) {
          final invoiceId = state.pathParameters['id'] ?? '';
          return InvoiceDetailScreen(invoiceId: invoiceId);
        },
      ),
      GoRoute(
        path: '/bill-book/analytics',
        builder: (context, state) => const BillAnalyticsScreen(),
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
  path: '/store',
  builder: (context, state) => const StoreDashboardScreen(),
),
GoRoute(
  path: '/store/:slug',
  builder: (context, state) {
    final slug = state.pathParameters['slug'] ?? '';
    return PublicStorefrontScreen(storeSlug: slug);
  },
),
GoRoute(
  path: '/search',
  builder: (context, state) => const GlobalSearchScreen(),
),
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreen(),
),
      GoRoute(
        path: '/ledger',
        builder: (context, state) => const UnifiedLedgerScreen(),
      ),
    ],
  );
}