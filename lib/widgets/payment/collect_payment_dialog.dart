import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/services/services.dart';
import 'package:digital_khata/widgets/common/notification_popup.dart';
import 'package:digital_khata/widgets/transaction_notification_popup.dart'; // NEW IMPORT
import 'package:digital_khata/services/notification_service.dart';
import 'package:digital_khata/models/notification_model.dart'; // NEW IMPORT
import 'package:digital_khata/controller/language_controller.dart';

class CollectPaymentModal extends StatefulWidget {
  final bool isPOS;

  const CollectPaymentModal({super.key, required this.isPOS});

  @override
  State<CollectPaymentModal> createState() => _CollectPaymentModalState();
}

class _CollectPaymentModalState extends State<CollectPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoadingAccounts = true;
  bool _isProcessing = false;
  bool _isSuccess = false;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      var query = Supabase.instance.client
          .from('accounts')
          .select('id, name, current_balance, balance');
          
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      final res = await query;
      var list = List<Map<String, dynamic>>.from(res as List);
      
      if (list.isEmpty) {
        final allRes = await Supabase.instance.client
            .from('accounts')
            .select('id, name, current_balance, balance')
            .limit(10);
        list = List<Map<String, dynamic>>.from(allRes as List);
      }

      if (mounted) {
        setState(() {
          _accounts = list;
          if (_accounts.isNotEmpty) {
            _selectedAccountId = _accounts.first['id'].toString();
          }
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading accounts: $e');
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedAccountId == null || _accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageController.isUrdu ? 'براہ کرم جمع کرنے کے لیے ایک اکاؤنٹ منتخب کریں' : 'Please select an account for deposit',
            textDirection: LanguageController.contentTextDirection,
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isProcessing = true);
    final client = Supabase.instance.client;

    try {
      // 1. Get current balance of target account safely
      final accRes = await client
          .from('accounts')
          .select('current_balance, balance')
          .eq('id', _selectedAccountId!)
          .single();
          
      final currentBal = (accRes['current_balance'] as num?)?.toDouble() ?? 
                         (accRes['balance'] as num?)?.toDouble() ?? 0.0;

      final newTotal = currentBal + amount;

      // 2. Update Account Balance safely
      await client.from('accounts').update({
        'current_balance': newTotal,
        'balance': newTotal,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _selectedAccountId!);

      // 3. Trigger Notification Service
      final notificationService = NotificationService();
      
      await notificationService.notifyCreditAdded(
        amount, 
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim()
      );

      // 4. CREATE & SHOW TRANSACTION DYNAMIC ISLAND POPUP
      if (mounted) {
        // Create transaction notification model
        final transactionNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: client.auth.currentUser?.id ?? '',
          title: widget.isPOS 
              ? (LanguageController.isUrdu ? 'POS ادائیگی موصول ہوئی' : 'POS Payment Received') 
              : (LanguageController.isUrdu ? 'نقد ادائیگی وصول کی گئی' : 'Cash Payment Collected'),
          message: LanguageController.isUrdu ? 'Rs. ${amount.toStringAsFixed(2)} اکاؤنٹ میں شامل کر دیے گئے' : 'Rs. ${amount.toStringAsFixed(2)} added to account',
          type: NotificationType.success,
          category: NotificationCategory.transactions,
          icon: widget.isPOS 
              ? Icons.point_of_sale_rounded 
              : Icons.attach_money_rounded,
          createdAt: DateTime.now(),
          isRead: false,
          metadata: {
            'amount': amount,
            'account_id': _selectedAccountId,
            'note': _noteController.text.trim(),
          },
          actionRoute: '/notifications',
        );

        // Show the dynamic island popup
        OverlayNotificationManager().showNotificationFromModel(
          transactionNotification,
          duration: const Duration(seconds: 5),
        );

        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'ادائیگی جمع کرنے میں ناکام: $e' : 'Payment collection failed: $e',
              textDirection: LanguageController.contentTextDirection,
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    // Success Screen Overlay View
    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? spaceCadet : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: LanguageController.contentTextDirection,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.green,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LanguageController.isUrdu ? 'کامیاب' : 'Successful',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : oxfordBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LanguageController.isUrdu ? 'آپ کی ادائیگی کی وصولی اکاؤنٹ میں جمع کر دی گئی ہے۔' : 'Your payment collection has been credited to the account.',
              textAlign: TextAlign.center,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: oxfordBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  LanguageController.isUrdu ? 'ہو گیا' : 'Done',
                  textDirection: LanguageController.contentTextDirection,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Row(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isPOS ? Icons.point_of_sale_rounded : Icons.qr_code_2_rounded,
                      color: isDark ? jordyBlue : yinMnBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(
                          widget.isPOS 
                              ? (LanguageController.isUrdu ? 'POS ادائیگی قبول کریں' : 'Accept POS Payment') 
                              : (LanguageController.isUrdu ? 'QR کے ذریعے وصول کریں' : 'Collect via QR'),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : oxfordBlue,
                          ),
                        ),
                        Text(
                          widget.isPOS
                              ? (LanguageController.isUrdu ? 'اپنے فون پر کارڈ کی ادائیگی قبول کریں' : 'Accept card payments on your phone')
                              : (LanguageController.isUrdu ? 'اسکین کریں اور نقد رقم براہ راست اپنے بینک اکاؤنٹ میں جمع کریں' : 'Scan & credit cash directly to your bank account'),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!widget.isPOS) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: lavender, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: 'DIGITAL_KHATA_COLLECT_${DateTime.now().millisecondsSinceEpoch}',
                      version: QrVersions.auto,
                      size: 150.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: oxfordBlue,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: oxfordBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 15),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return LanguageController.isUrdu ? 'براہ کرم رقم درج کریں' : 'Please enter an amount';
                  }
                  if (double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                    return LanguageController.isUrdu ? 'براہ کرم 0 سے زیادہ درست رقم درج کریں' : 'Please enter a valid amount greater than 0';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: LanguageController.isUrdu ? 'رقم (روپے) *' : 'Amount (Rs.) *',
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? jordyBlue : yinMnBlue),
                  prefixIcon: Icon(Icons.payments_outlined, color: isDark ? jordyBlue.withOpacity(0.7) : yinMnBlue.withOpacity(0.6), size: 20),
                  filled: true,
                  fillColor: isDark ? oxfordBlue.withOpacity(0.6) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? jordyBlue : yinMnBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Account Selection dropdown
              _isLoadingAccounts
                  ? Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? oxfordBlue.withOpacity(0.6) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                      ),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? jordyBlue : yinMnBlue,
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      isExpanded: true,
                      dropdownColor: isDark ? spaceCadet : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: LanguageController.isUrdu ? 'اکاؤنٹ میں جمع کریں *' : 'Deposit Into Account *',
                        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? jordyBlue : yinMnBlue),
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: isDark ? jordyBlue.withOpacity(0.7) : yinMnBlue.withOpacity(0.6), size: 20),
                        filled: true,
                        fillColor: isDark ? oxfordBlue.withOpacity(0.6) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? jordyBlue : yinMnBlue, width: 1.5),
                        ),
                      ),
                      items: _accounts.map((acc) {
                        final balanceNum = (acc['current_balance'] as num?)?.toDouble() ?? 
                                           (acc['balance'] as num?)?.toDouble() ?? 0.0;
                        return DropdownMenuItem<String>(
                          value: acc['id'].toString(),
                          child: Text(
                            '${acc['name'] ?? (LanguageController.isUrdu ? 'اکاؤنٹ' : 'Account')} (Rs. ${balanceNum.toStringAsFixed(0)})',
                            textDirection: LanguageController.contentTextDirection,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteController,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 15),
                decoration: InputDecoration(
                  labelText: LanguageController.isUrdu ? 'نوٹ / آرڈر ریفرنس (اختیاری)' : 'Note / Order Ref (Optional)',
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? jordyBlue : yinMnBlue),
                  prefixIcon: Icon(Icons.notes_outlined, color: isDark ? jordyBlue.withOpacity(0.7) : yinMnBlue.withOpacity(0.6), size: 20),
                  filled: true,
                  fillColor: isDark ? oxfordBlue.withOpacity(0.6) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? jordyBlue : yinMnBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? jordyBlue : yinMnBlue,
                    foregroundColor: isDark ? oxfordBlue : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: isDark ? oxfordBlue : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.isPOS 
                              ? (LanguageController.isUrdu ? 'POS ادائیگی کی تصدیق کریں' : 'Confirm POS Payment') 
                              : (LanguageController.isUrdu ? 'نقد وصول کریں' : 'Collect Cash'),
                          textDirection: LanguageController.contentTextDirection,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}