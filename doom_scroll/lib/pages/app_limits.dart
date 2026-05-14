import 'package:doom_scroll/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

const _amber = Color(0xFFFFAA00);

class AppLimitsPage extends StatefulWidget {
  const AppLimitsPage({super.key});

  @override
  State<AppLimitsPage> createState() => _AppLimitsPageState();
}

class _AppLimitsPageState extends State<AppLimitsPage> {
  List<_AppData> apps = [
    _AppData(
      name: 'Instagram',
      icon: Icons.camera_alt_outlined,
      timeUsed: '2h 15m today',
      limitMinutes: 45,
      status: 'High Risk',
      statusColor: _amber,
      accentColor: _amber,
      chipOptions: [15, 45, 60, 120],
    ),
    _AppData(
      name: 'TikTok',
      icon: Icons.music_note_outlined,
      timeUsed: '3h 42m today',
      limitMinutes: 20,
      status: 'Critical',
      statusColor: AppColors.red,
      accentColor: AppColors.red,
      chipOptions: [10, 20, 30],
    ),
    _AppData(
      name: 'Twitter',
      icon: Icons.close,
      timeUsed: '45m today',
      limitMinutes: 90,
      status: 'Moderate',
      statusColor: AppColors.cyan,
      accentColor: AppColors.purple,
      chipOptions: [45, 60, 90],
    ),
    _AppData(
      name: 'YouTube',
      icon: Icons.play_circle_outline,
      timeUsed: '1h 12m today',
      limitMinutes: 120,
      status: 'Moderate',
      statusColor: AppColors.cyan,
      accentColor: AppColors.cyan,
      chipOptions: [60, 120, 180],
    ),
  ];

  void _removeApp(int index) => setState(() => apps.removeAt(index));

  void _showAddAppDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add App',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'App name (e.g. Reddit)',
            hintStyle: const TextStyle(color: AppColors.muted),
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  apps.add(
                    _AppData(
                      name: name,
                      icon: Icons.phone_android_outlined,
                      timeUsed: '0m today',
                      limitMinutes: 60,
                      status: 'Moderate',
                      statusColor: AppColors.cyan,
                      accentColor: AppColors.cyan,
                      chipOptions: [30, 60, 90, 120],
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 10),

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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              /// HEADING
              const Text(
                'App Limits',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure your daily boundaries. Once reached,\nDoomScroll will intervene with a mindful lockout.',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 22),

              /// RECLAIM FOCUS CARD — first
              _ReclaimCard(onAddApp: _showAddAppDialog),

              const SizedBox(height: 22),

              /// SECTION LABEL
              const Text(
                'TRACKED APPS',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              /// APP LIMIT CARDS
              ...List.generate(
                apps.length,
                (i) => AppLimitCard(
                  key: ValueKey('${apps[i].name}_$i'),
                  data: apps[i],
                  onLimitChanged: (val) =>
                      setState(() => apps[i].limitMinutes = val),
                  onRemove: () => _removeApp(i),
                ),
              ),

              const SizedBox(height: 22),

              /// SAVE CARD
              _SaveCard(apps: apps),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _AppData {
  final String name;
  final IconData icon;
  final String timeUsed;
  int limitMinutes;
  final String status;
  final Color statusColor;
  final Color accentColor;
  final List<int> chipOptions;

  _AppData({
    required this.name,
    required this.icon,
    required this.timeUsed,
    required this.limitMinutes,
    required this.status,
    required this.statusColor,
    required this.accentColor,
    required this.chipOptions,
  });
}

// ── Reclaim Focus Card ────────────────────────────────────────────────────────
class _ReclaimCard extends StatelessWidget {
  final VoidCallback onAddApp;
  const _ReclaimCard({required this.onAddApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reclaim Your Focus',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The average user saves 4.2 hours per week by implementing these tactical boundaries. Your mental clarity is the ultimate prize.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 18),

          /// ADD APP button
          GestureDetector(
            onTap: onAddApp,
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'ADD APP',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.5,
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
}

// ── App Limit Card ────────────────────────────────────────────────────────────
class AppLimitCard extends StatelessWidget {
  final _AppData data;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback onRemove;

  const AppLimitCard({
    super.key,
    required this.data,
    required this.onLimitChanged,
    required this.onRemove,
  });

  String _fmt(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  @override
  Widget build(BuildContext context) {
    final maxM = (data.chipOptions.last * 1.5)
        .round()
        .clamp(60, 480)
        .toDouble();
    final sliderVal = data.limitMinutes.toDouble().clamp(5.0, maxM);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: data.accentColor.withOpacity(0.3)),
                ),
                child: Icon(data.icon, color: data.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Used: ${data.timeUsed}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              /// Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: data.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: data.statusColor.withOpacity(0.35)),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    color: data.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// Remove button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.red,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Daily limit label + current value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY LIMIT',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                _fmt(data.limitMinutes),
                style: TextStyle(
                  color: data.accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          /// Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: data.accentColor,
              inactiveTrackColor: AppColors.outline,
              thumbColor: Colors.white,
              overlayColor: data.accentColor.withOpacity(0.15),
            ),
            child: Slider(
              min: 5,
              max: maxM,
              value: sliderVal,
              onChanged: (v) => onLimitChanged(v.round()),
            ),
          ),

          const SizedBox(height: 6),

          /// Quick-select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.chipOptions.map((m) {
              final selected = data.limitMinutes == m;
              return GestureDetector(
                onTap: () => onLimitChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? data.accentColor
                        : data.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? data.accentColor
                          : data.accentColor.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    _fmt(m),
                    style: TextStyle(
                      color: selected ? Colors.black : data.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Save Card ─────────────────────────────────────────────────────────────────
class _SaveCard extends StatelessWidget {
  final List<_AppData> apps;
  const _SaveCard({required this.apps});

  @override
  Widget build(BuildContext context) {
    final totalMinutes = apps.fold(0, (sum, a) => sum + a.limitMinutes);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final label = m == 0 ? '${h}h / day' : '${h}h ${m}m / day';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'TOTAL SCREEN TIME TARGET',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.edit_outlined, color: AppColors.muted, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Limits saved!'),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SAVE LIMITS',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
