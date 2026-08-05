import 'package:flutter/material.dart';
import 'package:digital_khata/models/category_model.dart';
import 'package:digital_khata/models/product_model.dart';
import 'package:digital_khata/models/stock_movement_model.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:intl/intl.dart';

// Blue Palette Constants
const Color oxfordBlue = Color(0xFF192338);
const Color spaceCadet = Color(0xFF1E2E4F);
const Color yinMnBlue  = Color(0xFF31487A);
const Color jordyBlue  = Color(0xFF8FB3E2);
const Color lavender   = Color(0xFFD9E1F2);

// =========================================================
// STOCK BADGE WIDGET
// =========================================================
class StockBadge extends StatelessWidget {
  final Product product;

  const StockBadge({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    Color color;
    String text;

    if (product.isOutOfStock) {
      color = Colors.red.shade400;
      text = 'Out of Stock';
    } else if (product.isLowStock) {
      color = Colors.orange.shade400;
      text = 'Low Stock';
    } else {
      color = Colors.green.shade400;
      text = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
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
    final isDark = ThemeController.isDarkMode;
    final fallbackColor = isDark ? jordyBlue : yinMnBlue;
    final catColor = product.category?.getDisplayColor() ?? fallbackColor;

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
            color: catColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: catColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : oxfordBlue,
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
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                ),
              ),
              Text(
                '${product.currentStock.toStringAsFixed(0)} ${product.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? Colors.white : oxfordBlue,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? jordyBlue : yinMnBlue,
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
    final isDark = ThemeController.isDarkMode;
    final catColor = category.getDisplayColor();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(category.name),
        labelStyle: TextStyle(
          color: isSelected
              ? (isDark ? oxfordBlue : Colors.white)
              : (isDark ? Colors.white : oxfordBlue),
          fontWeight: FontWeight.w600,
        ),
        avatar: CircleAvatar(
          backgroundColor: catColor,
          radius: 6,
        ),
        backgroundColor: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        selectedColor: isDark ? jordyBlue : yinMnBlue,
        checkmarkColor: isDark ? oxfordBlue : Colors.white,
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : (isDark ? jordyBlue.withOpacity(0.2) : lavender),
          ),
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
    final isDark = ThemeController.isDarkMode;
    IconData icon;
    Color color;

    switch (movement.type) {
      case StockMovementType.inStock:
        icon = Icons.arrow_downward_rounded;
        color = Colors.green.shade400;
        break;
      case StockMovementType.outStock:
        icon = Icons.arrow_upward_rounded;
        color = Colors.red.shade400;
        break;
      case StockMovementType.adjustment:
        icon = Icons.tune_rounded;
        color = Colors.orange.shade400;
        break;
      case StockMovementType.returnStock:
        icon = Icons.replay_rounded;
        color = isDark ? jordyBlue : yinMnBlue;
        break;
    }

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
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          productName ?? movement.type.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : oxfordBlue,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy • hh:mm a').format(movement.createdAt)}${movement.notes != null ? " • ${movement.notes}" : ""}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          '${movement.type == StockMovementType.outStock ? "-" : "+"}${movement.quantity.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );
  }
}