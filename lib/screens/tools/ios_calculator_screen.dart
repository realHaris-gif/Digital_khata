import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

class IosCalculatorScreen extends StatefulWidget {
  const IosCalculatorScreen({super.key});

  @override
  State<IosCalculatorScreen> createState() => _IosCalculatorScreenState();
}

class _IosCalculatorScreenState extends State<IosCalculatorScreen> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onButtonTap(String text) {
    setState(() {
      if (text == 'AC') {
        _display = '0';
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = false;
      } else if (text == '+/-') {
        if (_display != '0') {
          if (_display.startsWith('-')) {
            _display = _display.substring(1);
          } else {
            _display = '-$_display';
          }
        }
      } else if (text == '%') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(val / 100);
      } else if (['+', '−', '×', '÷'].contains(text)) {
        _firstOperand = double.tryParse(_display);
        _operator = text;
        _shouldResetDisplay = true;
      } else if (text == '=') {
        if (_firstOperand != null && _operator != null) {
          final secondOperand = double.tryParse(_display) ?? 0;
          double result = 0;
          switch (_operator) {
            case '+':
              result = _firstOperand! + secondOperand;
              break;
            case '−':
              result = _firstOperand! - secondOperand;
              break;
            case '×':
              result = _firstOperand! * secondOperand;
              break;
            case '÷':
              result = secondOperand != 0 ? _firstOperand! / secondOperand : 0;
              break;
          }
          _display = _formatResult(result);
          _firstOperand = null;
          _operator = null;
          _shouldResetDisplay = true;
        }
      } else if (text == '.') {
        if (_shouldResetDisplay) {
          _display = '0.';
          _shouldResetDisplay = false;
        } else if (!_display.contains('.')) {
          _display += '.';
        }
      } else {
        // Digits 0-9
        if (_display == '0' || _shouldResetDisplay) {
          _display = text;
          _shouldResetDisplay = false;
        } else {
          if (_display.length < 9) {
            _display += text;
          }
        }
      }
    });
  }

  String _formatResult(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    final str = val.toString();
    if (str.length > 9) {
      return val.toStringAsPrecision(6);
    }
    return str;
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
              'Calculator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.oxfordBlue,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Enhanced Beige Display Output Area
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  alignment: Alignment.bottomRight,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface.withValues(alpha: 0.8) : const Color(0xFFFBF7EE), // Elegant Beige
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.2) : const Color(0xFFEFE8D8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 90,
                    child: FittedBox(
                      alignment: Alignment.centerRight,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.oxfordBlue,
                          fontSize: 64,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                ),

                // Button Keypad Grid (iOS Layout with Custom Blue Theme)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildButtonRow(['AC', '+/-', '%', '÷'], topRow: true, isDark: isDark),
                        const SizedBox(height: 12),
                        _buildButtonRow(['7', '8', '9', '×'], isDark: isDark),
                        const SizedBox(height: 12),
                        _buildButtonRow(['4', '5', '6', '−'], isDark: isDark),
                        const SizedBox(height: 12),
                        _buildButtonRow(['1', '2', '3', '+'], isDark: isDark),
                        const SizedBox(height: 12),
                        _buildBottomRow(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> texts, {bool topRow = false, required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: texts.map((t) {
        final isOperator = ['÷', '×', '−', '+', '='].contains(t);
        Color btnColor;
        Color txtColor = isDark ? Colors.white : AppColors.oxfordBlue;

        if (isOperator) {
          btnColor = isDark ? AppColors.jordyBlue : AppColors.yinMnBlue; // Primary Theme Accent
          txtColor = isDark ? AppColors.oxfordBlue : Colors.white;
        } else if (topRow) {
          btnColor = isDark ? AppColors.darkSurface : AppColors.lavender; // Secondary UI Tone
          txtColor = isDark ? AppColors.lavender : AppColors.oxfordBlue;
        } else {
          btnColor = isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white; // Standard Button
        }

        return _buildCalcButton(
          text: t,
          bgColor: btnColor,
          textColor: txtColor,
          isSelected: _operator == t && _shouldResetDisplay,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Wide "0" Button
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () => _onButtonTap('0'),
            borderRadius: BorderRadius.circular(36),
            child: Container(
              height: 72,
              padding: const EdgeInsets.only(left: 28),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : AppColors.lavender,
                ),
              ),
              child: Text(
                '0',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.oxfordBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCalcButton(
            text: '.',
            bgColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
            textColor: isDark ? Colors.white : AppColors.oxfordBlue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCalcButton(
            text: '=',
            bgColor: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
            textColor: isDark ? AppColors.oxfordBlue : Colors.white,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCalcButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required bool isDark,
    bool isSelected = false,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isSelected ? AppColors.lavender : bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(36),
          side: BorderSide(
            color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : AppColors.lavender,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          onTap: () => _onButtonTap(text),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? AppColors.oxfordBlue : textColor,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}