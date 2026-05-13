import 'dart:ui';
import 'package:flutter/material.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// FULL SCREEN BACKGROUND IMAGE — visible, not heavily dimmed
          SizedBox.expand(
            child: Image.asset("assets/bg.png", fit: BoxFit.cover),
          ),

          /// SUBTLE DARK OVERLAY — keep image visible like the screenshot
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
                  // const SizedBox(height: 62),

                  /// HERO TITLE
                  const Center(
                    child: Text(
                      "Welcome\nBack",
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
                      "Continue your journey toward\ndigital focus and clarity.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA6ADAD),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// GLASS CARD — matching DoomScroll signup card style
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
                            /// EMAIL FIELD
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
                            ),

                            const SizedBox(height: 20),

                            /// PASSWORD FIELD
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
                            ),

                            const SizedBox(height: 10),

                            /// FORGOT PASSWORD
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: const Color(
                                    0xFF00F2FF,
                                  ).withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            /// SIGN IN BUTTON — cyan-to-purple gradient
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00F2FF),
                                    Color(0xFF7000FF),
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
                              child: const Center(
                                child: Text(
                                  "SIGN IN",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 2,
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

                  /// NAV TO SIGNUP
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Don't have an account? Create one",
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
    bool obscure = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
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
