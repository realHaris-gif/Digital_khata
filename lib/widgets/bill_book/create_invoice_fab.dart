import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateInvoiceFAB extends StatelessWidget {
  const CreateInvoiceFAB({super.key});

  /// Opens the global Dark Bottom Sheet shown in your screenshot
  static void showCreateInvoiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Dark background matching your screenshot
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Option 1: Create New Invoice Card
              _buildOptionCard(
                icon: Icons.note_add_outlined,
                iconColor: const Color(0xFFFFB800), // Amber icon background
                title: 'Create new invoice',
                subtitle:
                    'Add all required details to easily create an invoice and save it to your ledger.',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bill-book/create');
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Add Existing Invoice Card
              _buildOptionCard(
                icon: Icons.post_add_rounded,
                iconColor: const Color(0xFF86EFAC), // Light green icon background
                title: 'Add an existing invoice',
                subtitle:
                    'Record an existing transaction or draft invoice into your database.',
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
            color: const Color(0xFF2B2B2B), // Dark card background matching screenshot
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
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
    return Positioned(
      right: 16,
      bottom: 24,
      child: GestureDetector(
        onTap: () => showCreateInvoiceModal(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Create invoice',
                style: TextStyle(
                  color: Colors.white,
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