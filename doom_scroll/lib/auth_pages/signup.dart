import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/state/auth_controller.dart';
import '../core/state/auth_state.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar("Enter valid email");
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters");
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .register(username: username, email: email, password: password);
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
      if (!next.isLoading && next.error == null) {
        _showSnackBar("Account created successfully", isError: false);

        context.go(AppRoutes.signIn);
      }

      if (next.error != null) {
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
                      "Join the\nFuture of Focus",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Center(
                    child: Text(
                      "Create your account",
                      style: TextStyle(color: Color(0xFFA6ADAD)),
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
                              "Username",
                              style: TextStyle(color: Color(0xFFA6ADAD)),
                            ),

                            const SizedBox(height: 8),

                            _input(
                              hint: "your_handle",
                              icon: Icons.person_outline,
                              controller: _usernameController,
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Email",
                              style: TextStyle(color: Color(0xFFA6ADAD)),
                            ),

                            const SizedBox(height: 8),

                            _input(
                              hint: "name@email.com",
                              icon: Icons.email_outlined,
                              controller: _emailController,
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Password",
                              style: TextStyle(color: Color(0xFFA6ADAD)),
                            ),

                            const SizedBox(height: 8),

                            _passwordInput(),

                            const SizedBox(height: 30),

                            GestureDetector(
                              onTap: authState.isLoading ? null : _handleSignup,
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
                                          "CREATE ACCOUNT",
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

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.go(AppRoutes.signIn);
                      },
                      child: const Text(
                        "Already have an account? Sign in",
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
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
