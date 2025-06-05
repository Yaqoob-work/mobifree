import 'package:flutter/material.dart';
import 'dart:math' as math;

class PuzzleLoader extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final bool showGlow;
  final bool showPulse;
  final double strokeWidth;
  final List<Color>? customColors;
  
  const PuzzleLoader({
    Key? key,
    this.size = 100.0,
    this.backgroundColor,
    this.showGlow = true,
    this.showPulse = true,
    this.strokeWidth = 8.0,
    this.customColors,
  }) : super(key: key);

  @override
  _PuzzleLoaderState createState() => _PuzzleLoaderState();
}

class _PuzzleLoaderState extends State<PuzzleLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main rotation controller
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  List<Color> get _rainbowColors => widget.customColors ?? [
    const Color.fromARGB(255, 238, 45, 45), // Red
    const Color.fromARGB(255, 4, 247, 247), // Yellow
    const Color.fromARGB(255, 8, 241, 39), // Teal
    const Color.fromARGB(255, 236, 20, 190), // Blue
    const Color.fromARGB(255, 11, 7, 243), // Green
    const Color.fromARGB(255, 247, 8, 60), // Pink
    const Color.fromARGB(255, 236, 4, 236), // Plum
    const Color.fromARGB(255, 9, 247, 29), // Mint
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationController,
        _pulseController,
        _glowController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: widget.showGlow ? [
                BoxShadow(
                  color: _rainbowColors[0].withOpacity(0.5 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: _rainbowColors[2].withOpacity(0.2 * _glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                // Outer spinning ring
                _buildAdvancedSpinningRing(
                  controller: _rotationController,
                  colors: _rainbowColors,
                  padding: 0,
                  strokeWidth: widget.strokeWidth,
                  gradientSweep: 0.7,
                ),
                // Middle spinning ring (opposite direction)
                Transform.rotate(
                  angle: -_rotationController.value * 1 * math.pi * 0.5,
                  child: _buildAdvancedSpinningRing(
                    controller: _rotationController,
                    colors: _rainbowColors.reversed.toList(),
                    padding: widget.size * 0.15,
                    strokeWidth: widget.strokeWidth * 0.7,
                    gradientSweep: 0.5,
                  ),
                ),
                // Inner spinning dots
                _buildSpinningDots(),
                // Center glow effect
                if (widget.showGlow)
                  Center(
                    child: Container(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _rainbowColors[1].withOpacity(0.4 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedSpinningRing({
    required AnimationController controller,
    required List<Color> colors,
    required double padding,
    required double strokeWidth,
    required double gradientSweep,
  }) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: CustomPaint(
        size: Size(widget.size - padding * 2, widget.size - padding * 2),
        painter: _AdvancedRainbowPainter(
          colors: colors,
          strokeWidth: strokeWidth,
          gradientSweep: gradientSweep,
          animationValue: controller.value,
        ),
      ),
    );
  }

  Widget _buildSpinningDots() {
    return Transform.rotate(
      angle: _rotationController.value * 1 * math.pi * 1,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: List.generate(6, (index) {
            final angle = (index * 2 * math.pi) / 6;
            final radius = widget.size * 0.35;
            final x = widget.size / 2 + radius * math.cos(angle) - 4;
            final y = widget.size / 2 + radius * math.sin(angle) - 4;
            
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rainbowColors[index % _rainbowColors.length],
                  boxShadow: [
                    BoxShadow(
                      color: _rainbowColors[index % _rainbowColors.length]
                          .withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AdvancedRainbowPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final double gradientSweep;
  final double animationValue;

  _AdvancedRainbowPainter({
    required this.colors,
    required this.strokeWidth,
    required this.gradientSweep,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Create gradient paint
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw gradient arcs
    for (int i = 0; i < colors.length; i++) {
      final sweepAngle = (2 * math.pi * gradientSweep) / colors.length;
      final startAngle = (i * sweepAngle) + (animationValue * 2 * math.pi);
      
      // Create gradient for each segment
      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: sweepAngle,
        colors: [
          colors[i].withOpacity(0.5),
          colors[i],
          colors[(i + 1) % colors.length].withOpacity(0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      
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
  bool shouldRepaint(_AdvancedRainbowPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

// Usage example:
class LoadingDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large spinner with glow
            PuzzleLoader(
              size: 120,
              showGlow: true,
              showPulse: true,
              strokeWidth: 20,
            ),
            SizedBox(height: 50),
            
            // Medium spinner without glow
            PuzzleLoader(
              size: 80,
              showGlow: false,
              showPulse: true,
              strokeWidth: 10,
              backgroundColor: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: 50),
            
            // Small spinner with custom colors
            PuzzleLoader(
              size: 60,
              showGlow: true,
              showPulse: false,
              strokeWidth: 4,
              customColors: [
                Colors.cyan,
                Colors.purple,
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
              ],
            ),
          ],
        ),
      ),
    );
  }
}




/*// Basic usage
PuzzleLoader(size: 100)

// With custom settings
PuzzleLoader(
  size: 120,
  showGlow: true,
  strokeWidth: 12,
  backgroundColor: Colors.black.withOpacity(0.1),
)

// Custom colors
PuzzleLoader(
  customColors: [Colors.blue, Colors.purple, Colors.pink],
)*/ 