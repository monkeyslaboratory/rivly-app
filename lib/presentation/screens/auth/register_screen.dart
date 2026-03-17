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
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: RivlyLogo(size: 36, showText: false, color: Colors.black)),
                              const SizedBox(height: 20),
                              Text(l.signUp,
                                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, letterSpacing: -0.3, color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(l.createYourAccount,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13, letterSpacing: -0.1, color: Colors.black.withValues(alpha: 0.4)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),

                              FrostedInput(controller: _emailController, hintText: l.email, validator: Validators.email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
                              const SizedBox(height: 16),
                              FrostedInput(controller: _usernameController, hintText: l.username, validator: Validators.username, textInputAction: TextInputAction.next),
                              const SizedBox(height: 16),
                              FrostedInput(
                                controller: _passwordController, hintText: l.password, validator: Validators.password,
                                obscureText: _obscurePassword, textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleRegister(),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black.withValues(alpha: 0.3)),
                                ),
                              ),
                              const SizedBox(height: 28),

                              ScaleButton(
                                onPressed: isLoading ? null : _handleRegister,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isLoading ? Colors.black.withValues(alpha: 0.5) : Colors.black,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                      : Text(l.createAccount, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 24 / 16, letterSpacing: -0.16, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${l.alreadyHaveAccount} ', style: GoogleFonts.inter(fontSize: 14, color: Colors.black.withValues(alpha: 0.4))),
                                  HoverLink(text: l.signIn, color: const Color(0xFF3044FA), fontWeight: FontWeight.w500, onTap: () => context.go('/login')),
                                ],
                              ),
                            ],
                          ),
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
}
