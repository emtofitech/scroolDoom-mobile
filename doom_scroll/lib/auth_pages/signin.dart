import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/state/auth_controller.dart';
import '../core/state/auth_state.dart';

class SigninPage extends ConsumerStatefulWidget {
  const SigninPage({super.key});

  @override
  ConsumerState<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<SigninPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    await ref.read(authControllerProvider.notifier).login(email, password);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF3B5C)
            : const Color(0xFF00E676),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          !next.isLoading &&
          next.error == null) {
        context.go(AppRoutes.home);
      }

      if (next.error != null && next.error != previous?.error) {
        _showSnackBar(next.error!);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          /// background
          SizedBox.expand(
            child: Image.asset("assets/bg.png", fit: BoxFit.cover),
          ),

          /// overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0xCC000000)],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 100,
              ),
              child: ListView(
                children: [
                  const Center(
                    child: Text(
                      "Welcome\nBack",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Center(
                    child: Text(
                      "Continue your journey toward\ndigital focus and clarity.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA6ADAD), fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 40),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x26151D1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Email Address",
                              style: TextStyle(
                                color: Color(0xFFA6ADAD),
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 8),

                            _input(
                              hint: "name@future.com",
                              icon: Icons.email_outlined,
                              controller: _emailController,
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Password",
                              style: TextStyle(
                                color: Color(0xFFA6ADAD),
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 8),

                            _passwordInput(),

                            const SizedBox(height: 28),

                            GestureDetector(
                              onTap: authState.isLoading ? null : _handleSignIn,
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: authState.isLoading
                                        ? [
                                            const Color(
                                              0xFF00F2FF,
                                            ).withOpacity(.5),
                                            const Color(
                                              0xFF7000FF,
                                            ).withOpacity(.5),
                                          ]
                                        : const [
                                            Color(0xFF00F2FF),
                                            Color(0xFF7000FF),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: authState.isLoading
                                      ? const CircularProgressIndicator()
                                      : const Text(
                                          "SIGN IN",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.go(AppRoutes.signUp);
                      },
                      child: const Text(
                        "Don't have an account? Create one",
                        style: TextStyle(color: Color(0xFFA6ADAD)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0x1A1D2424),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _passwordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "••••••••",
        filled: true,
        fillColor: const Color(0x1A1D2424),

        prefixIcon: const Icon(Icons.lock_outline),

        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
