import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../data/models/onboarding_user_preferences_model.dart';
import '../../data/models/screen_time_access_model.dart';
import '../../../Feature_06_SinkUnlock/data/data_sources/installed_apps_platform_data_source.dart';
import '../../data/repos/onboarding_repo.dart';

part 'onboarding_state.dart';

/// Owns the whole 15-step funnel: active step, every answer, permission
/// requests and completion. Widgets stay dumb and only call these methods.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required OnboardingRepo repo, required LocaleController localeController})
    : _repo = repo,
      _localeController = localeController,
      super(_initialState(repo, localeController)) {
    _loadInstalledApps(); // early, so screen 10 opens instantly
  }

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

  AppPickerMode get appPickerMode => _repo.appPickerMode;

  Future<void> _loadInstalledApps() async {
    final apps = await _repo.loadInstalledApps();
    if (isClosed) return;
    // Default picks (TikTok, Instagram…) only stay if they're installed.
    final selection = apps.isEmpty
        ? state.preferences.appSelection
        : state.preferences.appSelection.keepInstalled(apps);
    emit(
      state.copyWith(
        installedApps: apps,
        appsLoaded: true,
        preferences: state.preferences.copyWith(appSelection: selection),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  /// Native store rating sheet, once, a moment after the plan reveal.
  Future<void> requestStoreReview() => _repo.requestStoreReviewOnce();

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

  void setMealEnabled(List<int> weekdays, MealType type, bool enabled) =>
      _updateSchedule(state.preferences.schedule.withMealEnabled(weekdays, type, enabled: enabled));

  void setMealTime(List<int> weekdays, int mealIndex, int minutesOfDay) =>
      _updateSchedule(state.preferences.schedule.withMealTime(weekdays, mealIndex, minutesOfDay));

  void syncAllDaysWith(int weekday) => _updateSchedule(state.preferences.schedule.syncAllActiveDaysWith(weekday));

  // ── Screen 10: Apps ────────────────────────────────────────────────────
  void updateAppSelection(AppSelectionModel selection) =>
      _updatePreferences(state.preferences.copyWith(appSelection: selection));

  /// Quick toggle of a single app by id (tests / shortcuts).
  void toggleBlockedApp(String appId) {
    final app = BlockableAppModel.byId(appId);
    if (app == null) return;
    updateAppSelection(state.preferences.appSelection.toggleApp(app, state.installedApps));
  }

  // ── Screen 9: Screen Time permission ───────────────────────────────────
  /// Re-reads the OS status (on entering the step and whenever the app comes
  /// back to the foreground, e.g. from Android Settings). A grant that
  /// happened outside a pending request still completes the step.
  Future<void> refreshScreenTimeAccess() async {
    final result = await _repo.getScreenTimeAccess();
    if (isClosed) return;
    result.fold((_) {}, (access) {
      final previous = state.screenTimeAccess;
      final justGranted = access.isGranted && previous != null && !previous.isGranted;
      _applyScreenTimeAccess(access, status: justGranted ? OnboardingRequestStatus.success : null);
    });
  }

  /// iOS: shows Apple's popup · Android: opens the next Settings toggle.
  Future<void> requestScreenTimePermission() async {
    if (state.permissionStatus == OnboardingRequestStatus.inProgress) return;
    final before = state.screenTimeAccess;
    emit(state.copyWith(permissionStatus: OnboardingRequestStatus.inProgress, clearFailure: true));
    final result = await _repo.requestScreenTimePermission();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(permissionStatus: OnboardingRequestStatus.failure, failureKey: failure.messageKey)),
      (access) {
        if (access.isGranted) {
          // Already marked by a concurrent refresh → keep a single success.
          return _applyScreenTimeAccess(access, status: OnboardingRequestStatus.success);
        }
        // Android: one of two toggles done → idle, ready for the next one.
        final madeProgress = access.grantedCount > (before?.grantedCount ?? 0);
        _applyScreenTimeAccess(
          access,
          status: madeProgress ? OnboardingRequestStatus.idle : OnboardingRequestStatus.failure,
          failureKey: madeProgress ? null : 'permission_not_granted_hint',
        );
      },
    );
  }

  void _applyScreenTimeAccess(ScreenTimeAccessModel access, {OnboardingRequestStatus? status, String? failureKey}) {
    emit(
      state.copyWith(
        screenTimeAccess: access,
        permissionStatus: status,
        failureKey: failureKey,
        clearFailure: failureKey == null && status != null,
        preferences: state.preferences.copyWith(screenTimePermissionGranted: access.isGranted),
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
