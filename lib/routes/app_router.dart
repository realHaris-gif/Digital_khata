import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens & Models Imports
import 'package:digital_khata/screens/content/supplier/purchase_order_screen.dart';
import 'package:digital_khata/screens/content/admin/super_admin_screen.dart';
import 'package:digital_khata/screens/tools/qr_generator_screen.dart';
import 'package:digital_khata/screens/tools/global_search_screen.dart';
import 'package:digital_khata/screens/content/settings/settings_screen.dart';
import 'package:digital_khata/screens/content/store/store_dashboard_screen.dart';
import 'package:digital_khata/screens/content/store/public_storefront_screen.dart';
import 'package:digital_khata/models/supplier_model.dart';
import '../screens/content/supplier/supplier_detail_screen.dart';
import 'package:digital_khata/screens/content/notification/notification_screen.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/staff_model.dart';

// Auth & Core Screens
import 'package:digital_khata/screens/auth/auth_screen.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';

// Security Lock Screen & Service Imports
import '../screens/content/security/lock_screen.dart';
import 'package:digital_khata/services/security_service.dart';

// Payment Reminders Screen Import
import '../screens/content/people/payment_reminder_screen.dart';

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
import 'package:digital_khata/screens/content/expense/analytics_screen.dart';
import 'package:digital_khata/screens/content/supplier/suppliers_screen.dart';
import 'package:digital_khata/screens/content/supplier/add_supplier_screen.dart';
import 'package:digital_khata/screens/content/ledger/unified_ledger_screen.dart';


/// Helper wrapper to listen to Supabase auth state changes inside GoRouter cleanly
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    stream.listen((_) => notifyListeners());
  }
}

/// Helper wrapper to combine multiple listenables for GoRouter refresh list
class ListenableMerge extends ChangeNotifier {
  ListenableMerge(List<Listenable> listenables) {
    for (var listenable in listenables) {
      listenable.addListener(notifyListeners);
    }
  }
}

/// Custom Page Transition - Fade + Slide (prevents screen blending)
class _FadeSlideTransition extends Page {
  final Widget child;
  final String name;

  _FadeSlideTransition({
    required this.child,
    required this.name,
  }) : super(key: ValueKey(name), name: name);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        final tween = Tween(begin: begin, end: end);
        final fadeAnimation = animation.drive(tween);

        const slideBegin = Offset(0.0, 0.02);
        const slideEnd = Offset.zero;
        final slideTween = Tween(begin: slideBegin, end: slideEnd);
        final slideAnimation = animation.drive(slideTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
}

class AppRouter {
  static bool isLoggingOut = false;
  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: ListenableMerge([
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
      SecurityService(), // Listens to app lock state changes so GoRouter updates instantly on unlock
    ]),
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final currentPath = state.uri.toString();
      final isAuthRoute = currentPath == '/login' || currentPath == '/toggle_login_signup_screen';

      // 1. If not logged in and not already on login routes, force login
      if (session == null) {
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }

      // 2. Check if App Lock Screen is required (User has PIN set and app is locked)
      final shouldLock = await SecurityService.shouldShowLockScreen();
      if (shouldLock) {
        if (currentPath != '/lock') {
          return '/lock';
        }
        return null; // Already on lock screen, do nothing
      } else {
        // If it shouldn't lock anymore (unlocked via PIN/Biometric) but we are stuck on /lock, send away
        if (currentPath == '/lock') {
          // Re-evaluate admin or regular user dashboard target
          try {
            final userId = session.user.id;
            final profileRes = await Supabase.instance.client
                .from('profiles')
                .select('is_super_admin')
                .eq('id', userId)
                .maybeSingle();
            if (profileRes != null && profileRes['is_super_admin'] == true) {
              return '/admin';
            }
          } catch (_) {}
          return '/';
        }
      }

      // 3. If logged in, check profile status (super admin & blocked checks)
      try {
        final userId = session.user.id;
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('is_super_admin, is_blocked')
            .eq('id', userId)
            .maybeSingle();

        // If profile doesn't exist yet or user is blocked
        if (profileRes == null || profileRes['is_blocked'] == true) {
          await Supabase.instance.client.auth.signOut();
          return '/login';
        }

        final bool isSuperAdmin = profileRes['is_super_admin'] == true;

        // 4. Strict Admin & User Role Isolation
        if (isSuperAdmin) {
          // Admins can see /admin. If they try to go anywhere else (except login), force them to /admin
          if (currentPath != '/admin' && !isAuthRoute) {
            return '/admin';
          }
        } else {
          // Regular users are locked out of /admin. If they try, send them to home /
          if (currentPath == '/admin' || isAuthRoute) {
            return '/';
          }
        }
      } catch (e) {
        debugPrint('Router redirect error: $e');
      }

