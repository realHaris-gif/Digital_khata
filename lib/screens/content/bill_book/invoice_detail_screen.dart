import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/models/invoice_model.dart';
import 'package:digital_khata/services/invoice_service.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/widgets/bill_book/create_invoice_fab.dart';
import 'package:digital_khata/widgets/bill_book/invoice_ticket_card.dart';
import 'package:digital_khata/widgets/bill_book/invoice_widgets.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(Supabase.instance.client);
});

final singleInvoiceProvider =
    FutureProvider.family<Invoice?, String>((ref, invoiceId) async {
  final repo = ref.watch(invoiceRepoProvider);
  return repo.getInvoiceById(invoiceId);
});

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final GlobalKey _ticketKey = GlobalKey();

  void _refresh() {
    ref.invalidate(singleInvoiceProvider(widget.invoiceId));
  }

  Future<void> _shareInvoiceTicketImage() async {
    try {
      final boundary = _ticketKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/invoice_receipt.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: LanguageController.isUrdu ? 'یہاں آپ کے لین دین کی رسید ہے #${widget.invoiceId}۔' : 'Here is your receipt for transaction #${widget.invoiceId}.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'رسید کی تصویر شیئر کرنے میں ناکام: $e' : 'Failed to share receipt image: $e',
              textDirection: LanguageController.contentTextDirection,
            ),
          ),
        );
      }
    }
  }

  void _showShareTicketDialog(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _ticketKey,
                child: InvoiceTicketCard(invoice: invoice),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yinMnBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _shareInvoiceTicketImage();
                  },
                  icon: const Icon(Icons.share_rounded,
                      color: Colors.white, size: 18),
                  label: Text(
                    LanguageController.isUrdu ? 'رسید کی تصویر شیئر کریں' : 'Share Receipt Image',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActionBottomSheet(
      BuildContext context, WidgetRef ref, Invoice invoice) {
    final isDark = ThemeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.3) : AppColors.lavender,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildModalButton(
                icon: Icons.confirmation_number_outlined,
                label: LanguageController.isUrdu ? 'رسید کارڈ شیئر کریں' : 'Share Receipt Card',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showShareTicketDialog(context, invoice);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildModalButton(
                icon: Icons.copy_outlined,
                label: LanguageController.isUrdu ? 'انوائس کی نقل بنائیں' : 'Duplicate invoice',
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(context);
                  final userId =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
                  final repo = ref.read(invoiceRepoProvider);
                  await repo.duplicateInvoice(widget.invoiceId, userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LanguageController.isUrdu ? 'انوائس ڈپلیکیٹ ہو گئی!' : 'Invoice duplicated!',
                          textDirection: LanguageController.contentTextDirection,
                        ),
                      ),
                    );
                    context.pop(true);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildModalButton(
                icon: Icons.add_card_rounded,
                label: LanguageController.isUrdu ? 'ادائیگی درج کریں' : 'Record payment',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentModal(context, ref, invoice);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildModalButton(
                icon: Icons.delete_outline_rounded,
                label: LanguageController.isUrdu ? 'انوائس حذف کریں' : 'Delete invoice',
                isDanger: true,
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(invoiceRepoProvider);
                  await repo.deleteInvoice(widget.invoiceId);
                  if (context.mounted) context.pop(true);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDanger
                ? Colors.red.withValues(alpha: 0.1)
                : (isDark ? AppColors.darkBackground : AppColors.lavender.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Icon(
                icon,
                color: isDanger ? Colors.redAccent : (isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  color: isDanger ? Colors.redAccent : (isDark ? Colors.white : AppColors.oxfordBlue),
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

  Future<void> _showPaymentModal(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
  ) async {
    final amountController = TextEditingController(
      text: invoice.remainingBalance.toStringAsFixed(2),
    );
    final notesController = TextEditingController();
    String selectedMethod = 'Cash';
    String? selectedAccountId;
    final formKey = GlobalKey<FormState>();

    bool isSubmitting = false;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final accountsRes = await Supabase.instance.client
        .from('accounts')
        .select('id, name')
        .eq('user_id', userId);
    final accounts = List<Map<String, dynamic>>.from(accountsRes as List);

    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        LanguageController.isUrdu ? 'ادائیگی درج کریں' : 'Record Payment',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'ادائیگی کی رقم (روپے) *' : 'Payment Amount (Rs.) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return LanguageController.isUrdu ? 'ادائیگی کی رقم درج کریں' : 'Enter payment amount';
                          }
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return LanguageController.isUrdu ? 'درست رقم درج کریں' : 'Enter valid amount';
                          }
                          if (parsed > invoice.remainingBalance + 0.01) {
                            return LanguageController.isUrdu ? 'رقم باقی بیلنس سے زیادہ نہیں ہو سکتی (Rs. ${invoice.remainingBalance.toStringAsFixed(2)})' : 'Amount cannot exceed remaining balance (Rs. ${invoice.remainingBalance.toStringAsFixed(2)})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'ادائیگی کا طریقہ' : 'Payment Method',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Cash', child: Text(LanguageController.isUrdu ? 'نقد' : 'Cash', textDirection: LanguageController.contentTextDirection)),
                          DropdownMenuItem(value: 'Bank', child: Text(LanguageController.isUrdu ? 'بینک' : 'Bank', textDirection: LanguageController.contentTextDirection)),
                          DropdownMenuItem(
                              value: 'JazzCash', child: Text('JazzCash', textDirection: LanguageController.contentTextDirection)),
                          DropdownMenuItem(
                              value: 'EasyPaisa', child: Text('EasyPaisa', textDirection: LanguageController.contentTextDirection)),
                          DropdownMenuItem(
                              value: 'Credit Card', child: Text(LanguageController.isUrdu ? 'کریڈٹ کارڈ' : 'Credit Card', textDirection: LanguageController.contentTextDirection)),
                          DropdownMenuItem(
                              value: 'Custom', child: Text(LanguageController.isUrdu ? 'اپنی مرضی کے مطابق' : 'Custom', textDirection: LanguageController.contentTextDirection)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedMethod = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (accounts.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedAccountId,
                          decoration: InputDecoration(
                            labelText: LanguageController.isUrdu ? 'اکاؤنٹ (اختیاری)' : 'Account (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          items: accounts.map((acc) {
                            return DropdownMenuItem<String>(
                              value: acc['id'] as String,
                              child: Text(acc['name'] as String, textDirection: LanguageController.contentTextDirection),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() => selectedAccountId = val);
                          },
                        ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: notesController,
                        textDirection: LanguageController.contentTextDirection,
                        decoration: InputDecoration(
                          labelText: LanguageController.isUrdu ? 'ادائیگی کے نوٹس (اختیاری)' : 'Payment Notes (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.yinMnBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  final repo = ref.read(invoiceRepoProvider);

                                  await repo.recordPayment(
                                    invoiceId: invoice.id,
                                    userId: userId,
                                    accountId: selectedAccountId,
                                    amount: double.parse(
                                        amountController.text.trim()),
                                    paymentMethod: selectedMethod,
                                    paymentDate: DateTime.now(),
                                    notes: notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _refresh();
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          LanguageController.isUrdu ? 'ادائیگی ناکام ہو گئی: $e' : 'Payment failed: $e',
                                          textDirection: LanguageController.contentTextDirection,
                                        ),
                                      ),
                                    );
                                  }
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                LanguageController.isUrdu ? 'ادائیگی جمع کروائیں' : 'Submit Payment',
                                textDirection: LanguageController.contentTextDirection,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoiceAsync = ref.watch(singleInvoiceProvider(widget.invoiceId));
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue, size: 18),
            onPressed: () => context.pop(),
          ),
          title: Text(
            LanguageController.isUrdu ? 'انوائس کی تفصیل' : 'Invoice detail',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.oxfordBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            invoiceAsync.when(
              data: (invoice) => invoice == null
                  ? const SizedBox()
                  : Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.share_outlined,
                              color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue),
                          onPressed: () =>
                              _showShareTicketDialog(context, invoice),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert_rounded,
                              color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue),
                          onPressed: () =>
                              _showActionBottomSheet(context, ref, invoice),
                        ),
                      ],
                    ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        body: Stack(
          children: [
            invoiceAsync.when(
              data: (invoice) {
                if (invoice == null) {
                  return Center(
                    child: Text(
                      LanguageController.isUrdu ? 'انوائس نہیں ملی۔' : 'Invoice not found.',
                      textDirection: LanguageController.contentTextDirection,
                    ),
                  );
                }

                final formattedIssueDate =
                    DateFormat('MMM dd, yyyy').format(invoice.createdAt);
                final formattedDueDate = DateFormat('MMM dd, yyyy').format(
                  invoice.createdAt.add(const Duration(days: 14)),
                );

                return RefreshIndicator(
                  color: AppColors.yinMnBlue,
                  onRefresh: () async => _refresh(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.sm,
                      bottom: 120,
                    ),
                    child: Column(
                      children: [
                        // Top ID and Status Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : AppColors.lavender.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(Icons.description_outlined,
                                    size: 20, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : AppColors.oxfordBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InvoiceStatusBadge(status: invoice.status),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.borderLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                ),
                                onPressed: () => context.push(
                                    '/bill-book/create',
                                    extra: invoice),
                                icon: Icon(Icons.edit_outlined,
                                    size: 16, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                                label: Text(
                                  LanguageController.isUrdu ? 'ترمیم' : 'Edit',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: TextStyle(
                                    color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Main Receipt Document Layout
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Text(
                                    LanguageController.isUrdu ? 'انوائس' : 'INVOICE',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : AppColors.oxfordBlue,
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.yinMnBlue,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: const Icon(Icons.stop,
                                        color: Colors.white, size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              _buildMetaRow(
                                  LanguageController.isUrdu ? 'انوائس نمبر' : 'Invoice number', invoice.invoiceNumber, isDark),
                              _buildMetaRow(LanguageController.isUrdu ? 'اجراء کی تاریخ' : 'Issue date', formattedIssueDate, isDark),
                              _buildMetaRow(LanguageController.isUrdu ? 'آخری تاریخ' : 'Due date', formattedDueDate, isDark),
                              const SizedBox(height: AppSpacing.xl),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LanguageController.isUrdu ? 'بل بھیجا گیا' : 'Billed to',
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(
                                              color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                              fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          invoice.customerName ??
                                              (LanguageController.isUrdu ? 'واک ان کسٹمر' : 'Walk-in Customer'),
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LanguageController.isUrdu ? 'جانب سے' : 'From',
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(
                                              color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                              fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          LanguageController.isUrdu ? 'ڈیجیٹل کھاتہ اسٹور' : 'Digital Khata Store',
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Line Items Table Header
                              Row(
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      LanguageController.isUrdu ? 'آئٹمز' : 'Items',
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(
                                          color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                          fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      LanguageController.isUrdu ? 'مقدار' : 'Qty',
                                      textAlign: TextAlign.center,
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(
                                          color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                          fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      LanguageController.isUrdu ? 'رقم' : 'Amount',
                                      textAlign: TextAlign.right,
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(
                                          color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Divider(height: 1, color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight),
                              const SizedBox(height: AppSpacing.md),

                              // Line Items Rows
                              ...invoice.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    textDirection: LanguageController.contentTextDirection,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item.productName,
                                          textDirection: LanguageController.contentTextDirection,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13, color: isDark ? AppColors.lavender : AppColors.oxfordBlue),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rs. ${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : AppColors.oxfordBlue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),
                              Divider(height: 1, color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight),
                              const SizedBox(height: AppSpacing.md),

                              // Financial Summary Breakup
                              _buildSummaryRow(LanguageController.isUrdu ? 'ذیلی کل' : 'Subtotal',
                                  'Rs. ${invoice.subtotal.toStringAsFixed(2)}', isDark),
                              if (invoice.discount > 0)
                                _buildSummaryRow(LanguageController.isUrdu ? 'ڈسکاؤنট' : 'Discount',
                                    '- Rs. ${invoice.discount.toStringAsFixed(2)}', isDark,
                                    textColor: Colors.redAccent),
                              if (invoice.tax > 0)
                                _buildSummaryRow(LanguageController.isUrdu ? 'ٹیکس' : 'Tax',
                                    '+ Rs. ${invoice.tax.toStringAsFixed(2)}', isDark),
                              if (invoice.shipping > 0)
                                _buildSummaryRow(LanguageController.isUrdu ? 'شپنگ' : 'Shipping',
                                    '+ Rs. ${invoice.shipping.toStringAsFixed(2)}', isDark),

                              const SizedBox(height: AppSpacing.sm),
                              Divider(height: 1, color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight),
                              const SizedBox(height: AppSpacing.md),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Text(
                                    LanguageController.isUrdu ? 'کل' : 'Total',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      color: isDark ? AppColors.lavender : AppColors.spaceCadet,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${invoice.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.oxfordBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildSummaryRow(LanguageController.isUrdu ? 'کل ادا شدہ' : 'Total Paid',
                                  'Rs. ${invoice.totalPaid.toStringAsFixed(2)}', isDark,
                                  textColor: Colors.green.shade400, isBold: true),
                              _buildSummaryRow(LanguageController.isUrdu ? 'بقایا' : 'Remaining',
                                  'Rs. ${invoice.remainingBalance.toStringAsFixed(2)}', isDark,
                                  textColor: Colors.redAccent, isBold: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Payment Activity Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Text(
                              LanguageController.isUrdu ? 'ادائیگی کی سرگرمی' : 'Payment Activity',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                              ),
                            ),
                            if (invoice.remainingBalance > 0 &&
                                invoice.status != InvoiceStatus.cancelled)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.yinMnBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                ),
                                onPressed: () =>
                                    _showPaymentModal(context, ref, invoice),
                                icon: const Icon(Icons.add,
                                    color: Colors.white, size: 18),
                                label: Text(
                                  LanguageController.isUrdu ? 'ادائیگی درج کریں' : 'Record Payment',
                                  textDirection: LanguageController.contentTextDirection,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (invoice.payments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              LanguageController.isUrdu ? 'ابھی تک کوئی ادائیگی درج نہیں کی گئی۔' : 'No payments recorded yet.',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                  color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.6)),
                            ),
                          )
                        else
                          ...invoice.payments.map((p) => PaymentTile(payment: p)),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yinMnBlue)),
              error: (e, _) => Center(
                child: Text(
                  '${l10n.error}: $e',
                  textDirection: LanguageController.contentTextDirection,
                ),
              ),
            ),

            // Reusable Persistent Create Invoice Floating Button
            const CreateInvoiceFAB(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        textDirection: LanguageController.contentTextDirection,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                  color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
                  fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.oxfordBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    Color? textColor,
    bool isBold = false,
  }) {
    print("Building summary row: $label");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: LanguageController.contentTextDirection,
        children: [
          Text(
            label,
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : AppColors.spaceCadet.withValues(alpha: 0.6),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? (isDark ? Colors.white : AppColors.oxfordBlue),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}