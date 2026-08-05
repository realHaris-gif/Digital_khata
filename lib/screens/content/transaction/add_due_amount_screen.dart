import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/services/services.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class AddDueAmountScreen extends StatefulWidget {
  final String personId;
  final String personName;

  const AddDueAmountScreen({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<AddDueAmountScreen> createState() => _AddDueAmountScreenState();
}

class _AddDueAmountScreenState extends State<AddDueAmountScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();
  final TextEditingController paymentDescriptionController =
      TextEditingController();

  double _totalGiven = 0.0;
  double _totalPaid = 0.0;
  double _netDue = 0.0;
  bool _isLoading = true;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    paymentController.dispose();
    paymentDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTotals() async {
    setState(() => _isLoading = true);
    try {
      final totals = await CustomerService.getCustomerTotals(widget.personId);
      if (mounted) {
        setState(() {
          _totalGiven = totals['totalGiven'] ?? totals['totalDue'] ?? 0.0;
          _totalPaid = totals['totalPaid'] ?? totals['totalReceived'] ?? 0.0;
          _netDue = totals['netDue'] ?? (_totalGiven - _totalPaid);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> addDueItem() async {
    final item = itemController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;

    if (item.isEmpty || price <= 0) {
      showFormSnackBar(
        context,
        message: LanguageController.isUrdu ? 'براہ کرم درست آئٹم کا نام اور قیمت درج کریں' : 'Please enter valid item name and price',
        isError: true,
      );
      return;
    }

    try {
      await _databaseService.addDueItem(widget.personId, item, price);

      itemController.clear();
      priceController.clear();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'بقیہ آئٹم کامیابی کے ساتھ شامل کر دی گئی' : 'Due item added successfully',
        );
      }
      await _loadTotals();
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'بقیہ آئٹم شامل کرنے میں خرابی: $e' : 'Error adding due item: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> addPayment() async {
    final amount = double.tryParse(paymentController.text.trim()) ?? 0.0;
    final description = paymentDescriptionController.text.trim();

    if (amount <= 0 || amount > _netDue) {
      showFormSnackBar(
        context,
        message: amount <= 0
            ? (LanguageController.isUrdu ? 'درست رقم درج کریں' : 'Enter a valid amount')
            : (LanguageController.isUrdu ? 'ادائیگی نیٹ بقایا رقم (Rs. ${_netDue.toStringAsFixed(2)}) سے زیادہ نہیں ہو سکتی' : 'Payment cannot exceed net due amount (Rs. ${_netDue.toStringAsFixed(2)})'),
        isError: true,
      );
      return;
    }

    try {
      await _databaseService.addPayment(widget.personId, amount, description);

      paymentController.clear();
      paymentDescriptionController.clear();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'ادائیگی کامیابی کے ساتھ ریکارڈ ہو گئی' : 'Payment recorded successfully',
        );
      }
      await _loadTotals();
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'ادائیگی ریکارڈ کرنے میں خرابی: $e' : 'Error recording payment: $e',
          isError: true,
        );
      }
    }
  }

  void _showPaymentDialog() {
    final isDark = ThemeController.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? spaceCadet : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
        ),
        title: Text(
          LanguageController.isUrdu ? 'واضح کریں / ادائیگی ریکارڈ کریں' : 'Clear / Record Payment',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          textDirection: LanguageController.contentTextDirection,
          children: [
            AppFormTextField(
              controller: paymentController,
              autofocus: true,
              labelText: LanguageController.isUrdu ? 'رقم (زیادہ سے زیادہ: Rs. ${_netDue.toStringAsFixed(2)})' : 'Amount (Max: Rs. ${_netDue.toStringAsFixed(2)})',
              prefixText: 'Rs. ',
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: paymentDescriptionController,
              labelText: LanguageController.isUrdu ? 'تفصیل (اختیاری)' : 'Description (Optional)',
              prefixIcon: Icons.notes_outlined,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          FormSecondaryButton(
            label: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          FormPrimaryButton(
            label: LanguageController.isUrdu ? 'ادائیگی ریکارڈ کریں' : 'Record Payment',
            onPressed: addPayment,
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final isDark = ThemeController.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? spaceCadet : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
        ),
        title: Text(
          LanguageController.isUrdu ? 'بقیہ آئٹم شامل کریں' : 'Add Due Item',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: LanguageController.contentTextDirection,
          children: [
            AppFormTextField(
              controller: itemController,
              autofocus: true,
              labelText: LanguageController.isUrdu ? 'آئٹم کا نام' : 'Item Name',
              hintText: LanguageController.isUrdu ? 'کیا دیا گیا تھا؟' : 'What was given?',
              prefixIcon: Icons.shopping_bag_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: priceController,
              labelText: LanguageController.isUrdu ? 'قیمت / رقم' : 'Price / Amount',
              prefixText: 'Rs. ',
              prefixIcon: Icons.sell_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            Text(
              LanguageController.isUrdu 
                  ? 'تاریخ اور وقت: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}' 
                  : 'Date & Time: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          FormSecondaryButton(
            label: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          FormPrimaryButton(
            label: LanguageController.isUrdu ? 'آئٹم شامل کریں' : 'Add Item',
            icon: Icons.add_rounded,
            onPressed: addDueItem,
          ),
        ],
      ),
    );
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
            widget.personName,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    // Net Due Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? spaceCadet.withOpacity(0.6)
                            : (_netDue > 0 ? Colors.red.shade50 : Colors.green.shade50),
                        border: Border.all(
                          color: isDark
                              ? (_netDue > 0 ? Colors.red.shade800 : Colors.green.shade800)
                              : (_netDue > 0 ? Colors.red.shade300 : Colors.green.shade300),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: LanguageController.contentTextDirection,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                LanguageController.isUrdu ? 'کل دیا گیا (بقیہ):' : 'Total Given (Due):',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : oxfordBlue,
                                ),
                              ),
                              Text(
                                'Rs. ${_totalGiven.toStringAsFixed(2)}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                LanguageController.isUrdu ? 'کل ادا کیا گیا (وصول ہوا):' : 'Total Paid (Received):',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : oxfordBlue,
                                ),
                              ),
                              Text(
                                'Rs. ${_totalPaid.toStringAsFixed(2)}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 24,
                            color: isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade300,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                LanguageController.isUrdu ? 'نیٹ بقایا رقم:' : 'Net Due Amount:',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : oxfordBlue,
                                ),
                              ),
                              Text(
                                'Rs. ${_netDue.toStringAsFixed(2)}',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _netDue > 0 ? Colors.redAccent : Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Clear Due Action Button
                    if (_netDue > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? jordyBlue : yinMnBlue,
                            foregroundColor: isDark ? oxfordBlue : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _showPaymentDialog,
                          child: Text(
                            LanguageController.isUrdu ? 'بقیہ صاف کریں' : 'Clear Due',
                            textDirection: LanguageController.contentTextDirection,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Operational Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                        ),
                      ),
                      child: Text(
                        LanguageController.isUrdu 
                            ? 'لیجر بیلنس کی حیثیت\n\n'
                              'کل بقیہ: Rs. ${_totalGiven.toStringAsFixed(2)}\n'
                              'کل ادا شدہ: Rs. ${_totalPaid.toStringAsFixed(2)}\n'
                              'نیٹ بقایا: Rs. ${_netDue.toStringAsFixed(2)}'
                            : 'Ledger Balance Status\n\n'
                              'Total Due: Rs. ${_totalGiven.toStringAsFixed(2)}\n'
                              'Total Paid: Rs. ${_totalPaid.toStringAsFixed(2)}\n'
                              'Net Due: Rs. ${_netDue.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: isDark ? lavender : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: isDark ? jordyBlue : oxfordBlue,
          foregroundColor: isDark ? oxfordBlue : Colors.white,
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            LanguageController.isUrdu ? 'بقیہ آئٹم شامل کریں' : 'Add Due Item',
            textDirection: LanguageController.contentTextDirection,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}