      return null;
    },
    routes: [
      // =========================================================
      // AUTH & LOCK ROUTES
      // =========================================================
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final initialStage = AppRouter.isLoggingOut ? 'welcome' : 'splash';
          AppRouter.isLoggingOut = false;
          return _FadeSlideTransition(
            name: 'login',
            child: AuthScreen(initialStage: initialStage),
          );
        },
      ),
      GoRoute(
        path: '/toggle_login_signup_screen',
        pageBuilder: (context, state) {
          final initialStage = state.extra as String? ?? 'splash';
          return _FadeSlideTransition(
            name: 'toggle_auth',
            child: AuthScreen(initialStage: initialStage),
          );
        },
      ),
      GoRoute(
        path: '/lock',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'lock_screen',
          child: const LockScreen(),
        ),
      ),

      // Home route - main scaffold with tabs (Regular Users Only)
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'home',
          child: const HomeScreen(),
        ),
      ),

      // =========================================================
      // SUPER ADMIN PANEL ROUTE (Admin Only)
      // =========================================================
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'admin',
          child: const SuperAdminScreen(),
        ),
      ),

      // =========================================================
      // CUSTOMER PAYMENT REMINDERS ROUTE
      // =========================================================
      GoRoute(
        path: '/customers/reminders',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'payment_reminders',
          child: const PaymentRemindersScreen(),
        ),
      ),

      // =========================================================
      // TOOLS MODULE ROUTES
      // =========================================================
      GoRoute(
        path: '/tools/calculator',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'calculator',
          child: const IosCalculatorScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/business-card',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'business_card',
          child: const BusinessCardScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/qr-generator',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final data = extra?['data'] ?? 'https://digitalkhata.app';
          final title = extra?['title'] ?? 'Digital Khata QR';
          return _FadeSlideTransition(
            name: 'qr_generator',
            child: QrGeneratorScreen(qrData: data, title: title),
          );
        },
      ),

      // =========================================================
      // STAFF BOOK ROUTES
      // =========================================================
      GoRoute(
        path: '/staff',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'staff_dashboard',
          child: const StaffDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/staff/add',
        pageBuilder: (context, state) {
          final employeeToEdit = state.extra as Employee?;
          return _FadeSlideTransition(
            name: 'add_employee',
            child: AddEditEmployeeScreen(employeeToEdit: employeeToEdit),
          );
        },
      ),
      GoRoute(
        path: '/staff/attendance',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'attendance',
          child: const AttendanceScreen(),
        ),
      ),
      GoRoute(
        path: '/staff/payroll',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'payroll',
          child: const PayrollScreen(),
        ),
      ),

      // =========================================================
      // BILL BOOK ROUTES
      // =========================================================
      GoRoute(
        path: '/bill-book',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'invoice_dashboard',
          child: const InvoiceDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/bill-book/invoices',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'invoices_list',
          child: const InvoicesListScreen(),
        ),
      ),
      GoRoute(
        path: '/bill-book/create',
        pageBuilder: (context, state) {
          final invoiceToEdit = state.extra as Invoice?;
          return _FadeSlideTransition(
            name: 'add_invoice',
            child: AddEditInvoiceScreen(invoiceToEdit: invoiceToEdit),
          );
        },
      ),
      GoRoute(
        path: '/bill-book/invoice/:id',
        pageBuilder: (context, state) {
          final invoiceId = state.pathParameters['id'] ?? '';
          return _FadeSlideTransition(
            name: 'invoice_detail_$invoiceId',
            child: InvoiceDetailScreen(invoiceId: invoiceId),
          );
        },
      ),
      GoRoute(
        path: '/bill-book/analytics',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'bill_analytics',
          child: const BillAnalyticsScreen(),
        ),
      ),

      // =========================================================
      // INVENTORY ROUTES
      // =========================================================
      GoRoute(
        path: '/inventory',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'inventory_dashboard',
          child: const InventoryDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/inventory/products',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'products_list',
          child: const ProductsListScreen(),
        ),
      ),
      GoRoute(
        path: '/inventory/product/:id',
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return _FadeSlideTransition(
            name: 'product_detail_$productId',
            child: ProductDetailScreen(productId: productId),
          );
        },
      ),
      GoRoute(
        path: '/inventory/add-product',
        pageBuilder: (context, state) {
          final productToEdit = state.extra as Product?;
          return _FadeSlideTransition(
            name: 'add_product',
            child: AddEditProductScreen(productToEdit: productToEdit),
          );
        },
      ),
      GoRoute(
        path: '/inventory/categories',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'categories',
          child: const CategoriesScreen(),
        ),
      ),
      GoRoute(
        path: '/inventory/analytics',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'inventory_analytics',
          child: const AnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'analytics',
          child: const AnalyticsScreen(),
        ),
      ),

      // =========================================================
      // ACCOUNTS & OTHER MODULE ROUTES
      // =========================================================
      GoRoute(
        path: '/accounts',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'accounts',
          child: const AccountsScreen(),
        ),
      ),
      GoRoute(
        path: '/add-account',
        pageBuilder: (context, state) {
          final accountId = state.extra as String?;
          return _FadeSlideTransition(
            name: 'add_account',
            child: AddEditAccountScreen(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/account/:id',
        pageBuilder: (context, state) {
          final accountId = state.pathParameters['id'] ?? '';
          return _FadeSlideTransition(
            name: 'account_detail_$accountId',
            child: AccountDetailScreen(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/expense_screen',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'expense',
          child: const ExpenseScreen(),
        ),
      ),
      GoRoute(
        path: '/suppliers',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'suppliers',
          child: const SuppliersScreen(),
        ),
      ),
      GoRoute(
        path: '/suppliers/add',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'add_supplier',
          child: const AddEditSupplierScreen(),
        ),
      ),
      GoRoute(
        path: '/suppliers/purchase-order',
        pageBuilder: (context, state) {
          final preselectedSupplier = state.extra as Supplier?;
          return _FadeSlideTransition(
            name: 'purchase_order',
            child: PurchaseOrderScreen(preselectedSupplier: preselectedSupplier),
          );
        },
      ),
      GoRoute(
        path: '/supplier/:id',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'supplier_detail_${state.pathParameters['id']}',
          child: SupplierDetailScreen(
            supplierId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/store',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'store_dashboard',
          child: const StoreDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/store/:slug',
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return _FadeSlideTransition(
            name: 'storefront_$slug',
            child: PublicStorefrontScreen(storeSlug: slug),
          );
        },
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'global_search',
          child: const GlobalSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'settings',
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/ledger',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'ledger',
          child: const UnifiedLedgerScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _FadeSlideTransition(
          name: 'notifications',
          child: const NotificationCenterScreen(),
        ),
      ),
    ],
  );
}