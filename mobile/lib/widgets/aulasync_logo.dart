import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wordmark tipográfico oficial de AulaSync con punto de sincronización IoT
/// y onda expansiva concéntrica opcional ([animate]).
class AulaSyncWordmark extends StatefulWidget {
  final double fontSize;
  final bool darkBackground;
  final bool animate;

  const AulaSyncWordmark({
    super.key,
    this.fontSize = 42,
    this.darkBackground = false,
    this.animate = false,
  });

  @override
  State<AulaSyncWordmark> createState() => _AulaSyncWordmarkState();
}

class _AulaSyncWordmarkState extends State<AulaSyncWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _wordOpacity;
  late final Animation<double> _wordOffset;
  late final Animation<double> _dotScale;
  late final Animation<double> _rippleScale;
  late final Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _wordOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    _wordOffset = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _dotScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.38), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.38, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.62, curve: Curves.easeOut),
      ),
    );

    _rippleScale = Tween<double>(begin: 0.8, end: 3.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.95, curve: Curves.easeOut),
      ),
    );
    _rippleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 85),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.95, curve: Curves.easeOut),
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aulaColor = widget.darkBackground ? Colors.white : AppColors.navy;
    final syncColor =
        widget.darkBackground ? const Color(0xFF5EEAD4) : AppColors.teal;
    final dotColor =
        widget.darkBackground ? const Color(0xFF34D399) : AppColors.success;
    final dotSize = (widget.fontSize * 0.18).clamp(5.0, 10.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: widget.animate ? _wordOpacity.value : 1.0,
          child: Transform.translate(
            offset: Offset(0, widget.animate ? _wordOffset.value : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      letterSpacing: -(widget.fontSize * 0.045),
                      height: 1.05,
                    ),
                    children: [
                      TextSpan(
                        text: 'Aula',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: aulaColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Sync',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: syncColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: widget.fontSize * 0.16),
                  child: SizedBox(
                    width: dotSize + 4,
                    height: dotSize + 4,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (widget.animate && _rippleOpacity.value > 0.01)
                          Transform.scale(
                            scale: _rippleScale.value,
                            child: Opacity(
                              opacity: _rippleOpacity.value,
                              child: Container(
                                width: dotSize + 2,
                                height: dotSize + 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: dotColor,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Transform.scale(
                          scale: widget.animate ? _dotScale.value : 1.0,
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
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
}
