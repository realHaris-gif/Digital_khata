import 'package:flutter/material.dart';

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

/// Logout helper
void logout(BuildContext context) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/toggle_login_signup_screen',
    (route) => false,
  );
}