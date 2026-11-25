import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Wordmark tipográfico oficial `AulaSync.` con fuente Sora y punto IoT esmeralda.
/// Replica el diseño aprobado en Figma (sin caja de ícono) y la coreografía
/// `TextStagger + SyncRipple` cuando `animate` es true.
class AulaSyncWordmark extends StatefulWidget {
  final double fontSize;
  final bool darkBackground;
  final bool animate;

  const AulaSyncWordmark({
    super.key,
    this.fontSize = 36,
    this.darkBackground = false,
    this.animate = false,
  });

  @override
  State<AulaSyncWordmark> createState() => _AulaSyncWordmarkState();
}

class _AulaSyncWordmarkState extends State<AulaSyncWordmark>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aulaColor = widget.darkBackground ? Colors.white : AppColors.navy;
    final syncColor =
        widget.darkBackground ? AppColors.tealSoft : AppColors.teal;
    final dotSize = widget.fontSize * 0.18;

    Widget buildWordmark(double ripple) {
      final dotPulse = widget.animate
          ? 1.0 + (0.14 * (1.0 - (ripple - 0.5).abs() * 2.0)).clamp(0.0, 0.14)
          : 1.0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Aula',
            style: GoogleFonts.sora(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -widget.fontSize * 0.045,
              color: aulaColor,
              height: 1.05,
            ),
          ),
          Text(
            'Sync',
            style: GoogleFonts.sora(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w400,
              letterSpacing: -widget.fontSize * 0.035,
              color: syncColor,
              height: 1.05,
            ),
          ),
          SizedBox(width: widget.fontSize * 0.06),
          Transform.scale(
            scale: dotPulse,
            child: SizedBox(
              width: dotSize * 2.4,
              height: dotSize * 2.4,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.animate) ...[
                    _RippleRing(
                      size: dotSize * (1.2 + ripple * 3.1),
                      opacity: (1.0 - ripple).clamp(0.0, 0.55),
                    ),
                    _RippleRing(
                      size: dotSize * (1.2 + ((ripple + 0.45) % 1.0) * 2.4),
                      opacity:
                          (1.0 - ((ripple + 0.45) % 1.0)).clamp(0.0, 0.35),
                    ),
                  ],
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.45),
                          blurRadius: dotSize * 1.1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_controller == null) {
      return buildWordmark(0.0);
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, _) => buildWordmark(_controller!.value),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final double size;
  final double opacity;

  const _RippleRing({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
