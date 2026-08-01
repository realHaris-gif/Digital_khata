import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Output Area
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                child: FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 84,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
              ),
            ),

            // Button Keypad Grid (iOS Layout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildButtonRow(['AC', '+/-', '%', '÷'],
                      topRow: true),
                  const SizedBox(height: 12),
                  _buildButtonRow(['7', '8', '9', '×']),
                  const SizedBox(height: 12),
                  _buildButtonRow(['4', '5', '6', '−']),
                  const SizedBox(height: 12),
                  _buildButtonRow(['1', '2', '3', '+']),
                  const SizedBox(height: 12),
                  _buildBottomRow(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> texts, {bool topRow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: texts.map((t) {
        final isOperator = ['÷', '×', '−', '+', '='].contains(t);
        Color btnColor;
        Color txtColor = Colors.white;

        if (isOperator) {
          btnColor = const Color(0xFFFF9F0A); // iOS Orange
        } else if (topRow) {
          btnColor = const Color(0xFFA5A5A5); // iOS Light Gray
          txtColor = Colors.black;
        } else {
          btnColor = const Color(0xFF333333); // iOS Dark Gray
        }

        return _buildCalcButton(
          text: t,
          bgColor: btnColor,
          textColor: txtColor,
          isSelected: _operator == t && _shouldResetDisplay,
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Wide "0" Button
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () => _onButtonTap('0'),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 72,
              padding: const EdgeInsets.only(left: 28),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Text(
                '0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCalcButton(
            text: '.',
            bgColor: const Color(0xFF333333),
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCalcButton(
            text: '=',
            bgColor: const Color(0xFFFF9F0A),
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCalcButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    bool isSelected = false,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isSelected ? Colors.white : bgColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onButtonTap(text),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF9F0A) : textColor,
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}