import 'package:flutter/foundation.dart';

/// A selectable answer on the onboarding diagnosis quizzes (screens 5 & 6).
@immutable
class OnboardingQuizOptionModel {
  const OnboardingQuizOptionModel({required this.id, required this.emoji, required this.translationKey});

  final String id;
  final String emoji;
  final String translationKey;

  /// Screen 5 — "What's the longest you've let dishes pile up?"
  static const List<OnboardingQuizOptionModel> dishPileupSeverityOptions = [
    OnboardingQuizOptionModel(id: 'full_day', emoji: '🍽️', translationKey: 'quiz_pileup_full_day'),
    OnboardingQuizOptionModel(id: 'several_days', emoji: '🗓️', translationKey: 'quiz_pileup_several_days'),
    OnboardingQuizOptionModel(id: 'disgust_anxiety', emoji: '😰', translationKey: 'quiz_pileup_disgust_anxiety'),
  ];

  /// Screen 6 — "What do you find hardest about washing dishes?"
  static const List<OnboardingQuizOptionModel> dishwashingStruggleOptions = [
    OnboardingQuizOptionModel(id: 'boredom', emoji: '🥱', translationKey: 'quiz_struggle_boredom'),
    OnboardingQuizOptionModel(id: 'adhd_paralysis', emoji: '🌀', translationKey: 'quiz_struggle_adhd_paralysis'),
    OnboardingQuizOptionModel(id: 'social_media', emoji: '📱', translationKey: 'quiz_struggle_social_media'),
  ];
}
