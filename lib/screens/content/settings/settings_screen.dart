import 'package:flutter/material.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import '../../../services/platform_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PlatformServices _platformServices = PlatformServices();
  bool _biometricsEnabled = false;

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

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Option
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: const Text('Dark Mode'),
            subtitle: Text(isDark ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) {
                setState(() {
                  ThemeController.toggleTheme();
                });
              },
            ),
          ),
          const Divider(),

          // Language Switching
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Language'),
            subtitle: const Text('English / اردو'),
            trailing: PopupMenuButton<Locale>(
              onSelected: (loc) => LanguageController.changeLanguage(loc),
              itemBuilder: (_) => [
                const PopupMenuItem(value: Locale('en'), child: Text('🇬🇧 English')),
                const PopupMenuItem(value: Locale('ur'), child: Text('🇵🇰 اردو')),
              ],
            ),
          ),
          const Divider(),

          // Security & Biometrics
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Use Face ID or Fingerprint on startup'),
            trailing: Switch(
              value: _biometricsEnabled,
              onChanged: (val) async {
                if (val) {
                  final authenticated = await _platformServices.authenticateWithBiometrics();
                  if (authenticated) {
                    setState(() => _biometricsEnabled = true);
                  }
                } else {
                  setState(() => _biometricsEnabled = false);
                }
              },
            ),
          ),
          const Divider(),

          // Data Export
          ListTile(
            leading: const Icon(Icons.file_download_outlined, color: Colors.teal),
            title: const Text('Export Customers to Excel'),
            subtitle: const Text('Download .xlsx report of all client entries'),
            onTap: _exportAllCustomers,
          ),
        ],
      ),
    );
  }
}