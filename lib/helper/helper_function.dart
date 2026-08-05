import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Formats standard double monetary values without dividing by 100.
String formatCurrency(double amount) {
  return amount.toStringAsFixed(2);
}

/// Extension on double for easy UI formatting
extension CurrencyFormatting on double {
  String toCurrencyString() {
    return toStringAsFixed(2);
  }
}

/// Logout helper adapted for GoRouter and Supabase Auth
Future<void> logout(BuildContext context) async {
  try {
    AppRouter.isLoggingOut = true;

    await Supabase.instance.client.auth.signOut();

    // No context.go() here.
    // The auth listener will trigger the router redirect automatically.
  } catch (e) {
    AppRouter.isLoggingOut = false;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
        ),
      );
    }
  }
}