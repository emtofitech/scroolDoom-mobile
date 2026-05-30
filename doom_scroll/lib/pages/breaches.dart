import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models/breach_models.dart';
import '../core/services/breach_service.dart';
import '../core/theme/colors.dart';
import '../widgets/bottom_nav.dart';

class BreachesPage extends StatefulWidget {
  const BreachesPage({super.key});

  @override
  State<BreachesPage> createState() => _BreachesPageState();
}

class _BreachesPageState extends State<BreachesPage> {
  List<Breach> _breaches = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    final result = await BreachService.getMyBreaches();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _breaches = result.data ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result.error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Breaches'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _breaches.isEmpty
                  ? const Center(
                      child: Text(
                        'No breaches recorded',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _breaches.length,
                        itemBuilder: (context, index) {
                          final breach = _breaches[index];
                          return _BreachCard(
                            breach: breach,
                            onAcknowledge: breach.acknowledged
                                ? null
                                : () => _acknowledge(breach.id, index),
                          );
                        },
                    ),
                  ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Future<void> _acknowledge(String id, int index) async {
    final result = await BreachService.acknowledgeBreach(id);
    if (!mounted) return;
    if (result.isSuccess) {
      final b = _breaches[index];
      _breaches[index] = Breach(
        id: b.id,
        breachType: b.breachType,
        packageName: b.packageName,
        appLabel: b.appLabel,
        limitMinutes: b.limitMinutes,
        actualMinutes: b.actualMinutes,
        streakName: b.streakName,
        missedDays: b.missedDays,
        severity: b.severity,
        partnerNotified: b.partnerNotified,
        acknowledged: true,
        breachedAt: b.breachedAt,
      );
      setState(() {});
    }
  }
}

class _BreachCard extends StatelessWidget {
  final VoidCallback? onAcknowledge;
  final Breach breach;

  const _BreachCard({required this.breach, this.onAcknowledge});

  IconData _icon() {
    switch (breach.breachType) {
      case BreachType.blockedAppOpened:
        return Icons.block;
      case BreachType.screenTimeExceeded:
        return Icons.timer_off;
      case BreachType.streakBroken:
        return Icons.local_fire_department;
    }
  }

  Color _color() {
    switch (breach.severity) {
      case 'HIGH':
        return Colors.redAccent;
      case 'MEDIUM':
        return Colors.orangeAccent;
      default:
        return AppColors.cyan;
    }
  }

  String _title() {
    if (breach.streakName != null) return breach.streakName!;
    if (breach.appLabel != null) return breach.appLabel!;
    return 'Breach';
  }

  String _subtitle() {
    final buf = StringBuffer();
    buf.write(_formatType(breach.breachType));
    if (breach.actualMinutes != null && breach.limitMinutes != null) {
      buf.write(' \u2014 ${breach.actualMinutes}m / ${breach.limitMinutes}m');
    }
    if (breach.missedDays != null) {
      buf.write(' \u2014 ${breach.missedDays} day${breach.missedDays == 1 ? "" : "s"}');
    }
    return buf.toString();
  }

  String _formatType(BreachType type) {
    switch (type) {
      case BreachType.blockedAppOpened:
        return 'Blocked app';
      case BreachType.screenTimeExceeded:
        return 'Screen time';
      case BreachType.streakBroken:
        return 'Streak broken';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: breach.acknowledged ? null : onAcknowledge,
        leading: CircleAvatar(
          backgroundColor: _color().withOpacity(0.2),
          child: Icon(_icon(), color: _color(), size: 20),
        ),
        title: Text(
          _title(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _subtitle(),
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _timeAgo(breach.breachedAt),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            if (breach.acknowledged)
              const Icon(Icons.check_circle, color: Colors.green, size: 16)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
