import 'package:flutter/material.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';
import 'package:intl/intl.dart';

// =========================================================
// STOCK BADGE WIDGET
// =========================================================
class StockBadge extends StatelessWidget {
  final Product product;

  const StockBadge({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (product.isOutOfStock) {
      color = Colors.red;
      text = 'Out of Stock';
    } else if (product.isLowStock) {
      color = Colors.orange;
      text = 'Low Stock';
    } else {
      color = Colors.green;
      text = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =========================================================
// PRODUCT CARD WIDGET
// =========================================================
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
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
          backgroundColor: product.category?.getDisplayColor().withOpacity(0.15) ??
              Colors.teal.withOpacity(0.15),
          child: Icon(
            Icons.inventory_2_outlined,
            color: product.category?.getDisplayColor() ?? Colors.teal,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            StockBadge(product: product),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SKU: ${product.sku ?? "N/A"} • ${product.category?.name ?? "General"}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${product.currentStock.toStringAsFixed(0)} ${product.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
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
              'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// INVENTORY SUMMARY CARD WIDGET
// =========================================================
class InventorySummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const InventorySummaryCard({
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
// CATEGORY CHIP WIDGET
// =========================================================
class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final catColor = category.getDisplayColor();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(category.name),
        avatar: CircleAvatar(
          backgroundColor: catColor,
          radius: 6,
        ),
        selectedColor: catColor.withOpacity(0.2),
        checkmarkColor: catColor,
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// =========================================================
// MOVEMENT TILE WIDGET
// =========================================================
class MovementTile extends StatelessWidget {
  final StockMovement movement;
  final String? productName;

  const MovementTile({
    Key? key,
    required this.movement,
    this.productName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (movement.type) {
      case StockMovementType.inStock:
        icon = Icons.arrow_downward;
        color = Colors.green;
        break;
      case StockMovementType.outStock:
        icon = Icons.arrow_upward;
        color = Colors.red;
        break;
      case StockMovementType.adjustment:
        icon = Icons.tune;
        color = Colors.orange;
        break;
      case StockMovementType.returnStock:
        icon = Icons.replay;
        color = Colors.blue;
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        productName ?? movement.type.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${DateFormat('MMM dd, yyyy • hh:mm a').format(movement.createdAt)}${movement.notes != null ? " • ${movement.notes}" : ""}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Text(
        '${movement.type == StockMovementType.outStock ? "-" : "+"}${movement.quantity.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: color,
        ),
      ),
    );
  }
}