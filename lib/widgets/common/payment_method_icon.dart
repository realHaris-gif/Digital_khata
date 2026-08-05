import 'package:flutter/material.dart';

class PaymentMethodIcon extends StatelessWidget {
  final String? paymentMethod;
  final double size;

  const PaymentMethodIcon({
    Key? key,
    required this.paymentMethod,
    this.size = 24.0, // Consistent sizing between 20-28 px
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String assetPath = _getAssetPath(paymentMethod);

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if asset is missing
          return Icon(Icons.payment_rounded, size: size, color: Colors.grey);
        },
      ),
    );
  }

  String _getAssetPath(String? method) {
    // Normalize string to match asset mapping safely
    final normalized = (method ?? 'Unknown').trim().toLowerCase();

    switch (normalized) {
      case 'cash':
        return 'assets/payment_methods/cash.png';
      case 'visa':
        return 'assets/payment_methods/visa.png';
      case 'mastercard':
        return 'assets/payment_methods/mastercard.png';
      case 'jazzcash':
        return 'assets/payment_methods/jazzcash.png';
      case 'easypaisa':
        return 'assets/payment_methods/easypaisa.png';
      case 'bank transfer':
      case 'bank':
        return 'assets/payment_methods/bank.png';
      default:
        return 'assets/payment_methods/default.png';
    }
  }
}