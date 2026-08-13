import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// RPM Gauge Loader based on the custom GarageOS Tachometer design.
class RpmGaugeLoader extends StatefulWidget {
  final String brandName;
  final List<String>? statusMessages;
  final double size;
  final bool fullScreen;

  const RpmGaugeLoader({
    super.key,
    this.brandName = 'GarageOS',
    this.statusMessages,
    this.size = 220.0,
    this.fullScreen = false,
  });

  static void show(BuildContext context, {String brandName = 'GarageOS', List<String>? statusMessages}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: RpmGaugeLoader(
            brandName: brandName,
            statusMessages: statusMessages,
            size: 200.0,
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  State<RpmGaugeLoader> createState() => _RpmGaugeLoaderState();
}

class _RpmGaugeLoaderState extends State<RpmGaugeLoader> with SingleTickerProviderStateMixin {
  late AnimationController _revController;
  late Animation<double> _needleAnimation;
  Timer? _statusTimer;
  int _currentStatusIndex = 0;

  late final List<String> _messages;

  @override
  void initState() {
    super.initState();
    _messages = widget.statusMessages ?? [
      "Checking your bike's history",
      "Pulling up job cards",
      "Loading service records",
      "Almost ready",
    ];

    // Revving needle animation matching:
    // 0% -> -108 deg
    // 55% -> 96 deg
    // 72% -> 70 deg
    // 100% -> -108 deg
    _revController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _needleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -108, end: 96).chain(
          CurveTween(curve: const Cubic(0.5, 0.0, 0.2, 1.0)),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 96, end: 70).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 17,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 70, end: -108).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 28,
      ),
    ]).animate(_revController);

    // Status message cycling timer (every 1800ms)
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          _currentStatusIndex = (_currentStatusIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _revController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gauge Wrap with Radial Glow
        Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color.fromRGBO(240, 162, 2, 0.12),
                Color.fromRGBO(240, 162, 2, 0.0),
              ],
              stops: [0.0, 0.65],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Painter for Ticks & Needle
              AnimatedBuilder(
                animation: _needleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _RpmGaugePainter(
                      needleDegree: _needleAnimation.value,
                    ),
                  );
                },
              ),
              // RPM Label
              Positioned(
                bottom: widget.size * 0.18,
                child: Text(
                  'RPM',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.size * 0.05,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: const Color(0xFF8B8A85),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Brand Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.build_rounded,
              size: 20,
              color: Color(0xFFF0A202),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEDEBE4),
                  letterSpacing: 0.2,
                ),
                children: [
                  TextSpan(text: widget.brandName),
                  const TextSpan(
                    text: ' · loading',
                    style: TextStyle(
                      color: Color(0xFF8B8A85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fading Status Message
        SizedBox(
          height: 22,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              _messages[_currentStatusIndex],
              key: ValueKey<int>(_currentStatusIndex),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8B8A85),
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );

    if (widget.fullScreen) {
      return Container(
        color: const Color(0xFF17181B),
        alignment: Alignment.center,
        child: content,
      );
    }

    return content;
  }
}

class _RpmGaugePainter extends CustomPainter {
  final double needleDegree;

  _RpmGaugePainter({required this.needleDegree});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Major Ticks (sweep from -120deg to 120deg, 13 ticks)
    final majorTickAngles = [
      -120.0, -100.0, -80.0, -60.0, -40.0, -20.0, 0.0, 20.0, 40.0, 60.0, 80.0, 100.0, 120.0
    ];

    // Minor Ticks
    final minorTickAngles = [
      -110.0, -90.0, -70.0, -50.0, -30.0, -10.0, 10.0, 30.0, 50.0, 70.0, 90.0, 110.0
    ];

    final tickPaint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw Major Ticks
    for (final angle in majorTickAngles) {
      final isRedline = angle >= 80.0;
      tickPaint.color = isRedline ? const Color(0xFFD9502D) : const Color(0xFF6B6A66);

      final rad = angle * math.pi / 180;
      final startR = radius * 0.66;
      final endR = radius * 0.80;

      final p1 = Offset(
        center.dx + startR * math.sin(rad),
        center.dy - startR * math.cos(rad),
      );
      final p2 = Offset(
        center.dx + endR * math.sin(rad),
        center.dy - endR * math.cos(rad),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }

    // Draw Minor Ticks
    tickPaint.color = const Color(0xFF3A3B3E).withValues(alpha: 0.6);
    tickPaint.strokeWidth = 2.0;

    for (final angle in minorTickAngles) {
      final rad = angle * math.pi / 180;
      final startR = radius * 0.70;
      final endR = radius * 0.76;

      final p1 = Offset(
        center.dx + startR * math.sin(rad),
        center.dy - startR * math.cos(rad),
      );
      final p2 = Offset(
        center.dx + endR * math.sin(rad),
        center.dy - endR * math.cos(rad),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }

    // Draw Needle
    final needleRad = needleDegree * math.pi / 180;
    final needleStartR = radius * 0.05;
    final needleEndR = radius * 0.62;

    final needlePaint = Paint()
      ..color = const Color(0xFFF0A202)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final np1 = Offset(
      center.dx + needleStartR * math.sin(needleRad),
      center.dy - needleStartR * math.cos(needleRad),
    );
    final np2 = Offset(
      center.dx + needleEndR * math.sin(needleRad),
      center.dy - needleEndR * math.cos(needleRad),
    );

    canvas.drawLine(np1, np2, needlePaint);

    // Draw Outer Hub Ring
    final hubRingPaint = Paint()
      ..color = const Color(0xFF7A560A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius * 0.12, hubRingPaint);

    // Draw Inner Hub Fill
    final hubPaint = Paint()
      ..color = const Color(0xFFF0A202)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.06, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _RpmGaugePainter oldDelegate) {
    return oldDelegate.needleDegree != needleDegree;
  }
}
