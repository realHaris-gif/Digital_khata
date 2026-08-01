import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digital_khata/models/invoice_model.dart';

// =========================================================
// INVOICE STATUS BADGE WIDGET
// =========================================================
class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case InvoiceStatus.draft:
        color = Colors.grey;
        icon = Icons.edit_note;
        break;
      case InvoiceStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case InvoiceStatus.paid:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case InvoiceStatus.partiallyPaid:
        color = Colors.blue;
        icon = Icons.pie_chart_outline;
        break;
      case InvoiceStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.teal.withOpacity(0.12),
          child: const Icon(Icons.receipt_long, color: Colors.teal),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invoice.invoiceNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(invoice.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (invoice.remainingBalance > 0 &&
                invoice.status != InvoiceStatus.draft &&
                invoice.status != InvoiceStatus.cancelled)
              Text(
                'Due: Rs. ${invoice.remainingBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.productName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${item.quantity.toStringAsFixed(0)} x Rs. ${item.unitPrice.toStringAsFixed(2)}${item.discount > 0 ? " • Disc: Rs. ${item.discount.toStringAsFixed(2)}" : ""}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rs. ${item.lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
        ],
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.12),
        child: const Icon(Icons.payment, color: Colors.green, size: 20),
      ),
      title: Text(
        'Payment (${payment.paymentMethod})',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy • hh:mm a').format(payment.paymentDate),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Text(
        'Rs. ${payment.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.green,
        ),
      ),
    );
  }
}