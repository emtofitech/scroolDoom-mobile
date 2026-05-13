import 'package:flutter/material.dart';
import 'package:doom_scroll/widgets/bottom_nav.dart';
import '../core/theme/colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,

      // bottomNavigationBar: const AppBottomNav(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 10),

              /// APP BAR
              Row(
                children: [
                  Image.asset("assets/doomlogo.png", height: 58, width: 58),
                  const SizedBox(width: 10),
                  const Text(
                    "DoomScroll",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// HERO TITLE
              const Text(
                "Take Back Control\nof Your Screen Time",
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Set limits, build discipline, and reclaim your focus from addictive apps.",
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),

              const SizedBox(height: 20),

              /// GET STARTED BUTTON
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    "Get Started",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// SIGN IN / SIGN UP
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Sign In",
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Sign Up",
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// RECLAIM FOCUS CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.flash_on, color: AppColors.cyan, size: 28),
                    SizedBox(height: 10),
                    Text(
                      "Reclaim Your Focus",
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "The average user saves 4.2 hours per week by implementing these tactical boundaries. Your mental clarity is the ultimate prize.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// SECTION TITLE
              const Text(
                "Monitor Your App Usage Like This",
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              /// SOCIAL CARDS
              const AppLimitCard(
                name: "Instagram",
                timeUsed: "1h 20m today",
                limit: "45m",
                status: "High Risk",
                color: AppColors.cyan,
                sliderValue: 0.7,
              ),

              const AppLimitCard(
                name: "TikTok",
                timeUsed: "Used 3h 40m today",
                limit: "20m",
                status: "Critical",
                color: AppColors.red,
                sliderValue: 0.4,
              ),

              const AppLimitCard(
                name: "Twitter",
                timeUsed: "Used 45m today",
                limit: "1h 30m",
                status: "Moderate",
                color: AppColors.purple,
                sliderValue: 0.6,
              ),

              const AppLimitCard(
                name: "YouTube",
                timeUsed: "Used 1h 10m today",
                limit: "2h",
                status: "Moderate",
                color: AppColors.cyan,
                sliderValue: 0.8,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// REUSABLE CARD
class AppLimitCard extends StatelessWidget {
  final String name;
  final String timeUsed;
  final String limit;
  final String status;
  final Color color;
  final double sliderValue;

  const AppLimitCard({
    super.key,
    required this.name,
    required this.timeUsed,
    required this.limit,
    required this.status,
    required this.color,
    required this.sliderValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeUsed,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            "Limit: $limit",
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: sliderValue,
              backgroundColor: AppColors.bg,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
