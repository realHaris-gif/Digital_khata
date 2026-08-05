import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/controller/language_controller.dart';

enum AuthFlowStage { splash, languageSelect, welcome, signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialStage = 'splash',
  });

  final String initialStage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthFlowStage _currentStage;

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  // Language selection state (default is English)
  String _selectedLanguage = 'en';

  // Consistent Palette Constants matching your blue theme
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _currentStage = _parseInitialStage(widget.initialStage);
  }

  AuthFlowStage _parseInitialStage(String stage) {
    switch (stage) {
      case 'welcome':
        return AuthFlowStage.welcome;
      case 'signIn':
        return AuthFlowStage.signIn;
      case 'signUp':
        return AuthFlowStage.signUp;
      case 'languageSelect':
        return AuthFlowStage.languageSelect;
      default:
        return AuthFlowStage.splash;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// Handles sign-in with strict role checking to route super admins straight to /admin
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(LanguageController.isUrdu ? 'براہ کرم ای میل اور پاس ورڈ دونوں درج کریں۔' : 'Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (res.session != null && mounted) {
        final userId = res.session!.user.id;
        
        // Fetch profile details to check if user is blocked or is a super admin
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('is_super_admin, is_blocked')
            .eq('id', userId)
            .maybeSingle();

        if (profileRes != null && profileRes['is_blocked'] == true) {
          await Supabase.instance.client.auth.signOut();
          _showMessage(LanguageController.isUrdu ? 'آپ کا اکاؤنٹ ایڈمنسٹریٹر کی طرف سے مسدود کر دیا گیا ہے۔' : 'Your account has been blocked by the administrator.');
          return;
        }

        final bool isSuperAdmin = profileRes != null && (profileRes['is_super_admin'] == true);

        // Enforce strict routing: Admin goes exclusively to /admin, users go to /
        if (isSuperAdmin) {
          context.go('/admin');
        } else {
          context.go('/');
        }
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(LanguageController.isUrdu ? 'سائن ان ناکام ہو گیا: $e' : 'Sign in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(LanguageController.isUrdu ? 'براہ کرم تمام خانے پُر کریں۔' : 'Please fill in all fields.');
      return;
    }

    if (!_agreeToTerms) {
      _showMessage(LanguageController.isUrdu ? 'براہ کرم ذاتی ڈیٹا کی پروسیسنگ سے اتفاق کریں۔' : 'Please agree to the processing of Personal data.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
          'is_super_admin': false,
          'is_blocked': false,
        });
      }

      if (mounted) {
        if (res.session != null) {
          context.go('/');
        } else {
          _showMessage(LanguageController.isUrdu ? 'اکاؤنٹ بن گیا! براہ کرم اپنا ای میل تصدیق کریں۔' : 'Account created! Please verify your email.');
          setState(() => _currentStage = AuthFlowStage.signIn);
        }
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(LanguageController.isUrdu ? 'رجسٹریشن ناکام ہو گئی: $e' : 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGlassCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            fillColor: WidgetStateProperty.resolveWith((states) => Colors.white),
            checkColor: oxfordBlue,
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/auth_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildStageWidget(),
                    ),
                  ),
                ),
              ),
              // Footer included cleanly at the bottom of the screen
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  LanguageController.isUrdu ? 'zenvyrolabs کے ذریعہ تقویت یافتہ' : 'Powered by zenvyrolabs',
                  textDirection: LanguageController.contentTextDirection,
                  textAlign: LanguageController.contentTextAlign,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageWidget() {
    switch (_currentStage) {
      case AuthFlowStage.splash:
        return _buildSplashScreen();
      case AuthFlowStage.languageSelect:
        return _buildLanguageSelectScreen();
      case AuthFlowStage.welcome:
        return _buildWelcomeScreen();
      case AuthFlowStage.signUp:
        return _buildFormSheet(isSignUp: true);
      case AuthFlowStage.signIn:
        return _buildFormSheet(isSignUp: false);
    }
  }

  // --- STAGE 1: SPLASH SCREEN WITH CUSTOM LOGO ---
  Widget _buildSplashScreen() {
    return KeyedSubtree(
      key: const ValueKey('splash_screen'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: jordyBlue.withOpacity(0.4), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LanguageController.isUrdu ? 'ڈیجیٹل খাতা' : 'Digital Khata',
              textDirection: LanguageController.contentTextDirection,
              textAlign: LanguageController.contentTextAlign,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LanguageController.isUrdu ? 'آپ کا ہمہ گیر کاروباری کھاتہ' : 'Your All-in-One Business Ledger',
              textDirection: LanguageController.contentTextDirection,
              textAlign: LanguageController.contentTextAlign,
              style: TextStyle(
                fontSize: 14,
                color: lavender.withOpacity(0.85),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: yinMnBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  setState(() => _currentStage = AuthFlowStage.languageSelect);
                },
                child: Text(
                  LanguageController.isUrdu ? 'اگلا' : 'Next',
                  textDirection: LanguageController.contentTextDirection,
                  textAlign: LanguageController.contentTextAlign,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- STAGE 2: PREMIUM APPLE GLASSMORPHISM LANGUAGE SELECTION SCREEN ---
  Widget _buildLanguageSelectScreen() {
    return KeyedSubtree(
      key: const ValueKey('language_screen'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.language_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  LanguageController.isUrdu ? 'اپنی پسندیدہ زبان منتخب کریں' : 'Select Your Preferred Language',
                  textDirection: LanguageController.contentTextDirection,
                  textAlign: LanguageController.contentTextAlign,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageController.isUrdu ? 'زبان' : 'Language',
                        textDirection: LanguageController.contentTextDirection,
                        textAlign: LanguageController.contentTextAlign,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LanguageController.isUrdu ? 'منتخب کریں کہ آپ ڈیجیٹل کھاتہ کا تجربہ کیسے کرنا چاہتے ہیں' : 'Choose how you want to experience Digital Khata',
                        textDirection: LanguageController.contentTextDirection,
                        textAlign: LanguageController.contentTextAlign,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // English Card
                      _buildLanguageCard(
                        title: 'English',
                        subtitle: _selectedLanguage == 'en' ? 'Default' : null,
                        isSelected: _selectedLanguage == 'en',
                        onTap: () {
                          setState(() => _selectedLanguage = 'en');
                        },
                      ),
                      const SizedBox(height: 14),

                      // Urdu Card
                      _buildLanguageCard(
                        title: 'اردو',
                        subtitle: _selectedLanguage == 'ur' ? 'Urdu' : null,
                        isSelected: _selectedLanguage == 'ur',
                        onTap: () {
                          setState(() => _selectedLanguage = 'ur');
                        },
                      ),
                      const SizedBox(height: 28),

                      // Active Next Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: oxfordBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            LanguageController.changeLanguage(Locale(_selectedLanguage));
                            setState(() => _currentStage = AuthFlowStage.welcome);
                          },
                          child: Text(
                            LanguageController.isUrdu ? 'اگلا' : 'Next',
                            textDirection: LanguageController.contentTextDirection,
                            textAlign: LanguageController.contentTextAlign,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildLanguageCard({
    required String title,
    required String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.15),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: oxfordBlue),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textDirection: LanguageController.contentTextDirection,
                  textAlign: LanguageController.contentTextAlign,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    textDirection: LanguageController.contentTextDirection,
                    textAlign: LanguageController.contentTextAlign,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- STAGE 3: WELCOME CHOICE SCREEN ---
  Widget _buildWelcomeScreen() {
    return KeyedSubtree(
      key: const ValueKey('welcome_screen'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  LanguageController.isUrdu ? 'خوش آمدید!' : 'Welcome Back!',
                  textDirection: LanguageController.contentTextDirection,
                  textAlign: LanguageController.contentTextAlign,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  LanguageController.isUrdu ? 'اپنے کاروباری کھاتے کو محفوظ طریقے سے\nاور مؤثر طریقے سے منظم کریں' : 'Manage your business ledger securely\nand efficiently',
                  textDirection: LanguageController.contentTextDirection,
                  textAlign: LanguageController.contentTextAlign,
                  style: TextStyle(
                    fontSize: 15,
                    color: lavender.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _currentStage = AuthFlowStage.signIn);
                          },
                          child: Text(
                            LanguageController.isUrdu ? 'سائن ان' : 'Sign in',
                            textDirection: LanguageController.contentTextDirection,
                            textAlign: LanguageController.contentTextAlign,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextButton(
                            onPressed: () {
                              setState(() => _currentStage = AuthFlowStage.signUp);
                            },
                            child: Text(
                              LanguageController.isUrdu ? 'سائن اپ' : 'Sign up',
                              textDirection: LanguageController.contentTextDirection,
                              textAlign: LanguageController.contentTextAlign,
                              style: TextStyle(
                                color: yinMnBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  // --- STAGE 4 & 5: SIGN IN / SIGN UP FORMS ---
  Widget _buildFormSheet({required bool isSignUp}) {
    return KeyedSubtree(
      key: ValueKey(isSignUp ? 'signup_sheet' : 'signin_sheet'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() => _currentStage = AuthFlowStage.welcome);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            LanguageController.isUrdu ? 'واپس' : 'Back',
                            textDirection: LanguageController.contentTextDirection,
                            textAlign: LanguageController.contentTextAlign,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      child: Column(
                        children: [
                          Text(
                            isSignUp ? (LanguageController.isUrdu ? 'شروع کریں' : 'Get Started') : (LanguageController.isUrdu ? 'خوش آمدید' : 'Welcome back'),
                            textDirection: LanguageController.contentTextDirection,
                            textAlign: LanguageController.contentTextAlign,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (isSignUp) ...[
                            _buildTextField(
                              label: LanguageController.isUrdu ? 'پورا نام' : 'Full Name',
                              hint: LanguageController.isUrdu ? 'پورا نام درج کریں' : 'Enter Full Name',
                              controller: _fullNameController,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildTextField(
                            label: LanguageController.isUrdu ? 'ای میل' : 'Email',
                            hint: LanguageController.isUrdu ? 'ای میل درج کریں' : 'Enter Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            label: LanguageController.isUrdu ? 'پاس ورڈ' : 'Password',
                            hint: LanguageController.isUrdu ? 'پاس ورڈ درج کریں' : 'Enter Password',
                            controller: _passwordController,
                            isObscure: true,
                          ),
                          const SizedBox(height: 14),
                          if (isSignUp)
                            Row(
                              children: [
                                _buildGlassCheckbox(
                                  value: _agreeToTerms,
                                  onChanged: (val) {
                                    setState(() => _agreeToTerms = val ?? false);
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    textDirection: LanguageController.contentTextDirection,
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                                      children: [
                                        TextSpan(text: LanguageController.isUrdu ? 'میں ذاتی ڈیٹا کی پروسیسنگ سے اتفاق کرتا ہوں۔ ' : 'I agree to the processing of '),
                                        TextSpan(
                                          text: LanguageController.isUrdu ? 'ذاتی ڈیٹا' : 'Personal data',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildGlassCheckbox(
                                      value: _rememberMe,
                                      onChanged: (val) {
                                        setState(() => _rememberMe = val ?? false);
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      LanguageController.isUrdu ? 'مجھے یاد رکھیں' : 'Remember me',
                                      textDirection: LanguageController.contentTextDirection,
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    LanguageController.isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot password?',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: oxfordBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : (isSignUp ? _handleSignUp : _handleSignIn),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: oxfordBlue)
                                  : Text(
                                      isSignUp ? (LanguageController.isUrdu ? 'سائن اپ' : 'Sign up') : (LanguageController.isUrdu ? 'سائن ان' : 'Sign in'),
                                      textDirection: LanguageController.contentTextDirection,
                                      textAlign: LanguageController.contentTextAlign,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  isSignUp ? (LanguageController.isUrdu ? 'اس کے ساتھ سائن اپ کریں' : 'Sign up with') : (LanguageController.isUrdu ? 'اس کے ساتھ سائن ان کریں' : 'Sign in with'),
                                  textDirection: LanguageController.contentTextDirection,
                                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialIcon(Icons.facebook, const Color(0xFF1877F2)),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.g_mobiledata, Colors.redAccent, size: 32),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.apple, Colors.white, size: 26),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                isSignUp ? (LanguageController.isUrdu ? 'پہلے سے اکاؤنٹ ہے؟ ' : 'Already have an account? ') : (LanguageController.isUrdu ? 'اکاؤنٹ نہیں ہے؟ ' : 'Don\'t have an account? '),
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentStage = isSignUp ? AuthFlowStage.signIn : AuthFlowStage.signUp;
                                  });
                                },
                                child: Text(
                                  isSignUp ? (LanguageController.isUrdu ? 'سائن ان' : 'Sign in') : (LanguageController.isUrdu ? 'سائن اپ' : 'Sign up'),
                                  textDirection: LanguageController.contentTextDirection,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textDirection: LanguageController.contentTextDirection,
          textAlign: LanguageController.contentTextAlign,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          textDirection: LanguageController.contentTextDirection,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, {double size = 22}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}