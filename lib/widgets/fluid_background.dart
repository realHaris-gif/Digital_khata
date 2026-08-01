import 'package:flutter/material.dart';

class FluidBackground extends StatelessWidget {
  final Widget? child;

  const FluidBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Base & Abstract Waves
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2948AC),
                Color(0xFF3F5ED8),
                Color(0xFF5374EA),
              ],
            ),
          ),
          child: CustomPaint(
            painter: WavePainter(),
            size: Size.infinite,
          ),
        ),

        // 3D Spheres
        Positioned(
          top: -30,
          left: -20,
          child: _buildSphere(90, const Color(0xFF1E358A)),
        ),
        Positioned(
          top: 70,
          right: -40,
          child: _buildSphere(130, const Color(0xFF8AA6FF).withValues(alpha: 0.6)),
        ),
        Positioned(
          top: 240,
          left: 20,
          child: _buildSphere(40, Colors.white.withValues(alpha: 0.8)),
        ),
        Positioned(
          top: 280,
          right: 30,
          child: _buildSphere(100, const Color(0xFF1A37B0)),
        ),

        if (child != null) child!,
      ],
    );
  }

  Widget _buildSphere(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(4, 8),
          )
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B5BCC).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.35,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}