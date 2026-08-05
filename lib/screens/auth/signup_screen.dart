import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  final void Function()? onTap;
  final void Function()? onCustomerTap;

  const SignupScreen({
    super.key,
    required this.onTap,
    required this.onCustomerTap,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _agreeToTerms = false;

  // Consistent Palette Constants matching your blue theme
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signupUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (!_agreeToTerms) {
      _showMessage('Please agree to the processing of Personal data.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': response.user!.id,
          'email': response.user!.email,
          'username': fullName,
        });
      }

      if (!mounted) return;

      if (response.session != null) {
        context.go('/');
      } else {
        _showMessage('Account created! Please verify your email.');
        if (widget.onTap != null) {
          widget.onTap!(); // Return to sign-in view
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              // Top Back Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.go('/auth'),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chevron_left, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: TextStyle(
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
                  ],
                ),
              ),

              // Main Glassmorphism Form Container stretching fully to bottom before footer
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Full Name Field
                              _buildTextField(
                                label: 'Full Name',
                                hint: 'Enter Full Name',
                                controller: fullNameController,
                              ),
                              const SizedBox(height: 14),

                              // Email Field
                              _buildTextField(
                                label: 'Email',
                                hint: 'Enter Email',
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              // Password Field
                              _buildTextField(
                                label: 'Password',
                                hint: 'Enter Password',
                                controller: passwordController,
                                isObscure: true,
                              ),
                              const SizedBox(height: 12),

                              // Terms & Conditions Checkbox Row
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
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                                        children: [
                                          const TextSpan(text: 'I agree to the processing of '),
                                          const TextSpan(
                                            text: 'Personal data',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Sign Up Button
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
                                  onPressed: _isLoading ? null : signupUser,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: oxfordBlue)
                                      : const Text(
                                          'Sign up',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Social Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Sign up with',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Social Icons
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

                              // Navigation Toggles
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                                  ),
                                  GestureDetector(
                                    onTap: widget.onTap,
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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

              // Footer branding visible at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  'Powered by zenvyrolabs',
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
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