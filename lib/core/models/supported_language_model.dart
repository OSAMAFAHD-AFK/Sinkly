import 'package:flutter/widgets.dart';

/// One of the 10 languages Sinkly ships with.
@immutable
class SupportedLanguageModel {
  const SupportedLanguageModel({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flagEmoji,
    this.isRightToLeft = false,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final String flagEmoji;
  final bool isRightToLeft;

  Locale get locale => Locale(code);

  static const String fallbackCode = 'en';

  /// Order shown on the language selection screen.
  static const List<SupportedLanguageModel> all = [
    SupportedLanguageModel(code: 'en', nativeName: 'English', englishName: 'English', flagEmoji: '🇺🇸'),
    SupportedLanguageModel(
      code: 'ar',
      nativeName: 'العربية',
      englishName: 'Arabic',
      flagEmoji: '🇸🇦',
      isRightToLeft: true,
    ),
    SupportedLanguageModel(code: 'es', nativeName: 'Español', englishName: 'Spanish', flagEmoji: '🇪🇸'),
    SupportedLanguageModel(code: 'de', nativeName: 'Deutsch', englishName: 'German', flagEmoji: '🇩🇪'),
    SupportedLanguageModel(code: 'fr', nativeName: 'Français', englishName: 'French', flagEmoji: '🇫🇷'),
    SupportedLanguageModel(code: 'pt', nativeName: 'Português', englishName: 'Portuguese', flagEmoji: '🇧🇷'),
    SupportedLanguageModel(code: 'ja', nativeName: '日本語', englishName: 'Japanese', flagEmoji: '🇯🇵'),
    SupportedLanguageModel(code: 'ko', nativeName: '한국어', englishName: 'Korean', flagEmoji: '🇰🇷'),
    SupportedLanguageModel(code: 'it', nativeName: 'Italiano', englishName: 'Italian', flagEmoji: '🇮🇹'),
    SupportedLanguageModel(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', flagEmoji: '🇮🇳'),
  ];

  static List<Locale> get supportedLocales => all.map((language) => language.locale).toList(growable: false);

  static bool isSupported(String? code) => all.any((language) => language.code == code);

  static SupportedLanguageModel byCode(String? code) =>
      all.firstWhere((language) => language.code == code, orElse: () => all.first);
}
