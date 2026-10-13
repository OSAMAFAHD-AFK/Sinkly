import 'package:equatable/equatable.dart';

/// One OS-level grant Sinkly needs before it can lock apps.
///
/// * iOS — a single system prompt (FamilyControls "Screen Time" access).
/// * Android — two special accesses the user switches on in Settings:
///   "Display over other apps" (draws the lock screen) and "Usage access"
///   (knows which app just opened). Overlay comes first: it opens straight on
///   Sinkly's own toggle, and once granted Android lets Sinkly jump back
///   to the foreground automatically after the usage-access toggle.
enum ScreenTimeRequirement {
  familyControls('familyControls'),
  displayOverApps('displayOverApps'),
  usageAccess('usageAccess');

  const ScreenTimeRequirement(this.channelKey);

  /// Key used by the native side (`sinkly/screen_time`).
  final String channelKey;

  /// Shown by the OS as a popup over the app (vs. a Settings page).
  bool get isSystemPrompt => this == ScreenTimeRequirement.familyControls;
}

/// Which [requirements] this device has and which of them are [granted].
class ScreenTimeAccessModel extends Equatable {
  const ScreenTimeAccessModel({required this.requirements, this.granted = const {}});

  /// Native payload: `{requirementKey: bool}`, e.g. `{"familyControls": true}`.
  factory ScreenTimeAccessModel.fromMap(Map<Object?, Object?> map) {
    final requirements = ScreenTimeRequirement.values.where((r) => map.containsKey(r.channelKey)).toList();
    return ScreenTimeAccessModel(
      requirements: requirements,
      granted: {
        for (final requirement in requirements)
          if (map[requirement.channelKey] == true) requirement,
      },
    );
  }

  final List<ScreenTimeRequirement> requirements;
  final Set<ScreenTimeRequirement> granted;

  bool get isGranted => requirements.isNotEmpty && requirements.every(granted.contains);

  int get grantedCount => requirements.where(granted.contains).length;

  /// The next grant to ask for, in order (null once everything is on).
  ScreenTimeRequirement? get nextMissing {
    for (final requirement in requirements) {
      if (!granted.contains(requirement)) return requirement;
    }
    return null;
  }

  /// iOS-style flow (one system popup) vs. Android Settings toggles.
  bool get usesSystemPrompt => requirements.any((r) => r.isSystemPrompt);

  bool isRequirementGranted(ScreenTimeRequirement requirement) => granted.contains(requirement);

  ScreenTimeAccessModel grant(ScreenTimeRequirement requirement) =>
      ScreenTimeAccessModel(requirements: requirements, granted: {...granted, requirement});

  @override
  List<Object?> get props => [requirements, granted.toList()..sort((a, b) => a.index - b.index)];
}
