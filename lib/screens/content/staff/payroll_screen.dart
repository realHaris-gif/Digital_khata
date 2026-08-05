import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/staff_model.dart';
import 'staff_dashboard_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/controller/language_controller.dart';

final payrollProvider = FutureProvider.family<List<PayrollRecord>, DateTime>((ref, date) {
  return ref.watch(staffServiceProvider).getMonthlyPayroll(date.month, date.year);
});

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  final DateTime _selectedMonth = DateTime.now();

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  Future<void> _payDialog(PayrollRecord payroll) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final accountsRes = await Supabase.instance.client.from('accounts').select('id, name').eq('user_id', userId);
    final accounts = List<Map<String, dynamic>>.from(accountsRes as List);
    
    String? selectedAcc = accounts.isNotEmpty ? accounts.first['id'].toString() : null;
    const String method = 'Cash';
    final isDark = ThemeController.isDarkMode;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? spaceCadet : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Text(
                LanguageController.isUrdu 
                    ? 'تنخواہ ادا کریں (Rs. ${payroll.netSalary.toStringAsFixed(0)})' 
                    : 'Pay Salary (Rs. ${payroll.netSalary.toStringAsFixed(0)})',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : oxfordBlue,
                ),
              ),
              const SizedBox(height: 20),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedAcc,
                  dropdownColor: isDark ? spaceCadet : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: LanguageController.isUrdu ? 'اکاؤنٹ سے کٹوتی کریں' : 'Deduct from Account',
                    labelStyle: TextStyle(color: isDark ? jordyBlue : yinMnBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.3) : Colors.grey.shade300),
                    ),
                  ),
                  items: accounts.map((a) => DropdownMenuItem(
                        value: a['id'].toString(), 
                        child: Text(
                          a['name'],
                          textDirection: LanguageController.contentTextDirection,
                        ),
                      )).toList(),
                  onChanged: (v) => selectedAcc = v,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? jordyBlue : yinMnBlue,
                  foregroundColor: isDark ? oxfordBlue : Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (selectedAcc == null) return;
                  final service = ref.read(staffServiceProvider);
                  await service.paySalary(
                    payroll: payroll,
                    accountId: selectedAcc!,
                    paymentMethod: method,
                    paidAmount: payroll.netSalary,
                  );
                  ref.invalidate(payrollProvider(_selectedMonth));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  LanguageController.isUrdu ? 'ادائیگی کی تصدیق کریں' : 'Confirm Payment',
                  textDirection: LanguageController.contentTextDirection,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final payrollAsync = ref.watch(payrollProvider(_selectedMonth));
    final service = ref.watch(staffServiceProvider);
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
            LanguageController.isUrdu 
                ? 'پیرول (${DateFormat('MMMM yyyy').format(_selectedMonth)})' 
                : 'Payroll (${DateFormat('MMMM yyyy').format(_selectedMonth)})',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: LanguageController.isUrdu ? 'پیرول دوبارہ تیار کریں' : 'Regenerate Payroll',
              icon: Icon(Icons.autorenew_rounded, color: isDark ? jordyBlue : yinMnBlue),
              onPressed: () async {
                await service.generateMonthlyPayroll(_selectedMonth.month, _selectedMonth.year);
                ref.invalidate(payrollProvider(_selectedMonth));
              },
            )
          ],
        ),
        body: payrollAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 64, color: isDark ? jordyBlue.withOpacity(0.5) : Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        LanguageController.isUrdu ? 'اس ماہ کے لیے ابھی تک کوئی پیرول تیار نہیں کیا گیا' : 'No payroll generated for this month yet',
                        textAlign: TextAlign.center,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : oxfordBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? jordyBlue : yinMnBlue,
                          foregroundColor: isDark ? oxfordBlue : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await service.generateMonthlyPayroll(_selectedMonth.month, _selectedMonth.year);
                          ref.invalidate(payrollProvider(_selectedMonth));
                        },
                        icon: const Icon(Icons.flash_on_rounded),
                        label: Text(
                          LanguageController.isUrdu ? 'پیرول تیار کریں' : 'Generate Payroll',
                          textDirection: LanguageController.contentTextDirection,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, idx) {
                final rec = records[idx];
                final isPaid = rec.paymentStatus == PayrollPaymentStatus.paid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                    ),
                  ),
                  child: Row(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: isDark ? jordyBlue : yinMnBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Text(
                              'Rs. ${rec.netSalary.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : oxfordBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LanguageController.isUrdu 
                                  ? 'بنیادی: Rs. ${rec.basicSalary.toStringAsFixed(0)} | کٹوتی: Rs. ${rec.advanceDeduction.toStringAsFixed(0)}' 
                                  : 'Basic: Rs. ${rec.basicSalary.toStringAsFixed(0)} | Deductions: Rs. ${rec.advanceDeduction.toStringAsFixed(0)}',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaid ? Colors.green.shade600 : (isDark ? jordyBlue : yinMnBlue),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isPaid ? null : () => _payDialog(rec),
                        child: Text(
                          isPaid 
                              ? (LanguageController.isUrdu ? 'ادا شدہ' : 'PAID') 
                              : (LanguageController.isUrdu ? 'ادا کریں' : 'PAY'),
                          textDirection: LanguageController.contentTextDirection,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => _buildSkeletonLoadingState(isDark),
          error: (e, _) => Center(
            child: Text(
              LanguageController.isUrdu ? 'خرابی: $e' : 'Error: $e',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  // Skeleton Shimmer Loading State
  Widget _buildSkeletonLoadingState(bool isDark) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Container(width: 110, height: 16, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 8),
                      Container(width: 160, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                ),
                Container(width: 60, height: 32, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        );
      },
    );
  }
}