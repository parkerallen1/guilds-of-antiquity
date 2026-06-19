import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom container that draws a blocky, beveled border reminiscent of retro RPGs.
class RetroPanel extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color outlineColor;
  final Color? highlightColor;
  final Color? shadowColor;
  final double borderWidth;
  final double bevelWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool inset;

  const RetroPanel({
    super.key,
    required this.child,
    this.backgroundColor,
    this.outlineColor = const Color(0xFF000000),
    this.highlightColor,
    this.shadowColor,
    this.borderWidth = 2.0,
    this.bevelWidth = 2.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.inset = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surface;
    
    // Determine highlight and shadow colors automatically if not provided
    final double luminance = bg.computeLuminance();
    final Color hl = highlightColor ?? (luminance > 0.5 
        ? Colors.white.withValues(alpha: 0.5) 
        : Colors.white.withValues(alpha: 0.25));
    final Color sd = shadowColor ?? (luminance > 0.5 
        ? Colors.black.withValues(alpha: 0.25) 
        : Colors.black.withValues(alpha: 0.6));

    // For inset borders, swap highlight and shadow
    final topColor = inset ? sd : hl;
    final leftColor = inset ? sd : hl;
    final bottomColor = inset ? hl : sd;
    final rightColor = inset ? hl : sd;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: outlineColor,
        border: Border.all(color: outlineColor, width: borderWidth),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(color: topColor, width: bevelWidth),
            left: BorderSide(color: leftColor, width: bevelWidth),
            bottom: BorderSide(color: bottomColor, width: bevelWidth),
            right: BorderSide(color: rightColor, width: bevelWidth),
          ),
        ),
        padding: padding ?? const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }
}

/// A blocky click-animated button in retro RPG style.
class RetroButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color outlineColor;
  final Color? highlightColor;
  final Color? shadowColor;
  final double borderWidth;
  final double bevelWidth;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const RetroButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.outlineColor = const Color(0xFF000000),
    this.highlightColor,
    this.shadowColor,
    this.borderWidth = 2.0,
    this.bevelWidth = 2.0,
    this.padding,
    this.enabled = true,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.enabled
        ? (widget.backgroundColor ?? theme.colorScheme.primary)
        : Colors.grey[700]!;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: Transform.translate(
        offset: _isPressed ? const Offset(1, 1) : Offset.zero,
        child: RetroPanel(
          inset: _isPressed,
          backgroundColor: bg,
          outlineColor: widget.outlineColor,
          highlightColor: widget.highlightColor,
          shadowColor: widget.shadowColor,
          borderWidth: widget.borderWidth,
          bevelWidth: widget.bevelWidth,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A blocky, segmented progress bar for retro status bars (HP/XP/timers).
class RetroProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color progressColor;
  final Color backgroundColor;
  final double height;
  final bool segmented;
  final int segments;

  const RetroProgressBar({
    super.key,
    required this.value,
    required this.progressColor,
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.height = 16.0,
    this.segmented = true,
    this.segments = 10,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Container(
        color: backgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final progressWidth = maxWidth * clampedValue;

            if (!segmented) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: progressWidth,
                  height: double.infinity,
                  color: progressColor,
                ),
              );
            }

            // Segmented rendering
            final double segmentWidth = maxWidth / segments;
            final filledSegments = (clampedValue * segments).floor();
            final double remainder = (clampedValue * segments) - filledSegments;

            return Row(
              children: List.generate(segments, (index) {
                Color segColor = Colors.transparent;
                if (index < filledSegments) {
                  segColor = progressColor;
                } else if (index == filledSegments && remainder > 0.0) {
                  segColor = progressColor.withValues(alpha: remainder);
                }

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < segments - 1 ? 1.0 : 0.0,
                    ),
                    color: segColor,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

/// A blocky pixel-style horizontal divider.
class RetroDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double thickness;

  const RetroDivider({
    super.key,
    this.color = Colors.black,
    this.height = 16,
    this.thickness = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: thickness,
          width: double.infinity,
          color: color,
        ),
      ),
    );
  }
}
