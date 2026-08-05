import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({super.key});

  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> {
  final GlobalKey _cardKey = GlobalKey();

  final _storeNameController = TextEditingController(text: 'Digital Khata Store');
  final _ownerNameController = TextEditingController(text: 'Muhammad Haris');
  final _phoneController = TextEditingController(text: '03001234567');
  final _addressController =
      TextEditingController(text: 'Main Market, Faisalabad, Pakistan');

  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCardData();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCardData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedStoreName = prefs.getString('card_store_name');
    final savedOwnerName = prefs.getString('card_owner_name');
    final savedPhone = prefs.getString('card_phone');
    final savedAddress = prefs.getString('card_address');

    if (savedStoreName != null) _storeNameController.text = savedStoreName;
    if (savedOwnerName != null) {
      _ownerNameController.text = savedOwnerName;
    } else {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        _ownerNameController.text = user.email!.split('@')[0].toUpperCase();
      }
    }
    if (savedPhone != null) _phoneController.text = savedPhone;
    if (savedAddress != null) _addressController.text = savedAddress;

    setState(() {});
  }

  Future<void> _saveCardData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_store_name', _storeNameController.text.trim());
    await prefs.setString('card_owner_name', _ownerNameController.text.trim());
    await prefs.setString('card_phone', _phoneController.text.trim());
    await prefs.setString('card_address', _addressController.text.trim());
  }

  Future<void> _shareCardImage() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/business_card.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is my Digital Business Card.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.yinMnBlue),
          scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        ),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 28,
                color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Text(
              'Business Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.oxfordBlue,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Preview Card with Repaint Boundary
                RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.spaceCadet, AppColors.yinMnBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.spaceCadet.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.jordyBlue,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: const Icon(Icons.store_rounded,
                                      color: AppColors.oxfordBlue, size: 24),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _storeNameController.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'DIGITAL KHATA VERIFIED',
                                      style: TextStyle(
                                        color: AppColors.jordyBlue,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Dynamic Contact QR Code
                            QrImageView(
                              data:
                                  'TEL:${_phoneController.text}|STORE:${_storeNameController.text}',
                              version: QrVersions.auto,
                              size: 52.0,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _ownerNameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Store Owner',
                          style: TextStyle(
                            color: AppColors.lavender.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(color: AppColors.jordyBlue.withValues(alpha: 0.2), height: 1),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded,
                                color: AppColors.jordyBlue, size: 16),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _phoneController.text,
                              style: TextStyle(
                                  color: AppColors.lavender.withValues(alpha: 0.9), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: AppColors.jordyBlue, size: 16),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _addressController.text,
                                style: TextStyle(
                                    color: AppColors.lavender.withValues(alpha: 0.9), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Share Card Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                      foregroundColor: isDark ? AppColors.oxfordBlue : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                    onPressed: _isSharing ? null : _shareCardImage,
                    icon: const Icon(Icons.share_rounded),
                    label: _isSharing
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: isDark ? AppColors.oxfordBlue : Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Share Business Card',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // Edit Details Form
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit Card Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.oxfordBlue,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: _storeNameController,
                  labelText: 'Business / Store Name',
                  prefixIcon: Icons.store_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: _ownerNameController,
                  labelText: 'Owner Name',
                  prefixIcon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: _addressController,
                  labelText: 'Store Address',
                  prefixIcon: Icons.location_on_outlined,
                  isDark: isDark,
                ),
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
    required IconData prefixIcon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
        prefixIcon: Icon(prefixIcon, color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.7) : AppColors.yinMnBlue.withValues(alpha: 0.6), size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue, width: 1.5),
        ),
      ),
      onChanged: (_) {
        setState(() {});
        _saveCardData();
      },
    );
  }
}