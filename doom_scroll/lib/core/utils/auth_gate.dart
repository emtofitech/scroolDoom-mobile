import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_controller.dart';
import '../../auth_pages/signin.dart';

class AuthGate {
  static void requireAuth(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onAuthedAction,
  }) {
    final auth = ref.read(authControllerProvider);

    if (auth.isAuthenticated) {
      onAuthedAction();
    } else {
      _showLoginPrompt(context);
    }
  }

  static void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 220,
          child: Column(
            children: [
              const Text(
                "Sign in required",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                "You need an account to perform this action.",
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SigninPage()),
                  );
                },
                child: const Text("Sign In"),
              ),
            ],
          ),
        );
      },
    );
  }
}
