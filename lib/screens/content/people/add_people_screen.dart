import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/customer_service.dart';
import '../../../widgets/forms/form_widgets.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({Key? key}) : super(key: key);

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  String _name = '';
  String _phone = '';
  double _openingBalance = 0.0;
  String _address = '';
  String _notes = '';
  bool _isLoading = false;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad));

    _animController.forward();
    _nameFocus.requestFocus();
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        await CustomerService.addCustomer(
          name: _name,
          phone: _phone,
          openingBalance: _openingBalance,
          address: _address,
          notes: _notes,
        );

        if (mounted) {
          showFormSnackBar(
            context,
            message: LanguageController.isUrdu ? 'گاہک کامیابی کے ساتھ شامل کر لیا گیا!' : 'Customer added successfully!',
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showFormSnackBar(
            context,
            message: LanguageController.isUrdu ? 'گاہک شامل کرنے میں ناکام: $e' : 'Failed to add customer: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
        body: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _animController,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // Premium Overflow-Safe Header
                SliverAppBar(
                  expandedHeight: 180,
                  floating: false,
                  pinned: true,
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
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        alignment: LanguageController.isUrdu ? Alignment.bottomRight : Alignment.bottomLeft,
                        child: Row(
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            // Safe Avatar Icon Container
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          (isDark ? jordyBlue : yinMnBlue).withOpacity(0.3),
                                          (isDark ? jordyBlue : yinMnBlue).withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      size: 28,
                                      color: isDark ? jordyBlue : yinMnBlue,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Text(
                                    LanguageController.isUrdu ? 'نیا گاہک شامل کریں' : 'Add New Customer',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : oxfordBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    LanguageController.isUrdu ? 'اپنے کھاتے کے لیے پروفائل بنائیں' : 'Create a profile for your ledger',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? lavender.withOpacity(0.7)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: _isLoading 
                  ? _buildSkeletonLoadingState(isDark) 
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            const SizedBox(height: 8),

                            // --- PERSONAL INFORMATION SECTION ---
                            _buildSectionHeader(
                              LanguageController.isUrdu ? 'ذاتی معلومات' : 'Personal Information',
                              LanguageController.isUrdu ? 'بنیادی رابطہ کی تفصیلات' : 'Basic contact details',
                              Icons.person_outline_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 12),

                            _buildFormTextField(
                              focusNode: _nameFocus,
                              labelText: LanguageController.isUrdu ? 'گاہک کا نام *' : 'Customer Name *',
                              hintText: LanguageController.isUrdu ? 'مثال کے طور پر، احمد ٹریڈرز' : 'e.g. Ahmed Traders',
                              prefixIcon: Icons.badge_outlined,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? (LanguageController.isUrdu ? 'براہ کرم گاہک کا نام درج کریں' : 'Please enter customer name')
                                  : null,
                              onSaved: (val) => _name = val!.trim(),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),

                            _buildFormTextField(
                              labelText: LanguageController.isUrdu ? 'فون نمبر' : 'Phone Number',
                              hintText: '03001234567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (val) {
                                if (val != null && val.isNotEmpty && val.length != 11) {
                                  return LanguageController.isUrdu ? 'فون نمبر بالکل 11 ہندسوں کا ہونا چاہیے' : 'Phone number must be exactly 11 digits';
                                }
                                return null;
                              },
                              onSaved: (val) => _phone = val?.trim() ?? '',
                              isDark: isDark,
                            ),

                            const SizedBox(height: 24),

                            // --- BUSINESS INFORMATION SECTION ---
                            _buildSectionHeader(
                              LanguageController.isUrdu ? 'کاروباری معلومات' : 'Business Information',
                              LanguageController.isUrdu ? 'افتتاحی بیلنس اور پتہ' : 'Opening balance and location',
                              Icons.business_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 12),

                            _buildFormTextField(
                              labelText: LanguageController.isUrdu ? 'افتتاحی بیلنس (روپے)' : 'Opening Balance (Rs.)',
                              hintText: '0.00',
                              prefixIcon: Icons.payments_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              onSaved: (val) =>
                                  _openingBalance = double.tryParse(val ?? '0') ?? 0.0,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),

                            _buildFormTextField(
                              labelText: LanguageController.isUrdu ? 'پتہ' : 'Address',
                              hintText: LanguageController.isUrdu ? 'گلی، شہر، پوسٹل کوڈ' : 'Street, city, postal code',
                              prefixIcon: Icons.location_on_outlined,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              onSaved: (val) => _address = val?.trim() ?? '',
                              isDark: isDark,
                            ),

                            const SizedBox(height: 24),

                            // --- ADDITIONAL NOTES SECTION ---
                            _buildSectionHeader(
                              LanguageController.isUrdu ? 'اضافی نوٹس' : 'Additional Notes',
                              LanguageController.isUrdu ? 'اختیاری ریمارکس' : 'Optional remarks',
                              Icons.notes_outlined,
                              isDark,
                            ),
                            const SizedBox(height: 12),

                            _buildFormTextField(
                              labelText: LanguageController.isUrdu ? 'نوٹس' : 'Notes',
                              hintText: LanguageController.isUrdu ? 'اس گاہک کے بارے میں کوئی اضافی تفصیلات…' : 'Any extra details about this customer…',
                              prefixIcon: Icons.sticky_note_2_outlined,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              onSaved: (val) => _notes = val?.trim() ?? '',
                              onFieldSubmitted: (_) => _saveCustomer(),
                              isDark: isDark,
                            ),

                            const SizedBox(height: 28),

                            // Sticky Save Button
                            Container(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 4,
                                bottom: 24,
                              ),
                              child: Row(
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _isLoading ? null : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: isDark ? jordyBlue.withOpacity(0.4) : yinMnBlue,
                                        ),
                                      ),
                                      child: Text(
                                        LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isDark ? jordyBlue : yinMnBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _isLoading ? null : _saveCustomer,
                                      icon: _isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(Icons.check_rounded),
                                      label: Text(
                                        LanguageController.isUrdu ? 'گاہک محفوظ کریں' : 'Save Customer',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isDark ? jordyBlue : yinMnBlue,
                                        foregroundColor: isDark ? oxfordBlue : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Skeleton Shimmer Loading State Matching the Form Layout
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? jordyBlue : yinMnBlue).withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.15),
        ),
      ),
      child: Row(
        textDirection: LanguageController.contentTextDirection,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
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
                  title,
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : oxfordBlue,
                  ),
                ),
                Text(
                  subtitle,
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: isDark
                        ? lavender.withOpacity(0.7)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onFieldSubmitted,
    required bool isDark,
  }) {
    return TextFormField(
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      onFieldSubmitted: onFieldSubmitted,
      textDirection: LanguageController.contentTextDirection,
      style: TextStyle(
        color: isDark ? Colors.white : oxfordBlue,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark ? jordyBlue : yinMnBlue,
        ),
        hintStyle: TextStyle(
          color: isDark ? lavender.withOpacity(0.4) : Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark ? jordyBlue.withOpacity(0.7) : yinMnBlue.withOpacity(0.6),
                size: 20,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        filled: true,
        fillColor: isDark ? spaceCadet.withOpacity(0.6) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? jordyBlue.withOpacity(0.15) : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? jordyBlue : yinMnBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade600,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade600,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}