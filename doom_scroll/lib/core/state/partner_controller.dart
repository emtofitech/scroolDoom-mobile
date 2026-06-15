import 'package:flutter_riverpod/legacy.dart';
import '../models/partner_models.dart';
import '../services/partner_service.dart';
import '../services/token_storage.dart';
import 'partner_state.dart';

final partnerControllerProvider =
    StateNotifierProvider<PartnerController, PartnerState>(
  (ref) => PartnerController(),
);

class PartnerController extends StateNotifier<PartnerState> {
  PartnerController() : super(PartnerState());

  Future<void> loadPartnership() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await PartnerService.getMyPartnership();
    if (result.isSuccess) {
      state = state.copyWith(
        partnership: await _fixPartner(result.data!),
        isLoading: false,
      );
    } else if (result.error == 'No active partnership found') {
      state = state.copyWith(
        clearPartnership: true,
        isLoading: false,
      );
    } else if (state.partnership == null) {
      state = state.copyWith(
        clearPartnership: true,
        isLoading: false,
        error: result.error,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<bool> generateInvite() async {
    state = state.copyWith(isGenerating: true, error: null);
    final result = await PartnerService.generateInvite();
    if (result.isSuccess) {
      state = state.copyWith(
        partnership: await _fixPartner(result.data!),
        isGenerating: false,
      );
      return true;
    }

    final err = result.error?.toLowerCase() ?? '';
    if (err.contains('pending') || err.contains('already') || err.contains('active')) {
      await loadPartnership();
      if (state.partnership != null) {
        state = state.copyWith(isGenerating: false, error: null);
        return true;
      }
    }

    state = state.copyWith(isGenerating: false, error: result.error);
    return false;
  }

  Future<bool> acceptInvite(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await PartnerService.acceptInvite(inviteCode);
    if (result.isSuccess) {
      state = state.copyWith(
        partnership: await _fixPartner(result.data!),
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
      return false;
    }
  }

  Future<Partnership> _fixPartner(Partnership p) async {
    final email = await TokenStorage.email;
    if (email != null && p.partner?.email == email && p.createdBy != null) {
      return Partnership(
        id: p.id,
        status: p.status,
        inviteCode: p.inviteCode,
        createdAt: p.createdAt,
        acceptedAt: p.acceptedAt,
        partner: p.createdBy,
        createdBy: p.partner,
      );
    }
    return p;
  }

  Future<bool> dissolvePartnership() async {
    final partnership = state.partnership;
    if (partnership == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    final result = await PartnerService.dissolvePartnership(partnership.id);
    if (result.isSuccess) {
      state = state.copyWith(clearPartnership: true, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error ?? 'Failed to dissolve');
    }
    return result.isSuccess;
  }
}
