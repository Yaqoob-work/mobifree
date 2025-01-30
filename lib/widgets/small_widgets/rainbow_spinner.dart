import 'package:flutter/material.dart';
import 'dart:math' as math;

class RainbowSpinner extends StatefulWidget {
  final double size;
  final Color? backgroundColor; // बैकग्राउंड कलर के लिए नया पैरामीटर
  
  const RainbowSpinner({
    Key? key,
    this.size = 100.0,
    this.backgroundColor, // बैकग्राउंड कलर ऑप्शनल है
  }) : super(key: key);

  @override
  _RainbowSpinnerState createState() => _RainbowSpinnerState();
}

class _RainbowSpinnerState extends State<RainbowSpinner>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller3 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor, // बैकग्राउंड कलर सेट करें
        shape: BoxShape.circle, // गोल शेप के लिए
      ),
      child: Stack(
        children: [
          _buildSpinningCircle(
            controller: _controller1,
            colors: [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.blue,
            ],
            padding: 0,
          ),
          _buildSpinningCircle(
            controller: _controller2,
            colors: [
              Colors.purple,
              Colors.pink,
              Colors.indigo,
              Colors.orange,
            ],
            padding: widget.size * 0.1,
          ),
          _buildSpinningCircle(
            controller: _controller3,
            colors: [
              Colors.teal,
              Colors.cyan,
              Colors.lightGreen,
              Colors.deepPurple,
            ],
            padding: widget.size * 0.2,
          ),
        ],
      ),
    );
  }

  Widget _buildSpinningCircle({
    required AnimationController controller,
    required List<Color> colors,
    required double padding,
  }) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: controller.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RainbowCirclePainter(colors: colors),
            ),
          );
        },
      ),
    );
  }
}

class _RainbowCirclePainter extends CustomPainter {
  final List<Color> colors;

  _RainbowCirclePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    for (int i = 0; i < colors.length; i++) {
      final sweepAngle = 2 * math.pi / colors.length;
      final startAngle = i * sweepAngle;
      
      paint.color = colors[i];
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainbowCirclePainter oldDelegate) => false;
}