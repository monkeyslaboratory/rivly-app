import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/common/rivly_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              const Positioned.fill(child: AuthBackground()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _glassCard(
                    context,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: RivlyLogo(size: 36, showText: false, color: Colors.black)),
                          const SizedBox(height: 20),
                          Text(l.signIn,
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, letterSpacing: -0.3, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(l.competitiveIntelligence,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13, letterSpacing: -0.1, color: Colors.black.withValues(alpha: 0.4)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          FrostedInput(controller: _emailController, hintText: l.email, validator: Validators.email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
                          const SizedBox(height: 16),
                          FrostedInput(
                            controller: _passwordController, hintText: l.password, validator: Validators.password,
                            obscureText: _obscurePassword, textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black.withValues(alpha: 0.3)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: HoverLink(text: l.forgotPassword, color: const Color(0xFF3044FA), onTap: () {}),
                          ),
                          const SizedBox(height: 24),
                          ScaleButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isLoading ? Colors.black.withValues(alpha: 0.5) : Colors.black,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                  : Text(l.signIn, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 24 / 16, letterSpacing: -0.16, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ScaleButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.googleSignInComingSoon)));
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleLogo(size: 18),
                                  const SizedBox(width: 10),
                                  Text(l.continueWithGoogle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.14, color: Colors.black.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${l.dontHaveAccount} ', style: GoogleFonts.inter(fontSize: 14, color: Colors.black.withValues(alpha: 0.4))),
                              HoverLink(text: l.signUp, color: const Color(0xFF3044FA), fontWeight: FontWeight.w500, onTap: () => context.go('/register')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass card
// ---------------------------------------------------------------------------

Widget _glassCard(BuildContext context, {required Widget child}) {
  final w = MediaQuery.sizeOf(context).width;
  final cardWidth = w > 520 ? 464.0 : w - 48;
  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
        ),
        child: child,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// iOS-style scale button
// ---------------------------------------------------------------------------

class ScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const ScaleButton({super.key, required this.onPressed, required this.child});

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
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() { _hovered = false; _pressed = false; }),
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

// ---------------------------------------------------------------------------
// Hover link with underline
// ---------------------------------------------------------------------------

class HoverLink extends StatefulWidget {
  final String text;
  final Color color;
  final FontWeight fontWeight;
  final VoidCallback onTap;
  const HoverLink({super.key, required this.text, required this.color, required this.onTap, this.fontWeight = FontWeight.w400});

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
          child: Text(widget.text, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: widget.fontWeight, letterSpacing: -0.14, color: widget.color,
            decoration: _hovered ? TextDecoration.underline : TextDecoration.none, decorationColor: widget.color,
          )),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Frosted input — bold on focus
// ---------------------------------------------------------------------------

class FrostedInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const FrostedInput({
    super.key, required this.controller, required this.hintText,
    this.validator, this.keyboardType, this.textInputAction,
    this.obscureText = false, this.onFieldSubmitted, this.suffixIcon,
  });

  @override
  State<FrostedInput> createState() => _FrostedInputState();
}

class _FrostedInputState extends State<FrostedInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        onFieldSubmitted: widget.onFieldSubmitted,
        cursorColor: Colors.black,
        cursorWidth: 1.5,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: _focused ? FontWeight.w600 : FontWeight.w400,
          height: 24 / 14,
          letterSpacing: -0.14,
          color: Colors.black.withValues(alpha: 0.85),
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 24 / 14, letterSpacing: -0.14, color: Colors.black.withValues(alpha: 0.3)),
          suffixIcon: widget.suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 12), child: widget.suffixIcon) : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12), width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 1)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 0.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google "G" logo (official 4-color)
// ---------------------------------------------------------------------------

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleLogoPainter()));
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.drawPath(Path()..moveTo(23.49*s,12.27*s)..cubicTo(23.49*s,11.48*s,23.42*s,10.73*s,23.28*s,10*s)..lineTo(12*s,10*s)..lineTo(12*s,14.51*s)..lineTo(18.47*s,14.51*s)..cubicTo(18.18*s,15.99*s,17.34*s,17.25*s,16.08*s,18.1*s)..lineTo(16.08*s,21.09*s)..lineTo(19.93*s,21.09*s)..cubicTo(22.19*s,19*s,23.49*s,15.92*s,23.49*s,12.27*s)..close(), Paint()..color=const Color(0xFF4285F4));
    canvas.drawPath(Path()..moveTo(12*s,24*s)..cubicTo(15.24*s,24*s,17.95*s,22.92*s,19.93*s,21.09*s)..lineTo(16.08*s,18.1*s)..cubicTo(15*s,18.82*s,13.62*s,19.25*s,12*s,19.25*s)..cubicTo(8.87*s,19.25*s,6.22*s,17.14*s,5.28*s,14.29*s)..lineTo(1.29*s,14.29*s)..lineTo(1.29*s,17.38*s)..cubicTo(3.26*s,21.3*s,7.31*s,24*s,12*s,24*s)..close(), Paint()..color=const Color(0xFF34A853));
    canvas.drawPath(Path()..moveTo(5.28*s,14.29*s)..cubicTo(4.78*s,12.81*s,4.78*s,11.19*s,5.28*s,9.71*s)..lineTo(5.28*s,6.62*s)..lineTo(1.29*s,6.62*s)..cubicTo(-0.43*s,10.1*s,-0.43*s,13.9*s,1.29*s,17.38*s)..lineTo(5.28*s,14.29*s)..close(), Paint()..color=const Color(0xFFFBBC05));
    canvas.drawPath(Path()..moveTo(12*s,4.75*s)..cubicTo(13.77*s,4.75*s,15.35*s,5.36*s,16.6*s,6.55*s)..lineTo(19.96*s,3.19*s)..cubicTo(17.95*s,1.19*s,15.24*s,0,12*s,0)..cubicTo(7.31*s,0,3.26*s,2.7*s,1.29*s,6.62*s)..lineTo(5.28*s,9.71*s)..cubicTo(6.22*s,6.86*s,8.87*s,4.75*s,12*s,4.75*s)..close(), Paint()..color=const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
