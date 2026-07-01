import 'dart:math';
import 'package:flutter/material.dart';

class Checkpoint {
  final String label;
  final String sub;
  final bool done;
  final bool active;

  const Checkpoint({
    required this.label,
    required this.sub,
    this.done = false,
    this.active = false,
  });
}

class CheckpointTrail extends StatelessWidget {
  final List<Checkpoint> checkpoints;

  const CheckpointTrail({super.key, required this.checkpoints});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(checkpoints.length * 2 - 1, (i) {
          if (i.isOdd) {
            final prev = checkpoints[i ~/ 2];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: CustomPaint(
                  size: const Size(double.infinity, 2),
                  painter: _DottedLinePainter(
                    color: prev.done
                        ? const Color(0xFF2F6F62).withValues(alpha: 0.75)
                        : const Color(0xFF3A4750),
                  ),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final cp = checkpoints[idx];
          return _CheckpointStamp(checkpoint: cp);
        }),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashGap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 1),
        Offset((x + dashWidth).clamp(0, size.width), 1),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CheckpointStamp extends StatefulWidget {
  final Checkpoint checkpoint;
  const _CheckpointStamp({required this.checkpoint});

  @override
  State<_CheckpointStamp> createState() => _CheckpointStampState();
}

class _CheckpointStampState extends State<_CheckpointStamp>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    if (widget.checkpoint.active) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
      _pulseAnim = Tween<double>(begin: 0.85, end: 1.35).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeOut),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _CheckpointStamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checkpoint.active && _pulseController == null) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
      _pulseAnim = Tween<double>(begin: 0.85, end: 1.35).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeOut),
      );
    }
    if (!widget.checkpoint.active && _pulseController != null) {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnim = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = widget.checkpoint;

    Widget stamp;
    if (cp.active) {
      stamp = AnimatedBuilder(
        animation: _pulseAnim!,
        builder: (context, child) {
          final scale = _pulseAnim!.value;
          return SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2F6F62).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF131A20),
                    border: Border.all(color: const Color(0xFF2F6F62), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2F6F62),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else if (cp.done) {
      stamp = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF131A20),
          border: Border.all(color: const Color(0xFF2F6F62), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1E2F6F62),
              blurRadius: 0,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -4 * pi / 180,
          child: const Icon(Icons.check, size: 18, color: Color(0xFF2F6F62)),
        ),
      );
    } else {
      stamp = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF333F48),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF414F59), width: 2),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          stamp,
          const SizedBox(height: 8),
            Text(
            cp.label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              letterSpacing: 0.08,
              color: cp.done || cp.active
                  ? const Color(0xFFD7DED2)
                  : const Color(0xFF7C8892),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cp.sub,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10,
              color: cp.done || cp.active
                  ? const Color(0xFF2F6F62)
                  : const Color(0xFF54626B),
            ),
          ),
        ],
      ),
    );
  }
}
