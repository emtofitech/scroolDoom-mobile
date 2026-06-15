import '../models/partner_models.dart';

class PartnerState {
  final Partnership? partnership;
  final bool isLoading;
  final String? error;
  final bool isGenerating;

  PartnerState({
    this.partnership,
    this.isLoading = false,
    this.error,
    this.isGenerating = false,
  });

  bool get hasActivePartnership => partnership?.isActive == true;
  bool get isPending =>
      partnership != null && partnership?.isActive != true;
  bool get isGuest => partnership == null;

  PartnerState copyWith({
    bool clearPartnership = false,
    Partnership? partnership,
    bool? isLoading,
    String? error,
    bool? isGenerating,
  }) {
    return PartnerState(
      partnership: clearPartnership ? null : partnership ?? this.partnership,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}
