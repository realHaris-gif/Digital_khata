import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/pin_service.dart';
import '../../../services/local_auth_service.dart';
import '../../../services/security_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  String _enteredPin = '';
  bool _isAuthenticating = false;
  int _remainingAttempts = 3;

  // Animation Controllers for 60fps micro-interactions
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  // Splash-matching background blob animation controllers
  late AnimationController _blobController;
  late Animation<double> _blobAnimation;

  // Palette Constants Matching App Theme & Splash
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Shake controller for invalid PIN entries
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Subtle background blob floating animation
    _blobController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _blobAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _blobController, curve: Curves.easeInOut),
    );

    // Automatically trigger biometrics on start if configured
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      SecurityService.isAppUnlocked = false;
    }
  }

  Future<void> _tryBiometricAuth() async {
    if (_isAuthenticating) return;
    final bioEnabled = await LocalAuthService.isBiometricEnabled();
    if (!bioEnabled) return;

    setState(() => _isAuthenticating = true);
    final success = await LocalAuthService.authenticateUser(
      reason: 'Authenticate to unlock your digital workspace',
    );
    if (mounted) {
      setState(() => _isAuthenticating = false);
    }

    if (success) {
      _unlockApp();
    }
  }

  void _unlockApp() {
    SecurityService.isAppUnlocked = true;
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _onKeyPressed(String value) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += value;
      });
      if (_enteredPin.length == 4 || _enteredPin.length == 6) {
        _verifyEnteredPin();
      }
    }
  }

  void _onDeleteOrCancelPressed() {
    HapticFeedback.selectionClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyEnteredPin() async {
    final isValid = await PinService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (isValid) {
      HapticFeedback.mediumImpact();
      _unlockApp();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _remainingAttempts--;
        _enteredPin = '';
      });
      if (_remainingAttempts <= 0) {
        // Additional restriction handling if max attempts reached
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: oxfordBlue,
      body: Stack(
        children: [
          // ==========================================
          // SPLASH SCREEN MATCHING BACKGROUND SYSTEM
          // ==========================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [oxfordBlue, spaceCadet, yinMnBlue],
                ),
              ),
            ),
          ),
          // Animated Colorful Frosted Blobs matching splash
          AnimatedBuilder(
            animation: _blobAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -80 + _blobAnimation.value,
                    left: -50 - _blobAnimation.value,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: jordyBlue.withOpacity(0.18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100 - _blobAnimation.value,
                    right: -60 + _blobAnimation.value,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: yinMnBlue.withOpacity(0.25),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Heavy Gaussian Blur & Vignette Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==========================================
          // LOCK SCREEN UI INTERFACE
          // ==========================================
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      
                      // Brand Icon Glass Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: spaceCadet.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: jordyBlue.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_rounded,
                                color: jordyBlue,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title Header
                      const Text(
                        'Enter Passcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure access to your digital vault',
                        style: TextStyle(
                          color: lavender.withOpacity(0.7),
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Animated Passcode Dots Indicator
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                bool isFilled = index < _enteredPin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  width: isFilled ? 16 : 14,
                                  height: isFilled ? 16 : 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled
                                        ? jordyBlue
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isFilled ? jordyBlue : lavender.withOpacity(0.4),
                                      width: 2,
                                    ),
                                    boxShadow: isFilled
                                        ? [
                                            BoxShadow(
                                              color: jordyBlue.withOpacity(0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [],
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),

                      const Spacer(flex: 1),

                      // ==========================================
                      // MODERN GLASSMORPHIC KEYPAD
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            for (var row in [
                              ['1', '2', '3'],
                              ['4', '5', '6'],
                              ['7', '8', '9'],
                              ['bio', '0', 'del']
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: row.map((val) {
                                    if (val == 'bio') {
                                      return _buildKeypadButton(
                                        child: const Icon(
                                          Icons.fingerprint_rounded,
                                          color: jordyBlue,
                                          size: 30,
                                        ),
                                        onTap: _tryBiometricAuth,
                                      );
                                    } else if (val == 'del') {
                                      return _buildKeypadButton(
                                        child: const Icon(
                                          Icons.backspace_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onTap: _onDeleteOrCancelPressed,
                                      );
                                    } else {
                                      return _buildKeypadButton(
                                        child: Text(
                                          val,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onTap: () => _onKeyPressed(val),
                                      );
                                    }
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Frosted Glass Keypad Button Component
  Widget _buildKeypadButton({required Widget child, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          splashColor: jordyBlue.withOpacity(0.2),
          highlightColor: jordyBlue.withOpacity(0.1),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spaceCadet.withOpacity(0.35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}