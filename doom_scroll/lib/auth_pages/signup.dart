import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';
import '../core/router/app_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

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
    final password = _passwordController.text;

    // Basic validation
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    if (password.length < 8 || password.length > 72) {
      _showSnackBar('Password must be between 8 and 72 characters.');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      _showSnackBar('Account created successfully! Please sign in.', isError: false);

      // Navigate to sign-in page (not home) after successful registration
      context.go(AppRoutes.signIn);
    } else {
      _showSnackBar(result.error ?? 'Registration failed.');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF3B5C) : const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// FULL SCREEN BACKGROUND IMAGE — visible, not heavily dimmed
          SizedBox.expand(
            child: Image.asset("assets/bg.png", fit: BoxFit.cover),
          ),

          /// SUBTLE GRADIENT OVERLAY — keeps image visible
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000), // 40% black at top
                  Color(0xCC000000), // 80% black at bottom
                ],
              ),
            ),
          ),

          /// CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 100,
              ),
              child: ListView(
                children: [
                  /// HERO TITLE
                  const Center(
                    child: Text(
                      "Join the\nFuture of Focus",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Center(
                    child: Text(
                      "Your future self is protecting you. Step away from\nthe noise and reclaim your digital sovereignty.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA6ADAD),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// GLASS CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x26151D1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0x33FFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// USERNAME
                            const Text(
                              "Username",
                              style: TextStyle(
                                color: Color(0xFFA6ADAD),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _input(
                              hint: "your_handle",
                              icon: Icons.person_outline_rounded,
                              controller: _usernameController,
                            ),

                            const SizedBox(height: 20),

                            /// EMAIL
                            const Text(
                              "Email Address",
                              style: TextStyle(
                                color: Color(0xFFA6ADAD),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _input(
                              hint: "name@future.com",
                              icon: Icons.alternate_email_rounded,
                              controller: _emailController,
                            ),

                            const SizedBox(height: 20),

                            /// PASSWORD
                            const Text(
                              "Password",
                              style: TextStyle(
                                color: Color(0xFFA6ADAD),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _input(
                              hint: "••••••••",
                              icon: Icons.lock_outline_rounded,
                              obscure: true,
                              controller: _passwordController,
                            ),

                            const SizedBox(height: 28),

                            /// CREATE ACCOUNT BUTTON
                            GestureDetector(
                              onTap: _isLoading ? null : _handleSignup,
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isLoading
                                        ? [
                                            const Color(0xFF00F2FF).withOpacity(0.5),
                                            const Color(0xFF7000FF).withOpacity(0.5),
                                          ]
                                        : [
                                            const Color(0xFF00F2FF),
                                            const Color(0xFF7000FF),
                                          ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00F2FF,
                                      ).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          "CREATE ACCOUNT",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 2,
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

                  /// NAV TO SIGNIN
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.signIn),
                      child: const Text(
                        "Already have an account? Sign in",
                        style: TextStyle(
                          color: Color(0xFFA6ADAD),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
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
    bool obscure = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF666E6E), fontSize: 15),
            prefixIcon: Icon(icon, color: const Color(0xFF667070), size: 20),
            filled: true,
            fillColor: const Color(0x1A1D2424),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0x8000F2FF),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }
}
