import 'package:flutter/material.dart';
import 'package:digital_khata/services/payment_reminder_service.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({Key? key}) : super(key: key);

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  final Set<String> _selectedCustomerIds = {};
  bool _isSending = false;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _loadOutstandingCustomers();
  }

  Future<void> _loadOutstandingCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await PaymentReminderService.getCustomersWithOutstandingBalances();
      setState(() {
        _customers = customers;
        _selectedCustomerIds.clear();
        for (var c in customers) {
          if (c['can_send_reminder'] == true) {
            _selectedCustomerIds.add(c['id'].toString());
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading reminders list: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        for (var c in _customers) {
          if (c['can_send_reminder'] == true) {
            _selectedCustomerIds.add(c['id'].toString());
          }
        }
      } else {
        _selectedCustomerIds.clear();
      }
    });
  }

  Future<void> _sendBulkReminders() async {
    if (_selectedCustomerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageController.isUrdu ? 'براہ کرم کم از کم ایک گاہک کا انتخاب کریں۔' : 'Please select at least one customer.',
            textDirection: LanguageController.contentTextDirection,
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final selectedList = _customers
          .where((c) => _selectedCustomerIds.contains(c['id'].toString()))
          .toList();

      final result = await PaymentReminderService.sendBulkReminders(
        selectedCustomers: selectedList,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? spaceCadet : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.green.shade400,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    LanguageController.isUrdu ? 'یاد دہانیاں بھیج دی گئیں!' : 'Reminders Sent!',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : oxfordBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    LanguageController.isUrdu 
                        ? 'کامیابی کے ساتھ ${result['successCount']} ادائیگی کی یاد دہانی بھیج دی گئی۔' 
                        : 'Successfully dispatched ${result['successCount']} payment ${result['successCount'] == 1 ? 'reminder' : 'reminders'}.',
                    textAlign: TextAlign.center,
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? lavender : Colors.grey.shade600,
                    ),
                  ),
                  if (result['failedCount'] > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      LanguageController.isUrdu 
                          ? '${result['failedCount']} ناکام ہو گئیں۔' 
                          : '${result['failedCount']} ${result['failedCount'] == 1 ? 'failed' : 'failed'}.',
                      textAlign: TextAlign.center,
                      textDirection: LanguageController.contentTextDirection,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? jordyBlue : yinMnBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _loadOutstandingCustomers();
                          },
                          child: Text(
                            LanguageController.isUrdu ? 'हो गया' : 'Done',
                            textDirection: LanguageController.contentTextDirection,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageController.isUrdu ? 'یاد دہانیاں بھیجنے میں ناکام: $e' : 'Failed to send reminders: $e',
            textDirection: LanguageController.contentTextDirection,
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.surface1;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface0;
    final selectableCount = _customers.where((c) => c['can_send_reminder'] == true).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: LanguageController.contentTextDirection,
          children: [
            Text(
              LanguageController.isUrdu ? 'ادائیگی کی یاد دہانیاں' : 'Payment Reminders',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : oxfordBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              LanguageController.isUrdu ? '$selectableCount گاہک دستیاب ہیں' : '$selectableCount customers available',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: isDark ? jordyBlue : yinMnBlue),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        actions: [
          if (_customers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: () {
                  final allSelectable = _customers.where((c) => c['can_send_reminder'] == true);
                  final allSelected = allSelectable.every((c) => _selectedCustomerIds.contains(c['id'].toString()));
                  _toggleSelectAll(!allSelected);
                },
                icon: Icon(
                  Icons.select_all_rounded,
                  size: 20,
                  color: isDark ? jordyBlue : yinMnBlue,
                ),
                label: Text(
                  _selectedCustomerIds.length == _customers.length 
                      ? (LanguageController.isUrdu ? 'سب کو غیر منتخب کریں' : 'Deselect All') 
                      : (LanguageController.isUrdu ? 'سب کو منتخب کریں' : 'Select All'),
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    color: isDark ? jordyBlue : yinMnBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
              ),
            )
          : _customers.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadOutstandingCustomers,
                  color: isDark ? jordyBlue : yinMnBlue,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 56,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        LanguageController.isUrdu ? 'سب کچھ مکمل ہے!' : 'All Caught Up!',
                        textAlign: TextAlign.center,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : oxfordBlue,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Text(
                          LanguageController.isUrdu 
                              ? 'فی الحال کسی بھی گاہک کا بقایا بیلنس نہیں ہے۔ التوا میں موجود انوائسز اور واجبات یہاں ظاہر ہوں گے۔' 
                              : 'No customers currently have outstanding balances. Pending invoices and dues will appear here.',
                          textAlign: TextAlign.center,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    // Info Banner with better design
                    Container(
                      margin: const EdgeInsets.all(AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [spaceCadet.withOpacity(0.8), yinMnBlue.withOpacity(0.4)]
                              : [Colors.blue.shade50, Colors.indigo.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark ? jordyBlue.withOpacity(0.2) : jordyBlue.withOpacity(0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: jordyBlue.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: jordyBlue.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: isDark ? jordyBlue : yinMnBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Text(
                              LanguageController.isUrdu 
                                  ? 'کوڈاؤن فعال ہے: جن گاہکوں کو پچھلے 24 گھنٹوں میں یاد دہانی موصول ہوئی ہے، ان پر پابندی ہے۔' 
                                  : 'Cooldown active: Customers who received a reminder in the last 24h are restricted.',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? lavender : Colors.blue.shade900,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Customers List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadOutstandingCustomers,
                        color: isDark ? jordyBlue : yinMnBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            final customerId = customer['id'].toString();
                            final name = customer['name'] ?? (LanguageController.isUrdu ? 'نامعلوم' : 'Unknown');
                            final phone = customer['phone'] ?? (LanguageController.isUrdu ? 'کوئی فون نہیں' : 'No phone');
                            final totalDue = (customer['total_due'] as num?)?.toDouble() ?? 0.0;
                            final canSend = customer['can_send_reminder'] == true;
                            final isSelected = _selectedCustomerIds.contains(customerId);

                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? jordyBlue : yinMnBlue)
                                      : (isDark ? AppColors.darkBorder.withOpacity(0.2) : AppColors.borderLight),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: canSend
                                      ? () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedCustomerIds.remove(customerId);
                                            } else {
                                              _selectedCustomerIds.add(customerId);
                                            }
                                          });
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      textDirection: LanguageController.contentTextDirection,
                                      children: [
                                        Row(
                                          textDirection: LanguageController.contentTextDirection,
                                          children: [
                                            // Checkbox
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: canSend
                                                  ? (bool? val) {
                                                      setState(() {
                                                        if (val == true) {
                                                          _selectedCustomerIds.add(customerId);
                                                        } else {
                                                          _selectedCustomerIds.remove(customerId);
                                                        }
                                                      });
                                                    }
                                                  : null,
                                              activeColor: isDark ? jordyBlue : yinMnBlue,
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),

                                            // Customer Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                textDirection: LanguageController.contentTextDirection,
                                                children: [
                                                  Text(
                                                    name,
                                                    textDirection: LanguageController.contentTextDirection,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 15,
                                                      color: isDark ? Colors.white : oxfordBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    phone,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Amount Due Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md,
                                                vertical: AppSpacing.sm,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                                border: Border.all(
                                                  color: Colors.red.shade100,
                                                ),
                                              ),
                                              child: Text(
                                                'Rs. ${totalDue.toStringAsFixed(0)}',
                                                textDirection: TextDirection.ltr,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.red.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Cooldown Badge
                                        if (!canSend) ...[
                                          const SizedBox(height: AppSpacing.md),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: AppSpacing.sm,
                                              horizontal: AppSpacing.md,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(AppRadius.md),
                                              border: Border.all(
                                                color: Colors.orange.shade100,
                                              ),
                                            ),
                                            child: Row(
                                              textDirection: LanguageController.contentTextDirection,
                                              children: [
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  size: 14,
                                                  color: Colors.orange.shade600,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  LanguageController.isUrdu ? 'کوڈاؤن فعال ہے (پچھلے 24 گھنٹوں میں بھیجا گیا)' : 'Cooldown active (Sent in last 24h)',
                                                  textDirection: LanguageController.contentTextDirection,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.orange.shade600,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Bottom Action Button
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? AppColors.darkBorder.withOpacity(0.2) : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            if (_selectedCustomerIds.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Text(
                                  LanguageController.isUrdu 
                                      ? '${_selectedCustomerIds.length} گاہک منتخب کیے گئے' 
                                      : '${_selectedCustomerIds.length} customer${_selectedCustomerIds.length == 1 ? '' : 's'} selected',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedCustomerIds.isEmpty
                                      ? (isDark ? spaceCadet : Colors.grey.shade300)
                                      : (isDark ? jordyBlue : yinMnBlue),
                                  foregroundColor: _selectedCustomerIds.isEmpty
                                      ? (isDark ? lavender.withOpacity(0.4) : Colors.grey.shade500)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isSending || _selectedCustomerIds.isEmpty ? null : _sendBulkReminders,
                                child: _isSending
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        LanguageController.isUrdu ? 'یاد دہانیاں بھیجیں' : 'Send Reminders',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedCustomerIds.isEmpty
                                              ? (isDark ? lavender.withOpacity(0.4) : Colors.grey.shade500)
                                              : Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // Getter for isDark (helper)
  bool get isDark => ThemeController.isDarkMode;
}