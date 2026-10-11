import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../data/models/onboarding_user_preferences_model.dart';
import '../../data/repos/onboarding_repo.dart';

part 'onboarding_state.dart';

/// Owns the whole 15-step funnel: active step, every answer, permission
/// requests and completion. Widgets stay dumb and only call these methods.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required OnboardingRepo repo, required LocaleController localeController})
    : _repo = repo,
      _localeController = localeController,
      super(_initialState(repo, localeController));

  final OnboardingRepo _repo;
  final LocaleController _localeController;

  static OnboardingState _initialState(OnboardingRepo repo, LocaleController localeController) {
    // First launch: pre-select the device language automatically.
    final languageCode = localeController.hasUserChosenLanguage
        ? localeController.locale.languageCode
        : LocaleController.deviceLanguageCode();
    final draft = repo.restoreDraft(languageCode: languageCode);
    final safeIndex = draft.stepIndex.clamp(0, OnboardingStep.values.length - 1);
    return OnboardingState(currentStep: OnboardingStep.values[safeIndex], preferences: draft.preferences);
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  void nextStep() {
    if (state.currentStep.isPaywall) return;
    _goTo(OnboardingStep.values[state.stepIndex + 1]);
  }

  void previousStep() {
    if (state.currentStep.isFirst) return;
    _goTo(OnboardingStep.values[state.stepIndex - 1]);
  }

  void _goTo(OnboardingStep step) {
    emit(state.copyWith(currentStep: step, permissionStatus: OnboardingRequestStatus.idle, clearFailure: true));
    _repo.saveDraft(state.preferences, step.index); // fire-and-forget persistence
  }

  void _updatePreferences(OnboardingUserPreferencesModel preferences) => emit(state.copyWith(preferences: preferences));

  // ── Screen 1: Language ─────────────────────────────────────────────────
  Future<void> selectLanguage(String languageCode) async {
    _updatePreferences(state.preferences.copyWith(languageCode: languageCode));
    // Live preview: the whole UI switches language (and RTL) immediately.
    await _localeController.changeLanguage(languageCode);
  }

  /// Persists the (possibly auto-detected) language when leaving screen 1.
  Future<void> confirmLanguage() async {
    await _localeController.changeLanguage(state.preferences.languageCode);
    nextStep();
  }

  // ── Screen 2: Name ─────────────────────────────────────────────────────
  void updateName(String name) => _updatePreferences(state.preferences.copyWith(userName: name));

  // ── Screens 5 & 6: Quizzes ─────────────────────────────────────────────
  void selectDishPileupSeverity(String optionId) =>
      _updatePreferences(state.preferences.copyWith(dishPileupSeverityId: optionId));

  void selectMainStruggle(String optionId) => _updatePreferences(state.preferences.copyWith(mainStruggleId: optionId));

  // ── Screen 8: Schedule matrix ──────────────────────────────────────────
  void _updateSchedule(WeeklyLockScheduleModel schedule) =>
      _updatePreferences(state.preferences.copyWith(schedule: schedule));

  void toggleScheduleDay(int weekday) => _updateSchedule(state.preferences.schedule.toggleDay(weekday));

  void toggleDayPreset(DaySelectionPreset preset) => _updateSchedule(state.preferences.schedule.togglePreset(preset));

  void setMealCount(List<int> weekdays, int count) =>
      _updateSchedule(state.preferences.schedule.withMealCount(weekdays, count));

  void setMealTime(List<int> weekdays, int mealIndex, int minutesOfDay) =>
      _updateSchedule(state.preferences.schedule.withMealTime(weekdays, mealIndex, minutesOfDay));

  void syncAllDaysWith(int weekday) => _updateSchedule(state.preferences.schedule.syncAllActiveDaysWith(weekday));

  // ── Screen 9: Apps ─────────────────────────────────────────────────────
  void toggleBlockedApp(String appId) {
    final current = state.preferences.blockedAppIds;
    final updated = current.contains(appId) ? current.where((id) => id != appId).toList() : [...current, appId];
    _updatePreferences(state.preferences.copyWith(blockedAppIds: List.unmodifiable(updated)));
  }

  // ── Screen 10: Screen Time permission ──────────────────────────────────
  Future<void> requestScreenTimePermission() async {
    emit(state.copyWith(permissionStatus: OnboardingRequestStatus.inProgress, clearFailure: true));
    final result = await _repo.requestScreenTimePermission();
    result.fold(
      (failure) =>
          emit(state.copyWith(permissionStatus: OnboardingRequestStatus.failure, failureKey: failure.messageKey)),
      (granted) => emit(
        state.copyWith(
          permissionStatus: granted ? OnboardingRequestStatus.success : OnboardingRequestStatus.failure,
          failureKey: granted ? null : 'error_permission_screen_time',
          preferences: state.preferences.copyWith(screenTimePermissionGranted: granted),
        ),
      ),
    );
  }

  // ── Screen 12: Commitment ──────────────────────────────────────────────
  void confirmCommitment() => _updatePreferences(state.preferences.copyWith(commitmentConfirmed: true));

  // ── Screen 14: Trial reminder (notification opt-in) ────────────────────
  Future<void> acceptTrialReminder() async {
    emit(state.copyWith(permissionStatus: OnboardingRequestStatus.inProgress));
    final result = await _repo.requestNotificationPermission();
    final accepted = result.getOrElse(() => false);
    emit(
      state.copyWith(
        permissionStatus: OnboardingRequestStatus.idle,
        preferences: state.preferences.copyWith(notificationsAccepted: accepted),
      ),
    );
    nextStep();
  }

  // ── Screen 15: Completion (after purchase OR paywall dismissal) ────────
  Future<bool> completeOnboarding() async {
    emit(state.copyWith(completionStatus: OnboardingRequestStatus.inProgress));
    final result = await _repo.completeOnboarding(state.preferences);
    return result.fold(
      (failure) {
        emit(state.copyWith(completionStatus: OnboardingRequestStatus.failure, failureKey: failure.messageKey));
        return false;
      },
      (_) {
        emit(state.copyWith(completionStatus: OnboardingRequestStatus.success));
        return true;
      },
    );
  }
}
