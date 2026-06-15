import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/partner_models.dart';
import '../core/state/partner_controller.dart';
import '../core/state/partner_state.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';

const _green = Color(0xFF00E676);

class AccountabilityPage extends ConsumerStatefulWidget {
  const AccountabilityPage({super.key});

  @override
  ConsumerState<AccountabilityPage> createState() => _AccountabilityPageState();
}

class _AccountabilityPageState extends ConsumerState<AccountabilityPage>
    with WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();

  bool _notifyMe = true;
  bool _notifyPartner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnerControllerProvider.notifier).loadPartnership();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(partnerControllerProvider.notifier).loadPartnership();
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _showSnackBar('Invite code copied to clipboard!', _green);
  }

  void _shareCode(String code) {
    Share.share(
      'Join me on DoomScroll as my accountability partner! Use my invite code: $code',
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _generateInvite() async {
    final controller = ref.read(partnerControllerProvider.notifier);
    final success = await controller.generateInvite();
    if (!success) {
      final error =
          ref.read(partnerControllerProvider).error ??
          'Failed to generate invite';
      _showSnackBar(error, AppColors.red);
    }
  }

  Future<void> _acceptInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Please enter a valid invite code', AppColors.red);
      return;
    }

    final controller = ref.read(partnerControllerProvider.notifier);
    final success = await controller.acceptInvite(code);
    if (success) {
      _codeController.clear();
      _showSnackBar('Successfully connected to partner!', _green);
    } else {
      final error =
          ref.read(partnerControllerProvider).error ?? 'Failed to connect';
      _showSnackBar(error, AppColors.red);
    }
  }

  Future<void> _refresh() async {
    await ref.read(partnerControllerProvider.notifier).loadPartnership();
  }

  Future<void> _dissolvePartnership() async {
    final controller = ref.read(partnerControllerProvider.notifier);
    final success = await controller.dissolvePartnership();
    if (success) {
      _showSnackBar('Partnership dissolved successfully', AppColors.red);
    } else {
      _showSnackBar(
        'Failed to dissolve partnership. Try again.',
        AppColors.red,
      );
    }
  }

  Future<void> _regenerateInvite() async {
    final controller = ref.read(partnerControllerProvider.notifier);
    final dissolved = await controller.dissolvePartnership();
    if (!dissolved) {
      final error =
          ref.read(partnerControllerProvider).error ?? 'Failed to regenerate';
      _showSnackBar(error, AppColors.red);
      return;
    }
    final success = await controller.generateInvite();
    if (success) {
    } else {
      final error =
          ref.read(partnerControllerProvider).error ?? 'Failed to regenerate';
      _showSnackBar(error, AppColors.red);
    }
  }

  void _showRegenerateConfirmSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.cyan,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Generate New Code?',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your current invite code will be invalidated and a new one will be generated. Your partner will need the new code to connect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _regenerateInvite();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Yes, Generate New Code',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDissolveConfirmSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.heart_broken_rounded,
                  color: AppColors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dissolve Partnership?',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to dissolve your accountability partnership? You will no longer receive notifications on their limit breaches, and your focus progress will not be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _dissolvePartnership();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Yes, Dissolve Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerState = ref.watch(partnerControllerProvider);
    final partnership = partnerState.partnership;
    final isConnected = partnership?.isActive == true;
    final isPending = partnerState.isPending;

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.cyan,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield, color: AppColors.cyan, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'DoomScroll',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: AppColors.cyan,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Accountability',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share boundaries and conquer doomscrolling together.\nReceive instant push notifications when your partner breaches limits.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (partnerState.isLoading && partnership == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  ),
                )
              else if (isConnected)
                _buildConnectedUI(partnership!)
              else if (isPending)
                _buildPendingUI(partnerState)
              else
                _buildDisconnectedUI(partnerState),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingUI(PartnerState state) {
    final code = state.partnership!.inviteCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.cyan,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Waiting for Partner',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your invite code with your accountability partner. The page will update automatically once they connect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'YOUR INVITE CODE',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share this code with your partner:',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          code,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyToClipboard(code),
                    icon: const Icon(Icons.copy_rounded, color: AppColors.cyan),
                    tooltip: 'Copy Code',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _shareCode(code),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_rounded,
                          color: AppColors.cyan,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SHARE INVITE CODE',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'LINK PARTNER CODE',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter partner\'s invite code below:',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. XK4M9P',
                  hintStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.cyan,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: state.isLoading ? null : _acceptInvite,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'CONNECT PARTNER',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectedUI(PartnerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.cyan,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find an Accountability Partner',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Research shows users are 3x more likely to stick to screen limits when they connect with a supportive partner. Exchange invite codes to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'YOUR INVITE CODE',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: state.isGenerating ? null : _generateInvite,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share this code with your partner:',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap here to generate invite code',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (state.isGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cyan,
                    ),
                  )
                else
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.cyan,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: state.isLoading ? null : _showRegenerateConfirmSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'GENERATE NEW CODE',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'LINK PARTNER CODE',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter partner\'s invite code below:',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. XK4M9P',
                  hintStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.cyan,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: state.isLoading ? null : _acceptInvite,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'CONNECT PARTNER',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedUI(Partnership partnership) {
    final partner = partnership.partner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _green.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.cyan,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner?.displayName ??
                              partner?.username ??
                              'Partner',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (partner != null && partner.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            partner.email ?? '',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _green.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Linked',
                          style: TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.outline),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notify me on partner breach',
                    style: TextStyle(color: AppColors.text, fontSize: 13.5),
                  ),
                  Switch(
                    value: _notifyMe,
                    onChanged: (v) => setState(() => _notifyMe = v),
                    activeColor: AppColors.cyan,
                    activeTrackColor: AppColors.cyan.withOpacity(0.3),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notify partner on my breach',
                    style: TextStyle(color: AppColors.text, fontSize: 13.5),
                  ),
                  Switch(
                    value: _notifyPartner,
                    onChanged: (v) => setState(() => _notifyPartner = v),
                    activeColor: AppColors.cyan,
                    activeTrackColor: AppColors.cyan.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'PARTNERSHIP INFO',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              _infoRow(
                'Partner',
                partner?.displayName ?? partner?.username ?? 'Partner',
              ),
              const SizedBox(height: 8),
              _infoRow('Code', partnership.inviteCode),
              const SizedBox(height: 8),
              _infoRow(
                'Since',
                _formatDate(partnership.acceptedAt ?? partnership.createdAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _showDissolveConfirmSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.red.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(14),
              color: AppColors.red.withOpacity(0.04),
            ),
            child: const Center(
              child: Text(
                'DISSOLVE PARTNERSHIP',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
