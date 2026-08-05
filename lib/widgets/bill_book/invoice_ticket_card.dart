import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/controller/theme_controller.dart';

class InvoiceTicketCard extends StatelessWidget {
  final Invoice invoice;
  final String? companyLogo; // Optional company logo path

  const InvoiceTicketCard({
    super.key,
    required this.invoice,
    this.companyLogo,
  });

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final issueDateStr =
        DateFormat('dd MMM yyyy • HH:mm').format(invoice.createdAt);

    return Center(
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: isDark ? spaceCadet : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? jordyBlue.withOpacity(0.15) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),

            // === HEADER SECTION ===

            // Party Popper Emoji / Celebration Icon
            const Text(
              '🎉',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),

            // Main Title
            Text(
              'Thank you!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              'Your ticket has been issued\nsuccessfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade500,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // === DASHED DIVIDER ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomPaint(
                painter: DashedLinePainter(
                  color: isDark ? jordyBlue.withOpacity(0.3) : Colors.grey.shade300,
                ),
                size: const Size(double.infinity, 1.5),
              ),
            ),

            const SizedBox(height: 24),

            // === DETAILS SECTION ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Invoice ID & Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TICKET ID',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? jordyBlue.withOpacity(0.7) : Colors.grey.shade400,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? jordyBlue.withOpacity(0.7) : Colors.grey.shade400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rs. ${invoice.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? jordyBlue : const Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Row 2: Date & Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATE & TIME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? jordyBlue.withOpacity(0.7) : Colors.grey.shade400,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        issueDateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // === Customer Card ===
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? oxfordBlue.withOpacity(0.6) : const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade200,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar Circle with Icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? jordyBlue : const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: isDark ? oxfordBlue : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Customer Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                invoice.customerName ?? 'Walk-in Customer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Status: ${invoice.status.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // === PERFORATED CUT LINE (Ticket Separator) ===
            Row(
              children: [
                // Left decorative notch
                Container(
                  width: 12,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? spaceCadet : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
                        blurRadius: 2,
                        offset: const Offset(1, 0),
                      ),
                    ],
                  ),
                ),

                // Center dashed line
                Expanded(
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: isDark ? jordyBlue.withOpacity(0.3) : Colors.grey.shade300,
                      dashWidth: 6,
                      dashSpace: 4,
                    ),
                    size: const Size(double.infinity, 1.5),
                  ),
                ),

                // Right decorative notch
                Container(
                  width: 12,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? spaceCadet : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade200,
                        blurRadius: 2,
                        offset: const Offset(-1, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // === BARCODE SECTION ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? oxfordBlue.withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: invoice.invoiceNumber,
                      height: 56,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      backgroundColor: Colors.transparent,
                      drawText: true,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? lavender : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// === CUSTOM PAINTER FOR DASHED LINES ===
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    this.color = Colors.grey,
    this.dashWidth = 5,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}