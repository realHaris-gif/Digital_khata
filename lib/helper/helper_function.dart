import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    // 1. Sign out the active Supabase session
    await Supabase.instance.client.auth.signOut();

    if (context.mounted) {
      // 2. Navigate back to login using GoRouter
      context.go('/login');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }
}