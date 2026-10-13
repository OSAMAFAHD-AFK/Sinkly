part of 'onboarding_cubit.dart';

/// The 15 funnel steps, in conversion-optimized order.
enum OnboardingStep {
  languageSelection,
  nameInput,
  emotionalPainPoint,
  realityCheck,
  dishPileupDiagnosisQuiz,
  dishwashingStruggleEmpathy,
  timeLossFrictionAnalysis,
  mealScheduleSetup,
  // Permission BEFORE the picker: on iOS Apple's FamilyActivityPicker only
  // works once Screen Time access is granted (otherwise it pops the system
  // prompt itself, without our framed explanation).
  screenTimePermission,
  distractingAppsSelection,
  sinklySolutionExplainer,
  personalCommitment,
  personalizedPlanSummary,
  trialReminderAssurance,
  paywall;

  bool get isFirst => index == 0;
  bool get isPaywall => this == OnboardingStep.paywall;

  /// Steps that show the progress bar & back button: language … apps
  /// selection (Screen Time permission included). After that the funnel is "sealed": no bar, no back button.
  bool get showsChrome => index <= OnboardingStep.distractingAppsSelection.index;
}

enum OnboardingRequestStatus { idle, inProgress, success, failure }

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.currentStep,
    required this.preferences,
    this.permissionStatus = OnboardingRequestStatus.idle,
    this.completionStatus = OnboardingRequestStatus.idle,
    this.failureKey,
    this.screenTimeAccess,
    this.installedApps = const [],
    this.appsLoaded = false,
  });

  final OnboardingStep currentStep;
  final OnboardingUserPreferencesModel preferences;
  final OnboardingRequestStatus permissionStatus;
  final OnboardingRequestStatus completionStatus;
  final String? failureKey;

  /// Live Screen Time status (null until checked on the permission step).
  final ScreenTimeAccessModel? screenTimeAccess;

  /// Device apps for the category picker on screen 9 (Android).
  final List<BlockableAppModel> installedApps;
  final bool appsLoaded;

  int get stepIndex => currentStep.index;
  static int get totalSteps => OnboardingStep.values.length;

  /// Screens that show the progress bar (language … apps selection).
  static int get barSteps => OnboardingStep.distractingAppsSelection.index + 1;

  /// 0 … 1 progress used by the top progress bar: it fills completely on the
  /// last screen that shows it (the apps-selection screen).
  double get progress => ((stepIndex + 1) / barSteps).clamp(0.0, 1.0);

  bool get canContinueFromName => preferences.trimmedName.isNotEmpty;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    OnboardingUserPreferencesModel? preferences,
    OnboardingRequestStatus? permissionStatus,
    OnboardingRequestStatus? completionStatus,
    String? failureKey,
    bool clearFailure = false,
    ScreenTimeAccessModel? screenTimeAccess,
    List<BlockableAppModel>? installedApps,
    bool? appsLoaded,
  }) => OnboardingState(
    currentStep: currentStep ?? this.currentStep,
    preferences: preferences ?? this.preferences,
    permissionStatus: permissionStatus ?? this.permissionStatus,
    completionStatus: completionStatus ?? this.completionStatus,
    failureKey: clearFailure ? null : failureKey ?? this.failureKey,
    screenTimeAccess: screenTimeAccess ?? this.screenTimeAccess,
    installedApps: installedApps ?? this.installedApps,
    appsLoaded: appsLoaded ?? this.appsLoaded,
  );

  @override
  List<Object?> get props => [
    currentStep,
    preferences,
    permissionStatus,
    completionStatus,
    failureKey,
    screenTimeAccess,
    installedApps,
    appsLoaded,
  ];
}
