import 'package:flutter/material.dart';
import '../../../services/pin_service.dart';
import '../../../services/local_auth_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final hasPin = await PinService.hasPin();
    final bioSupported = await LocalAuthService.isDeviceSupported();
    final bioEnabled = await LocalAuthService.isBiometricEnabled();
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = bioSupported;
      _isBiometricEnabled = bioEnabled;
    });
  }

  Future<void> _promptPinSetup({bool isChanging = false}) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    if (isChanging) {
      final verified = await _verifyCurrentPinFlow();
      if (!verified) return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isChanging ? 'Change PIN' : 'Create 4-digit PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter new PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length >= 4) {
                await PinService.savePin(pinController.text);
                Navigator.pop(context);
                _loadSecurityState();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN successfully saved')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyCurrentPinFlow() async {
    final controller = TextEditingController();
    bool verified = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Current PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Current PIN'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (await PinService.verifyPin(controller.text)) {
                verified = true;
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    return verified;
  }

  Future<void> _disableAppLockFlow() async {
    final verified = await _verifyCurrentPinFlow();
    if (verified) {
      await PinService.removePin();
      await LocalAuthService.setBiometricEnabled(false);
      _loadSecurityState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App Lock disabled successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable App Lock'),
            subtitle: const Text('Secure application access using a PIN'),
            value: _hasPin,
            onChanged: (val) async {
              if (val) {
                await _promptPinSetup();
              } else {
                await _disableAppLockFlow();
              }
            },
          ),
          if (_hasPin) ...[
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change PIN'),
              onTap: () => _promptPinSetup(isChanging: true),
            ),
            if (_biometricAvailable)
              SwitchListTile(
                title: const Text('Enable Biometrics / Face ID'),
                subtitle: const Text('Use fingerprint or face recognition'),
                value: _isBiometricEnabled,
                onChanged: (val) async {
                  if (val) {
                    final authenticated = await LocalAuthService.authenticateUser(
                      reason: 'Verify identity to enable biometrics',
                    );
                    if (authenticated) {
                      await LocalAuthService.setBiometricEnabled(true);
                      setState(() => _isBiometricEnabled = true);
                    }
                  } else {
                    await LocalAuthService.setBiometricEnabled(false);
                    setState(() => _isBiometricEnabled = false);
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}