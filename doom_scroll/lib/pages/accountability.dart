import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';

const _amber = Color(0xFFFFAA00);
const _green = Color(0xFF00E676);

class AccountabilityPage extends StatefulWidget {
  const AccountabilityPage({super.key});

  @override
  State<AccountabilityPage> createState() => _AccountabilityPageState();
}

class _AccountabilityPageState extends State<AccountabilityPage> {
  bool _isConnected = false;
  final String _generatedCode = 'DOOM-X8K9-M2W4';
  final TextEditingController _codeController = TextEditingController();

  // FCM Settings
  bool _notifyMe = true;
  bool _notifyPartner = true;

  // Mock Partner Breach Logs
  final List<_BreachLog> _partnerBreaches = [
    _BreachLog(
      appName: 'Instagram',
      appIcon: Icons.camera_alt_outlined,
      exceededMins: 14,
      timeString: 'Today, 10:24 AM',
      severityColor: _amber,
    ),
    _BreachLog(
      appName: 'TikTok',
      appIcon: Icons.music_note_outlined,
      exceededMins: 32,
      timeString: 'Yesterday, 11:15 PM',
      severityColor: AppColors.red,
    ),
    _BreachLog(
      appName: 'Twitter',
      appIcon: Icons.close_sharp,
      exceededMins: 8,
      timeString: 'Oct 22, 5:48 PM',
      severityColor: AppColors.purple,
    ),
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite code copied to clipboard! 📋'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _connectPartner() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid invite code'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isConnected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Successfully connected to partner! 👥✨'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
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
                  setState(() {
                    _isConnected = false;
                    _codeController.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Partnership dissolved successfully'),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          children: [
            const SizedBox(height: 14),

            /// TOP BAR
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

            _isConnected ? _buildConnectedUI() : _buildDisconnectedUI(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// SHIELD INFO CARD
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
                child: const Icon(Icons.security_rounded, color: AppColors.cyan, size: 28),
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
                style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
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

        /// GENERATE/SHARE CODE BOX
        Container(
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
                    Text(
                      _generatedCode,
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
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded, color: AppColors.cyan),
                tooltip: 'Copy Code',
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

        /// ENTER PARTNER CODE
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
                style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. DOOM-A1B2-C3D4',
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
                    borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _connectPartner,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
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

  Widget _buildConnectedUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// CONNECTED PARTNER PROFILE CARD
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
                    child: const Icon(Icons.person_rounded, color: AppColors.cyan, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jane Doe',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'jane.doe@gmail.com',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.outline),
              const SizedBox(height: 16),

              /// PUSH NOTIFICATION SWITCHES
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
          'PARTNER\'S BREACH HISTORY',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 14),

        /// BREACH LOGS LIST
        ..._partnerBreaches.map((log) => _buildBreachRow(log)),

        const SizedBox(height: 28),

        /// DISSOLVE PARTNERSHIP
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

  Widget _buildBreachRow(_BreachLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: log.severityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(log.appIcon, color: log.severityColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.appName} Limit Exceeded',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.timeString,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '+${log.exceededMins}m',
            style: TextStyle(
              color: log.severityColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreachLog {
  final String appName;
  final IconData appIcon;
  final int exceededMins;
  final String timeString;
  final Color severityColor;

  const _BreachLog({
    required this.appName,
    required this.appIcon,
    required this.exceededMins,
    required this.timeString,
    required this.severityColor,
  });
}
