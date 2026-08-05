import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digital_khata/controller/language_controller.dart';

class CustomerCard extends StatelessWidget {
  final String customerId;
  final String name;
  final String phone;
  final double totalDue;
  final int transactionCount;
  final DateTime? lastTransactionDate;
  final VoidCallback onTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onWhatsAppTap;

  // Blue Palette Constants matching the app theme
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  const CustomerCard({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.transactionCount,
    this.lastTransactionDate,
    required this.onTap,
    this.onCallTap,
    this.onWhatsAppTap,
    Key? key,
  }) : super(key: key);

  Color _getAmountColor(bool isDark) {
    if (totalDue > 0) {
      return isDark ? Colors.redAccent.shade100 : Colors.red.shade600;
    }
    return isDark ? Colors.greenAccent.shade200 : Colors.green.shade600;
  }

  String _getLastTransactionText() {
    if (lastTransactionDate == null) {
      return LanguageController.isUrdu ? 'کوئی لین دین نہیں' : 'No transactions';
    }
    final now = DateTime.now();
    final difference = now.difference(lastTransactionDate!);

    if (difference.inDays == 0) {
      return LanguageController.isUrdu ? 'آج' : 'Today';
    } else if (difference.inDays == 1) {
      return LanguageController.isUrdu ? 'कल' : 'Yesterday';
    } else if (difference.inDays < 7) {
      return LanguageController.isUrdu ? '${difference.inDays} دن پہلے' : '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return LanguageController.isUrdu ? '${(difference.inDays / 7).floor()} ہفتے پہلے' : '${(difference.inDays / 7).floor()}w ago';
    } else {
      return DateFormat('MMM d').format(lastTransactionDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountColor = _getAmountColor(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: LanguageController.contentTextDirection,
            children: [
              // Header Row: Avatar + Name + Balance
              Row(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _getAvatarGradient(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Phone (Expanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? Colors.white : oxfordBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone.isEmpty 
                              ? (LanguageController.isUrdu ? 'کوئی فون نمبر نہیں' : 'No phone') 
                              : phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount Badge (Updated to show Pending vs Advance explicitly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      totalDue > 0
                          ? (LanguageController.isUrdu ? 'بقیہ: Rs. ${totalDue.toStringAsFixed(0)}' : 'Pending: Rs. ${totalDue.toStringAsFixed(0)}')
                          : (LanguageController.isUrdu ? 'ایڈوانس: Rs. ${totalDue.abs().toStringAsFixed(0)}' : 'Advance: Rs. ${totalDue.abs().toStringAsFixed(0)}'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: amountColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats Row: Transaction Count + Last Transaction
              Row(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  // Transaction Count
                  Expanded(
                    child: Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Icon(
                          Icons.receipt_rounded,
                          size: 16,
                          color: isDark ? jordyBlue.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          LanguageController.isUrdu ? '$transactionCount لین دین' : '$transactionCount transactions',
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Last Transaction
                  Row(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: isDark ? jordyBlue.withOpacity(0.7) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getLastTransactionText(),
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quick Action Buttons Row
              Row(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.call_rounded,
                      label: LanguageController.isUrdu ? 'کال' : 'Call',
                      onTap: onCallTap,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.chat_rounded,
                      label: LanguageController.isUrdu ? 'پیغام' : 'Message',
                      onTap: onWhatsAppTap,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? oxfordBlue : lavender.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? jordyBlue : spaceCadet,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? jordyBlue : spaceCadet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getAvatarGradient() {
    const gradients = [
      [Color(0xFF6366F1), Color(0xFF3B82F6)], // Indigo to Blue
      [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Purple to Pink
      [Color(0xFFF97316), Color(0xFFEA580C)], // Orange
      [Color(0xFF10B981), Color(0xFF059669)], // Green
      [Color(0xFFEF4444), Color(0xFFDC2626)], // Red
      [Color(0xFF0EA5E9), Color(0xFF0284C7)], // Sky
    ];

    final index = customerId.hashCode % gradients.length;
    return gradients[index];
  }
}