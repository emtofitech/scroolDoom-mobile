import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/services/usage_service.dart';
import '../core/router/app_router.dart';

/// Full-screen page shown when required permissions are missing.
/// Prompts the user to grant Usage Access and Display over other apps via system settings.
class PermissionDeniedPage extends StatefulWidget {
  final bool showBackButton;

  const PermissionDeniedPage({super.key, this.showBackButton = true});

  @override
  State<PermissionDeniedPage> createState() => _PermissionDeniedPageState();
}

class _PermissionDeniedPageState extends State<PermissionDeniedPage> {
  bool _checking = false;
  bool _hasUsage = false;
  bool _hasOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _checking = true);
    final usage = await UsageService.hasUsagePermission();
    final overlay = await UsageService.hasOverlayPermission();
    setState(() {
      _hasUsage = usage;
      _hasOverlay = overlay;
      _checking = false;
    });

    if (usage && overlay) {
      if (widget.showBackButton) {
        if (mounted) context.pop();
      } else {
        if (mounted) context.go(AppRoutes.home);
      }
    }
  }

  Future<void> _checkAgain() async {
    await _checkPermissions();
    if (!mounted) return;

    if (!_hasUsage || !_hasOverlay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions not fully granted yet. Please enable them in Settings.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: AppColors.red, size: 44),
              ),
              const SizedBox(height: 28),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DoomScroll needs specific permissions to track your '
                'app usage and block apps when you exceed your limits.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Usage Permission Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: Icon(_hasUsage ? Icons.check_circle : Icons.settings, size: 20),
                  label: Text('Usage Access',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: _hasUsage ? TextDecoration.lineThrough : null)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasUsage ? AppColors.surface : AppColors.cyan,
                    foregroundColor: _hasUsage ? AppColors.muted : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _hasUsage ? null : UsageService.openUsageSettings,
                ),
              ),
              const SizedBox(height: 14),

              // Overlay Permission Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: Icon(_hasOverlay ? Icons.check_circle : Icons.layers, size: 20),
                  label: Text('Display over other apps',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: _hasOverlay ? TextDecoration.lineThrough : null)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasOverlay ? AppColors.surface : AppColors.cyan,
                    foregroundColor: _hasOverlay ? AppColors.muted : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _hasOverlay ? null : UsageService.openOverlaySettings,
                ),
              ),
              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cyan,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  label: Text(_checking ? 'Checking...' : 'Check Again',
                      style: const TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: const BorderSide(color: AppColors.cyan, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _checking ? null : _checkAgain,
                ),
              ),
              const SizedBox(height: 24),
              if (widget.showBackButton)
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppColors.muted.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
