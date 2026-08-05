import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/store_model.dart';
import 'store_dashboard_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  final StoreModel? store;

  const StoreSettingsScreen({super.key, this.store});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;

  File? _logoFile;
  File? _bannerFile;
  bool _isSaving = false;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _nameCtrl = TextEditingController(text: s?.storeName ?? '');
    _slugCtrl = TextEditingController(text: s?.slug ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(picked.path);
        } else {
          _bannerFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final service = ref.read(storeServiceProvider);
      await service.saveStore(
        storeName: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim().isEmpty
            ? _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-')
            : _slugCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        logoFile: _logoFile,
        bannerFile: _bannerFile,
        currentLogoUrl: widget.store?.logoUrl,
        currentBannerUrl: widget.store?.bannerUrl,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageController.isUrdu ? 'اسٹور محفوظ کرنے میں خرابی: $e' : 'Error saving store: $e',
              textDirection: LanguageController.contentTextDirection,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            widget.store != null 
                ? (LanguageController.isUrdu ? 'اسٹور کی ترتیبات' : 'Store Settings') 
                : (LanguageController.isUrdu ? 'ڈیجیٹل اسٹور سیٹ اپ کریں' : 'Setup Digital Store'),
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
        ),
        body: _isSaving
            ? _buildSkeletonLoadingState(isDark)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      // Banner Picker
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? spaceCadet.withOpacity(0.6) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade300,
                            ),
                            image: _bannerFile != null
                                ? DecorationImage(image: FileImage(_bannerFile!), fit: BoxFit.cover)
                                : (widget.store?.bannerUrl != null
                                    ? DecorationImage(image: NetworkImage(widget.store!.bannerUrl!), fit: BoxFit.cover)
                                    : null),
                          ),
                          child: _bannerFile == null && widget.store?.bannerUrl == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    textDirection: LanguageController.contentTextDirection,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded, size: 32, color: isDark ? jordyBlue : yinMnBlue),
                                      const SizedBox(height: 6),
                                      Text(
                                        LanguageController.isUrdu ? 'اسٹور کا بینر اپ لوڈ کرنے کے لیے ٹیپ کریں' : 'Tap to upload Store Banner',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? lavender : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Logo Picker
                      Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: isDark ? spaceCadet : Colors.grey.shade200,
                                backgroundImage: _logoFile != null
                                    ? FileImage(_logoFile!)
                                    : (widget.store?.logoUrl != null ? NetworkImage(widget.store!.logoUrl!) : null)
                                        as ImageProvider?,
                                child: _logoFile == null && widget.store?.logoUrl == null
                                    ? Icon(Icons.storefront_rounded, size: 36, color: isDark ? jordyBlue : yinMnBlue)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? jordyBlue : yinMnBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: isDark ? oxfordBlue : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _nameCtrl,
                        labelText: LanguageController.isUrdu ? 'اسٹور کا نام *' : 'Store Name *',
                        hintText: LanguageController.isUrdu ? 'مثال کے طور پر، حارث جنرل اسٹور' : 'e.g. Haris General Store',
                        prefixIcon: Icons.store_rounded,
                        isDark: isDark,
                        validator: (v) => v == null || v.isEmpty ? (LanguageController.isUrdu ? 'اسٹور کا نام درج کریں' : 'Enter store name') : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _slugCtrl,
                        labelText: LanguageController.isUrdu ? 'اسٹور یو آر ایل سلگ' : 'Store URL Slug',
                        hintText: 'e.g. haris-store',
                        prefixIcon: Icons.link_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _phoneCtrl,
                        labelText: LanguageController.isUrdu ? 'واٹس ایپ / فون نمبر' : 'WhatsApp / Phone Number',
                        hintText: '03001234567',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        isDark: isDark,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length != 11) {
                            return LanguageController.isUrdu ? 'فون نمبر بالکل 11 ہندسوں کا ہونا چاہیے' : 'Phone number must be exactly 11 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _addressCtrl,
                        labelText: LanguageController.isUrdu ? 'اسٹور کا پتہ' : 'Store Address',
                        hintText: LanguageController.isUrdu ? 'گلی، شہر' : 'Street, City',
                        prefixIcon: Icons.location_on_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _descCtrl,
                        labelText: LanguageController.isUrdu ? 'اسٹور کی تفصیل' : 'Store Description',
                        hintText: LanguageController.isUrdu ? 'آپ کے اسٹور کی مصنوعات کا خلاصہ...' : 'Brief summary of your store products...',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: isDark ? jordyBlue : yinMnBlue,
                          foregroundColor: isDark ? oxfordBlue : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: Text(
                          LanguageController.isUrdu ? 'اسٹور کی ترتیبات محفوظ کریں' : 'Save Store Settings',
                          textDirection: LanguageController.contentTextDirection,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      textDirection: LanguageController.contentTextDirection,
      style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? jordyBlue : yinMnBlue),
        hintStyle: TextStyle(color: isDark ? lavender.withOpacity(0.4) : Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: isDark ? jordyBlue.withOpacity(0.7) : yinMnBlue.withOpacity(0.6), size: 20),
        filled: true,
        fillColor: isDark ? spaceCadet.withOpacity(0.6) : const Color(0xFFF1F5F9),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(width: double.infinity, height: 140, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 24),
              Center(child: Container(width: 84, height: 84, decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle))),
              const SizedBox(height: 24),
              Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
            ],
          ),
        );
      },
    );
  }
}