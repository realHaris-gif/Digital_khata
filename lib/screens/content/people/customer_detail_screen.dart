import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/customer_service.dart';
import 'add_people_screen.dart';
import 'customer_detail_screen.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/customer_card.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  const CustomerDetailScreen({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    Key? key,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? spaceCadet : Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: isDark ? jordyBlue : oxfordBlue,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            LanguageController.isUrdu ? 'گاہک کی تفصیلات' : 'Customer Details',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<Map<String, double>>(
          future: CustomerService.getCustomerTotals(widget.customerId),
          builder: (context, totalsSnapshot) {
            if (!totalsSnapshot.hasData) {
              return _buildSkeletonLoadingState(isDark);
            }

            final totals = totalsSnapshot.data ?? {'totalDue': 0.0};
            final totalDue = totals['totalDue'] ?? 0.0;

            return CustomScrollView(
              slivers: [
                // Header Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        // Large Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _getAvatarGradient(),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getAvatarGradient().first.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.customerName.isNotEmpty
                                  ? widget.customerName[0].toUpperCase()
                                  : 'C',
              
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Customer Name
                        Text(
                          widget.customerName,
                          textAlign: TextAlign.center,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : oxfordBlue,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Customer Phone
                        Text(
                          widget.customerPhone.isEmpty
                              ? (LanguageController.isUrdu ? 'کوئی فون نمبر نہیں' : 'No phone number')
                              : widget.customerPhone,
                          textAlign: TextAlign.center,
            
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? lavender.withOpacity(0.7)
                                : Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Quick Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            if (widget.customerPhone.isNotEmpty)
                              _buildQuickActionButton(
                                icon: Icons.call_rounded,
                                label: LanguageController.isUrdu ? 'কল' : 'Call',
                                onTap: () => _launchCall(widget.customerPhone),
                                isDark: isDark,
                              ),
                            if (widget.customerPhone.isNotEmpty)
                              const SizedBox(width: 12),
                            if (widget.customerPhone.isNotEmpty)
                              _buildQuickActionButton(
                                icon: Icons.chat_rounded,
                                label: LanguageController.isUrdu ? 'واٹس ایپ' : 'WhatsApp',
                                onTap: () =>
                                    _launchWhatsApp(widget.customerPhone),
                                isDark: isDark,
                              ),
                            const SizedBox(width: 12),
                            _buildQuickActionButton(
                              icon: Icons.edit_rounded,
                              label: LanguageController.isUrdu ? 'ترمیم' : 'Edit',
                              onTap: () {
                                // TODO: Implement edit functionality
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Balance Summary Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(
                          LanguageController.isUrdu ? 'خلاصہ' : 'Summary',
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : oxfordBlue,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Outstanding Balance Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: totalDue > 0
                                  ? [
                                      Colors.red.shade600,
                                      Colors.red.shade700,
                                    ]
                                  : [
                                      Colors.green.shade600,
                                      Colors.green.shade700,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (totalDue > 0
                                        ? Colors.red
                                        : Colors.green)
                                    .withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                totalDue > 0
                                    ? (LanguageController.isUrdu ? 'بقایا بیلنس' : 'Outstanding Balance')
                                    : (LanguageController.isUrdu ? 'ایڈوانس بیلنس' : 'Advance Balance'),
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. ${totalDue.abs().toStringAsFixed(2)}',
                              
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                totalDue > 0
                                    ? (LanguageController.isUrdu ? 'گاہک نے آپ کو دینے ہیں' : 'Customer owes you')
                                    : (LanguageController.isUrdu ? 'آپ نے گاہک کو دینے ہیں' : 'You owe customer'),
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quick Stats
                        _buildStatsGrid(isDark),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Transactions Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      LanguageController.isUrdu ? 'حالیہ لین دین' : 'Recent Transactions',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : oxfordBlue,
                      ),
                    ),
                  ),
                ),

                // Transactions List FutureBuilder using CustomerService Timeline
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: CustomerService.getCustomerTimeline(widget.customerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                isDark ? jordyBlue : yinMnBlue,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final transactions = snapshot.data ?? [];

                    if (transactions.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              textDirection: LanguageController.contentTextDirection,
                              children: [
                                Icon(
                                  Icons.receipt_rounded,
                                  size: 48,
                                  color: isDark
                                      ? lavender.withOpacity(0.3)
                                      : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  LanguageController.isUrdu ? 'ابھی تک کوئی لین دین نہیں ہوا' : 'No transactions yet',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? lavender.withOpacity(0.6)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tx = transactions[index];
                            final typeStr = (tx['type'] ?? '').toString().toLowerCase();
                            final isGiven = typeStr.contains('given');
                            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                            final date = DateTime.tryParse(tx['date']?.toString() ?? '');
                            final title = tx['title'] ?? 'Transaction';

                            return _buildTransactionTile(
                              title: title,
                              amount: amount,
                              date: date,
                              isGiven: isGiven,
                              isDark: isDark,
                            );
                          },
                          childCount: transactions.length,
                        ),
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Skeleton Loading State for Details Screen
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(width: 100, height: 100, decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle)),
            ),
            const SizedBox(height: 16),
            Center(child: Container(width: 160, height: 20, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)))),
            const SizedBox(height: 8),
            Center(child: Container(width: 110, height: 14, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)))),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 130, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 90, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.6) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDark ? jordyBlue : yinMnBlue,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? lavender : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: LanguageController.isUrdu ? 'کل لین دین' : 'Total Transactions',
          value: '12',
          icon: Icons.receipt_rounded,
          isDark: isDark,
        ),
        _buildStatCard(
          title: LanguageController.isUrdu ? 'اوسط لین دین' : 'Avg. Transaction',
          value: 'Rs. 450',
          icon: Icons.trending_up_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: LanguageController.contentTextDirection,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? jordyBlue : yinMnBlue,
          ),
          const SizedBox(height: 8),
          Text(
            value,
          
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile({
    required String title,
    required double amount,
    required DateTime? date,
    required bool isGiven,
    required bool isDark,
  }) {
    final color = isGiven ? Colors.red.shade600 : Colors.green.shade600;
    final icon = isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        textDirection: LanguageController.contentTextDirection,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Text(
                  title,
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy • hh:mm a').format(date)
                      : (LanguageController.isUrdu ? 'کوئی تاریخ نہیں' : 'No date'),
          
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isGiven ? '−' : '+'}Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getAvatarGradient() {
    const gradients = [
      [Color(0xFF6366F1), Color(0xFF3B82F6)],
      [Color(0xFF8B5CF6), Color(0xFFD946EF)],
      [Color(0xFFF97316), Color(0xFFEA580C)],
      [Color(0xFF10B981), Color(0xFF059669)],
      [Color(0xFFEF4444), Color(0xFFDC2626)],
      [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    ];

    final index = widget.customerId.hashCode % gradients.length;
    return gradients[index];
  }
}