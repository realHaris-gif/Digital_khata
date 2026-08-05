import 'package:flutter/material.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import '../../../services/platform_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/services/google_drive_backup_service.dart';
import '../security/security_settings_screen.dart'; // NEW: Imported Security Settings screen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PlatformServices _platformServices = PlatformServices();
  bool _biometricsEnabled = false;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    final canCheck = await _platformServices.canCheckBiometrics();
    setState(() => _biometricsEnabled = canCheck);
  }

  Future<void> _exportAllCustomers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final res = await Supabase.instance.client
        .from('customers')
        .select('name, phone')
        .eq('user_id', userId);

    final rows = (res as List).map((c) => [c['name'], c['phone'] ?? 'N/A']).toList();

    await _platformServices.exportDataToExcel(
      sheetName: 'Customers',
      headers: ['Customer Name', 'Phone'],
      rows: rows,
    );
  }

  // Handle Google Drive Backup Flow
  Future<void> _handleGoogleDriveBackup() async {
    // Show sleek loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ThemeController.isDarkMode ? spaceCadet : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            textDirection: LanguageController.contentTextDirection,
            children: [
              // Enhanced spinner with gradient
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(
                        ThemeController.isDarkMode ? jordyBlue : yinMnBlue,
                      ),
                    ),
                    Icon(
                      Icons.cloud_upload_rounded,
                      color: ThemeController.isDarkMode ? jordyBlue : yinMnBlue,
                      size: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LanguageController.isUrdu ? 'ڈیٹا کا بیک اپ لیا جا رہا ہے' : 'Backing up data',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  color: ThemeController.isDarkMode ? Colors.white : oxfordBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LanguageController.isUrdu ? 'براہ کرم انتظار کریں جب تک ہم گوگل ڈرائیو کے ساتھ مطابقت پذیر ہو رہے ہیں' : 'Please wait while we sync to Google Drive',
                textAlign: TextAlign.center,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  color: ThemeController.isDarkMode 
                      ? lavender.withOpacity(0.7) 
                      : Colors.grey.shade600,
                  fontSize: 12,
                  letterSpacing: 0.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await GoogleDriveBackupService().backupToGoogleDrive();
      
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        
        // Show premium success confirmation
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ThemeController.isDarkMode ? spaceCadet : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  // Success checkmark animation
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LanguageController.isUrdu ? 'بیک اپ مکمل ہو گیا!' : 'Backup Complete!',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      color: ThemeController.isDarkMode ? Colors.white : oxfordBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LanguageController.isUrdu ? 'آپ کا سارا ڈیٹا گوگل ڈرائیو پر محفوظ طریقے سے مطابقت پذیر ہو گیا ہے۔ آپ کا کاروبار محفوظ ہے!' : 'All your data has been securely synced to Google Drive. Your business is safe!',
                    textAlign: TextAlign.center,
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      color: ThemeController.isDarkMode 
                          ? lavender.withOpacity(0.8) 
                          : Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: jordyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        LanguageController.isUrdu ? 'سمجھ گیا' : 'Got it',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        
        // Show error dialog
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ThemeController.isDarkMode ? spaceCadet : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_rounded,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LanguageController.isUrdu ? 'بیک اپ ناکام ہو گیا' : 'Backup Failed',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                      color: ThemeController.isDarkMode ? Colors.white : oxfordBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: ThemeController.isDarkMode 
                          ? lavender.withOpacity(0.8) 
                          : Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        LanguageController.isUrdu ? 'دوبارہ کوشش کریں' : 'Try again',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
  }

  void _showFeatureDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeController.isDarkMode ? spaceCadet : Colors.white,
        title: Text(title, textDirection: LanguageController.contentTextDirection, style: TextStyle(color: ThemeController.isDarkMode ? Colors.white : oxfordBlue)),
        content: Text(message, textDirection: LanguageController.contentTextDirection, style: TextStyle(color: ThemeController.isDarkMode ? lavender : Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageController.isUrdu ? 'بند کریں' : 'Close', textDirection: LanguageController.contentTextDirection),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Digital Khata User';

    return Scaffold(
      backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? spaceCadet : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          LanguageController.isUrdu ? 'ترتیبات' : 'Settings',
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : oxfordBlue,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          // ====================================================
          // USER PROFILE HEADER CARD
          // ====================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
              ),
            ),
            child: Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [jordyBlue, yinMnBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Text(
                        userEmail.split('@').first.toUpperCase(),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : oxfordBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? jordyBlue : Colors.grey.shade400),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // GENERAL & PREFERENCES GROUP
          // ====================================================
          Text(
            LanguageController.isUrdu ? 'ترجیحات اور سیکیورٹی' : 'Preferences & Security',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? jordyBlue : yinMnBlue,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
              ),
            ),
            child: Column(
              textDirection: LanguageController.contentTextDirection,
              children: [
                // Profile Details (Professional Placeholder)
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: LanguageController.isUrdu ? 'پروفাইল کی تفصیلات' : 'Profile details',
                  isDark: isDark,
                  onTap: () => _showFeatureDialog('Profile Details', 'Manage your account details and business identity.'),
                ),
                _buildDivider(isDark),

                // Language Selection Dropdown
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.language_rounded, color: isDark ? jordyBlue : yinMnBlue, size: 20),
                  ),
                  title: Text(LanguageController.isUrdu ? 'زبان' : 'Language', textDirection: LanguageController.contentTextDirection, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : oxfordBlue)),
                  subtitle: Text('English / اردو', textDirection: TextDirection.ltr, style: TextStyle(color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600, fontSize: 12)),
                  trailing: PopupMenuButton<Locale>(
                    onSelected: (loc) => LanguageController.changeLanguage(loc),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: Locale('en'), child: Text('🇬🇧 English')),
                      const PopupMenuItem(value: Locale('ur'), child: Text('🇵🇰 اردو')),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(LanguageController.isUrdu ? 'تبدیل کریں' : 'Change', textDirection: LanguageController.contentTextDirection, style: TextStyle(color: isDark ? jordyBlue : yinMnBlue, fontWeight: FontWeight.bold)),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                _buildDivider(isDark),

                // Dark Mode Switch
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.brightness_6_rounded, color: isDark ? jordyBlue : yinMnBlue, size: 20),
                  ),
                  title: Text(LanguageController.isUrdu ? 'ڈارک موڈ' : 'Dark mode', textDirection: LanguageController.contentTextDirection, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : oxfordBlue)),
                  subtitle: Text(isDark ? (LanguageController.isUrdu ? 'فعال' : 'Enabled') : (LanguageController.isUrdu ? 'غیر فعال' : 'Disabled'), textDirection: LanguageController.contentTextDirection, style: TextStyle(color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600, fontSize: 12)),
                  value: isDark,
                  activeColor: jordyBlue,
                  onChanged: (_) {
                    setState(() {
                      ThemeController.toggleTheme();
                    });
                  },
                ),
                _buildDivider(isDark),

                // NEW: Security Settings Navigation Tile (Replaces the raw non-functional switch)
                _buildSettingsTile(
                  icon: Icons.security_rounded,
                  title: LanguageController.isUrdu ? 'سیکیورٹی اور پن لاک' : 'Security & App Lock',
                  subtitle: LanguageController.isUrdu ? 'پن سیٹ کریں، بائیو میٹرکس اور فیس آئی ڈی کا نظم کریں' : 'Configure PIN, biometrics & Face ID setup',
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
                    );
                  },
                ),
                _buildDivider(isDark),

                // Google Drive Backup Option
                _buildSettingsTile(
                  icon: Icons.cloud_upload_rounded,
                  title: LanguageController.isUrdu ? 'گوگل ڈرائیو پر بیک اپ لیں' : 'Backup to Google Drive',
                  subtitle: LanguageController.isUrdu ? 'اپنے اکاؤنٹس، انوائسز اور سپلائرز کو محفوظ طریقے سے مطابقت پذیر بنائیں' : 'Securely sync your accounts, invoices & suppliers',
                  isDark: isDark,
                  onTap: _handleGoogleDriveBackup,
                ),
                _buildDivider(isDark),

                // Data Export option
                _buildSettingsTile(
                  icon: Icons.file_download_outlined,
                  title: LanguageController.isUrdu ? 'گاہکوں کو ایکسل میں ایکسپورٹ کریں' : 'Export Customers to Excel',
                  subtitle: LanguageController.isUrdu ? 'تمام کلائنٹ اندراجات کی .xlsx رپورٹ ڈاؤن لوڈ کریں' : 'Download .xlsx report of all client entries',
                  isDark: isDark,
                  onTap: _exportAllCustomers,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // SUPPORT & SYSTEM GROUP
          // ====================================================
          Text(
            LanguageController.isUrdu ? 'سسٹم اور سپورٹ' : 'System & Support',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? jordyBlue : yinMnBlue,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
              ),
            ),
            child: Column(
              textDirection: LanguageController.contentTextDirection,
              children: [
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: LanguageController.isUrdu ? 'ایپلی کیشن کے بارے میں' : 'About application',
                  subtitle: 'Digital Khata v1.0.0',
                  isDark: isDark,
                  onTap: () => _showFeatureDialog('About Application', 'Digital Khata is your ultimate all-in-one ledger and business management tool built for modern shopkeepers and enterprises.'),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: LanguageController.isUrdu ? 'مدد / عمومی سوالات' : 'Help / FAQ',
                  subtitle: LanguageController.isUrdu ? 'کسٹمر سپورٹ اور گائیڈز حاصل کریں' : 'Get customer support and guides',
                  isDark: isDark,
                  onTap: () => _showFeatureDialog('Help & FAQ', 'For technical assistance, contact support@digitalkhata.app or reach out via WhatsApp.'),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: LanguageController.isUrdu ? 'اپنا اکاؤنٹ غیر فعال کریں' : 'Deactivate my account',
                  isDark: isDark,
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  onTap: () => _showFeatureDialog('Deactivate Account', 'Account deactivation is permanent. Please contact admin support to process requests.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? (isDark ? jordyBlue : yinMnBlue)).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? (isDark ? jordyBlue : yinMnBlue), size: 20),
      ),
      title: Text(
        title,
        textDirection: LanguageController.contentTextDirection,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? (isDark ? Colors.white : oxfordBlue),
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? jordyBlue.withOpacity(0.5) : Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: isDark ? jordyBlue.withOpacity(0.1) : lavender.withOpacity(0.5),
    );
  }
}