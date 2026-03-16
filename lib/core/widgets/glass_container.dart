import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: shadows,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (color ?? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.white)).withValues(alpha: opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ?? Border.all(
                color: (Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.white).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
