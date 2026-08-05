import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/controller/theme_controller.dart';

// Blue Palette Constants
const Color oxfordBlue = Color(0xFF192338);
const Color spaceCadet = Color(0xFF1E2E4F);
const Color yinMnBlue  = Color(0xFF31487A);
const Color jordyBlue  = Color(0xFF8FB3E2);
const Color lavender   = Color(0xFFD9E1F2);

// =========================================================
// INVOICE STATUS BADGE WIDGET
// =========================================================
class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    Color color;
    IconData icon;

    switch (status) {
      case InvoiceStatus.draft:
        color = Colors.grey;
        icon = Icons.edit_note_rounded;
        break;
      case InvoiceStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty_rounded;
        break;
      case InvoiceStatus.paid:
        color = Colors.green.shade400;
        icon = Icons.check_circle_outline_rounded;
        break;
      case InvoiceStatus.partiallyPaid:
        color = isDark ? jordyBlue : yinMnBlue;
        icon = Icons.pie_chart_outline_rounded;
        break;
      case InvoiceStatus.cancelled:
        color = Colors.red.shade400;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// INVOICE CARD WIDGET
// =========================================================
class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    Key? key,
    required this.invoice,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: isDark ? jordyBlue : yinMnBlue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invoice.invoiceNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : oxfordBlue,
                ),
              ),
            ),
            InvoiceStatusBadge(status: invoice.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.customerName ?? 'Walk-in Customer',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(invoice.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${invoice.total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : oxfordBlue,
              ),
            ),
            if (invoice.remainingBalance > 0 &&
                invoice.status != InvoiceStatus.draft &&
                invoice.status != InvoiceStatus.cancelled)
              Text(
                'Due: Rs. ${invoice.remainingBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// INVOICE SUMMARY CARD WIDGET
// =========================================================
class InvoiceSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const InvoiceSummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : oxfordBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// INVOICE ITEM TILE WIDGET
// =========================================================
class InvoiceItemTile extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback? onDelete;

  const InvoiceItemTile({
    Key? key,
    required this.item,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          item.productName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : oxfordBlue,
          ),
        ),
        subtitle: Text(
          '${item.quantity.toStringAsFixed(0)} x Rs. ${item.unitPrice.toStringAsFixed(2)}${item.discount > 0 ? " • Disc: Rs. ${item.discount.toStringAsFixed(2)}" : ""}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs. ${item.lineTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? jordyBlue : yinMnBlue,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// PAYMENT TILE WIDGET
// =========================================================
class PaymentTile extends StatelessWidget {
  final InvoicePayment payment;

  const PaymentTile({Key? key, required this.payment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.payment_rounded, color: Colors.greenAccent, size: 20),
        ),
        title: Text(
          'Payment (${payment.paymentMethod})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : oxfordBlue,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a').format(payment.paymentDate),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          'Rs. ${payment.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.greenAccent,
          ),
        ),
      ),
    );
  }
}

// =========================================================
// SKELETON / SHIMMER LOADING BUILDER HELPER
// =========================================================
Widget buildInvoiceCardSkeleton(bool isDark) {
  final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
  final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.3, end: 1.0),
    duration: const Duration(milliseconds: 800),
    builder: (context, value, child) {
      final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 84,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    },
  );
}