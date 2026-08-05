import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_khata/controller/theme_controller.dart';

class CreateInvoiceFAB extends StatelessWidget {
  const CreateInvoiceFAB({super.key});

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  /// Opens the modernized theme-adaptive bottom sheet
  static void showCreateInvoiceModal(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? spaceCadet : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle Indicator
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? jordyBlue.withOpacity(0.3) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Option 1: Create New Invoice Card
              _buildOptionCard(
                icon: Icons.note_add_rounded,
                iconColor: const Color(0xFFFFB800),
                title: 'Create new invoice',
                subtitle:
                    'Add all required details to easily create an invoice and save it to your ledger.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Add Existing Invoice Card
              _buildOptionCard(
                icon: Icons.post_add_rounded,
                iconColor: const Color(0xFF22C55E),
                title: 'Add an existing invoice',
                subtitle:
                    'Record an existing transaction or draft invoice into your database.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? oxfordBlue.withOpacity(0.7) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : oxfordBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Positioned(
      right: 16,
      bottom: 24,
      child: GestureDetector(
        onTap: () => showCreateInvoiceModal(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? jordyBlue : oxfordBlue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? spaceCadet : oxfordBlue).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: isDark ? oxfordBlue : Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'Create invoice',
                style: TextStyle(
                  color: isDark ? oxfordBlue : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}