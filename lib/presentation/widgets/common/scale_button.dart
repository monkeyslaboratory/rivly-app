import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A button wrapper that applies scale-on-hover and scale-on-press effects.
///
/// Example:
/// ```dart
/// ScaleButton(
///   onPressed: () => print('tapped'),
///   child: Container(
///     padding: EdgeInsets.all(16),
///     child: Text('Click me'),
///   ),
/// )
/// ```
class ScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const ScaleButton(
      {super.key, required this.onPressed, required this.child});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _hovered = false;
  bool _pressed = false;

  double get _scale {
    if (_pressed) return 0.97;
    if (_hovered && widget.onPressed != null) return 1.02;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A text link that shows an underline on hover.
///
/// Example:
/// ```dart
/// HoverLink(
///   text: 'View all',
///   color: Colors.blue,
///   onTap: () => print('tapped'),
/// )
/// ```
class HoverLink extends StatefulWidget {
  final String text;
  final Color color;
  final FontWeight fontWeight;
  final VoidCallback onTap;
  const HoverLink({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
    this.fontWeight = FontWeight.w400,
  });

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            widget.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: widget.fontWeight,
              letterSpacing: -0.14,
              color: widget.color,
              decoration:
                  _hovered ? TextDecoration.underline : TextDecoration.none,
              decorationColor: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
