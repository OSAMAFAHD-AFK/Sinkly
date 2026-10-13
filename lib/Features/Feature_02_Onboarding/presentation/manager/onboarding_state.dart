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
  distractingAppsSelection,
  screenTimePermission,
  sinklySolutionExplainer,
  personalCommitment,
  personalizedPlanSummary,
  trialReminderAssurance,
  paywall;

  bool get isFirst => index == 0;
  bool get isPaywall => this == OnboardingStep.paywall;

  /// Steps that show the progress bar & back button.
  bool get showsChrome => !isPaywall;
}

enum OnboardingRequestStatus { idle, inProgress, success, failure }

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.currentStep,
    required this.preferences,
    this.permissionStatus = OnboardingRequestStatus.idle,
    this.completionStatus = OnboardingRequestStatus.idle,
    this.failureKey,
    this.installedApps = const [],
    this.appsLoaded = false,
  });

  final OnboardingStep currentStep;
  final OnboardingUserPreferencesModel preferences;
  final OnboardingRequestStatus permissionStatus;
  final OnboardingRequestStatus completionStatus;
  final String? failureKey;

  /// Device apps for the category picker on screen 9 (Android).
  final List<BlockableAppModel> installedApps;
  final bool appsLoaded;

  int get stepIndex => currentStep.index;
  static int get totalSteps => OnboardingStep.values.length;

  /// 0 … 1 progress used by the top progress bar.
  double get progress => (stepIndex + 1) / totalSteps;

  bool get canContinueFromName => preferences.trimmedName.isNotEmpty;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    OnboardingUserPreferencesModel? preferences,
    OnboardingRequestStatus? permissionStatus,
    OnboardingRequestStatus? completionStatus,
    String? failureKey,
    bool clearFailure = false,
    List<BlockableAppModel>? installedApps,
    bool? appsLoaded,
  }) => OnboardingState(
    currentStep: currentStep ?? this.currentStep,
    preferences: preferences ?? this.preferences,
    permissionStatus: permissionStatus ?? this.permissionStatus,
    completionStatus: completionStatus ?? this.completionStatus,
    failureKey: clearFailure ? null : failureKey ?? this.failureKey,
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
    installedApps,
    appsLoaded,
  ];
}
