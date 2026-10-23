import '../../../../core/models/shared_core_models.dart';
import '../../../../core/utils/local_storage_service.dart';

/// Persists the onboarding draft so users resume where they left off if the
/// app is killed mid-funnel.
abstract class OnboardingLocalDataSource {
  UserPlanModel readSavedPlan();
  int readSavedStepIndex();
  Future<void> saveDraft({required UserPlanModel plan, required int stepIndex});
  Future<void> completeOnboarding(UserPlanModel plan);

  /// The native store rating sheet was already asked for (once per install).
  bool readStoreReviewRequested();
  Future<void> markStoreReviewRequested();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  OnboardingLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;
  static const String _stepIndexKey = 'sinkly.onboarding_step_index';
  static const String _storeReviewKey = 'sinkly.onboarding_store_review_requested';

  @override
  UserPlanModel readSavedPlan() => _storage.plan;

  @override
  int readSavedStepIndex() => int.tryParse(_storage.getString(_stepIndexKey) ?? '') ?? 0;

  @override
  Future<void> saveDraft({required UserPlanModel plan, required int stepIndex}) async {
    await _storage.savePlan(plan);
    await _storage.setString(_stepIndexKey, '$stepIndex');
  }

  @override
  Future<void> completeOnboarding(UserPlanModel plan) async {
    await _storage.savePlan(plan.copyWith(onboardingCompleted: true));
    await _storage.setString(_stepIndexKey, '0');
  }

  @override
  bool readStoreReviewRequested() => _storage.getBool(_storeReviewKey);

  @override
  Future<void> markStoreReviewRequested() => _storage.setBool(_storeReviewKey, true);
}
