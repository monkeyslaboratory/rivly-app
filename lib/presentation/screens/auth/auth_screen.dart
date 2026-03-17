import 'dart:ui';
import 'dart:math' as math;

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
import 'login_screen.dart';

/// Auth screen with login/register toggle.
/// Uses a single animation controller for the entire transition:
///   0.0 = login visible
///   0.5 = crossover (both faded, logo bounced)
///   1.0 = register visible
class AuthScreen extends StatefulWidget {
  final bool isRegister;
  const AuthScreen({super.key, this.isRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late bool _showRegister;

  // Fields
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginObscure = true;

  final _regFormKey = GlobalKey<FormState>();
  final _regEmail = TextEditingController();
  final _regUsername = TextEditingController();
  final _regPassword = TextEditingController();
  bool _regObscure = true;

  @override
  void initState() {
    super.initState();
    _showRegister = widget.isRegister;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: _showRegister ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(AuthScreen old) {
    super.didUpdateWidget(old);
    if (old.isRegister != widget.isRegister) _toggle();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _loginEmail.dispose(); _loginPassword.dispose();
    _regEmail.dispose(); _regUsername.dispose(); _regPassword.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_ctrl.isAnimating) return;
    _showRegister = !_showRegister;
    if (_showRegister) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _handleLogin() {
    if (_loginFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(email: _loginEmail.text.trim(), password: _loginPassword.text);
    }
  }

  void _handleRegister() {
    if (_regFormKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().register(email: _regEmail.text.trim(), username: _regUsername.text.trim(), password: _regPassword.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final cardWidth = w > 520 ? 464.0 : w - 48;

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) context.go('/dashboard');
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
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
                  child: ClipRRect(
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
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) {
                            final t = _ctrl.value;
                            final logoScale = 1.0 + 0.08 * math.sin(t * math.pi);

                            // Login: visible at 0.0, fades 0.0→0.5
                            final loginOpacity = (t <= 0.5) ? 1.0 - (t * 2.0) : 0.0;
                            // Register: fades in 0.5→1.0
                            final regOpacity = (t >= 0.5) ? (t - 0.5) * 2.0 : 0.0;
                            final loginSlide = (1.0 - loginOpacity) * -12.0;
                            final regSlide = (1.0 - regOpacity) * 12.0;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Transform.scale(
                                    scale: logoScale,
                                    child: const RivlyLogo(size: 36, showText: false, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Measure both forms, interpolate height
                                _HeightCrossfade(
                                  progress: t,
                                  loginChild: _loginForm(l, isLoading),
                                  registerChild: _registerForm(l, isLoading),
                                  loginOpacity: loginOpacity,
                                  regOpacity: regOpacity,
                                  loginSlide: loginSlide,
                                  regSlide: regSlide,
                                ),
                              ],
                            );
                          },
                        ),
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

  Widget _loginForm(AppLocalizations l, bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.signIn, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, letterSpacing: -0.3, color: Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(l.competitiveIntelligence, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13, letterSpacing: -0.1, color: Colors.black.withValues(alpha: 0.4)), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          FrostedInput(controller: _loginEmail, hintText: l.email, validator: Validators.email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          FrostedInput(
            controller: _loginPassword, hintText: l.password, validator: Validators.password,
            obscureText: _loginObscure, textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            suffixIcon: GestureDetector(onTap: () => setState(() => _loginObscure = !_loginObscure),
              child: Icon(_loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black.withValues(alpha: 0.3))),
          ),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: HoverLink(text: l.forgotPassword, color: const Color(0xFF3044FA), onTap: () {})),
          const SizedBox(height: 24),
          ScaleButton(onPressed: isLoading ? null : _handleLogin, child: _PrimaryBtn(label: l.signIn, isLoading: isLoading)),
          const SizedBox(height: 12),
          ScaleButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.googleSignInComingSoon))),
            child: _GoogleBtn(label: l.continueWithGoogle),
          ),
          const SizedBox(height: 24),
          _BottomLink(prefix: '${l.dontHaveAccount} ', linkText: l.signUp, onTap: _toggle),
        ],
      ),
    );
  }

  Widget _registerForm(AppLocalizations l, bool isLoading) {
    return Form(
      key: _regFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.signUp, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, letterSpacing: -0.3, color: Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(l.createYourAccount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13, letterSpacing: -0.1, color: Colors.black.withValues(alpha: 0.4)), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          FrostedInput(controller: _regEmail, hintText: l.email, validator: Validators.email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          FrostedInput(controller: _regUsername, hintText: l.username, validator: Validators.username, textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          FrostedInput(
            controller: _regPassword, hintText: l.password, validator: Validators.password,
            obscureText: _regObscure, textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            suffixIcon: GestureDetector(onTap: () => setState(() => _regObscure = !_regObscure),
              child: Icon(_regObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black.withValues(alpha: 0.3))),
          ),
          const SizedBox(height: 28),
          ScaleButton(onPressed: isLoading ? null : _handleRegister, child: _PrimaryBtn(label: l.createAccount, isLoading: isLoading)),
          const SizedBox(height: 24),
          _BottomLink(prefix: '${l.alreadyHaveAccount} ', linkText: l.signIn, onTap: _toggle),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Height-interpolating crossfade: measures both children, lerps height
// ---------------------------------------------------------------------------

class _HeightCrossfade extends StatefulWidget {
  final double progress; // 0 = login, 1 = register
  final Widget loginChild, registerChild;
  final double loginOpacity, regOpacity, loginSlide, regSlide;

  const _HeightCrossfade({
    required this.progress,
    required this.loginChild,
    required this.registerChild,
    required this.loginOpacity,
    required this.regOpacity,
    required this.loginSlide,
    required this.regSlide,
  });

  @override
  State<_HeightCrossfade> createState() => _HeightCrossfadeState();
}

class _HeightCrossfadeState extends State<_HeightCrossfade> {
  final _loginKey = GlobalKey();
  final _regKey = GlobalKey();
  double? _loginHeight;
  double? _regHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_HeightCrossfade old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final lBox = _loginKey.currentContext?.findRenderObject() as RenderBox?;
    final rBox = _regKey.currentContext?.findRenderObject() as RenderBox?;
    final lh = lBox?.size.height;
    final rh = rBox?.size.height;
    if (lh != _loginHeight || rh != _regHeight) {
      setState(() {
        if (lh != null) _loginHeight = lh;
        if (rh != null) _regHeight = rh;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lh = _loginHeight ?? 400;
    final rh = _regHeight ?? 450;
    final height = lh + (rh - lh) * widget.progress;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Login — measure offscreen, show with opacity
          Positioned(
            left: 0, right: 0, top: 0,
            child: KeyedSubtree(
              key: _loginKey,
              child: Opacity(
                opacity: widget.loginOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, widget.loginSlide),
                  child: widget.loginChild,
                ),
              ),
            ),
          ),
          // Register
          Positioned(
            left: 0, right: 0, top: 0,
            child: KeyedSubtree(
              key: _regKey,
              child: Opacity(
                opacity: widget.regOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, widget.regSlide),
                  child: widget.registerChild,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool isLoading;
  const _PrimaryBtn({required this.label, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: isLoading ? Colors.black.withValues(alpha: 0.5) : Colors.black, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
          : Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 24 / 16, letterSpacing: -0.16, color: Colors.white)),
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  final String label;
  const _GoogleBtn({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 0.5)),
      alignment: Alignment.center,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const GoogleLogo(size: 18), const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.14, color: Colors.black.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class _BottomLink extends StatelessWidget {
  final String prefix, linkText;
  final VoidCallback onTap;
  const _BottomLink({required this.prefix, required this.linkText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(prefix, style: GoogleFonts.inter(fontSize: 14, color: Colors.black.withValues(alpha: 0.4))),
      HoverLink(text: linkText, color: const Color(0xFF3044FA), fontWeight: FontWeight.w500, onTap: onTap),
    ]);
  }
}
