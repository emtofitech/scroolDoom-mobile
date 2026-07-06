import 'package:flutter_riverpod/legacy.dart';
import '../models/breach_models.dart';
import '../services/breach_service.dart';

class BreachState {
  final List<Breach> breaches;
  final bool isLoading;
  final String? error;

  BreachState({
    this.breaches = const [],
    this.isLoading = false,
    this.error,
  });

  BreachState copyWith({
    List<Breach>? breaches,
    bool? isLoading,
    String? error,
  }) {
    return BreachState(
      breaches: breaches ?? this.breaches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final breachControllerProvider = StateNotifierProvider<BreachController, BreachState>(
  (ref) => BreachController(),
);

class BreachController extends StateNotifier<BreachState> {
  BreachController() : super(BreachState());

  Future<void> loadBreaches() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await BreachService.getMyBreaches();
    if (result.isSuccess) {
      state = state.copyWith(breaches: result.data ?? [], isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> loadBreachesByType(BreachType type) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await BreachService.getMyBreachesByType(type);
    if (result.isSuccess) {
      state = state.copyWith(breaches: result.data ?? [], isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<bool> acknowledgeBreach(String breachId) async {
    final result = await BreachService.acknowledgeBreach(breachId);
    if (result.isSuccess) {
      final updated = state.breaches.map((b) {
        if (b.id == breachId) {
          return Breach(
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
        }
        return b;
      }).toList();
      state = state.copyWith(breaches: updated);
      return true;
    }
    return false;
  }

  Future<Breach?> reportStreakBroken({
    required String streakName,
    required int missedDays,
  }) async {
    final result = await BreachService.reportStreakBroken(
      streakName: streakName,
      missedDays: missedDays,
    );
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        breaches: [result.data!, ...state.breaches],
      );
      return result.data;
    }
    return null;
  }

  Future<Breach?> reportBlockedApp({
    required String packageName,
    required String appLabel,
  }) async {
    final result = await BreachService.reportBlockedApp(
      packageName: packageName,
      appLabel: appLabel,
    );
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        breaches: [result.data!, ...state.breaches],
      );
      return result.data;
    }
    return null;
  }

  void removeBreachesByPackage(String packageName) {
    final filtered = state.breaches.where((b) => b.packageName != packageName).toList();
    if (filtered.length != state.breaches.length) {
      state = state.copyWith(breaches: filtered);
    }
  }
}
