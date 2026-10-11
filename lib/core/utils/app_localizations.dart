import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/supported_language_model.dart';
import 'local_storage_service.dart';
import 'style.dart';

/// JSON-based localization.
///
/// Translations live in `assets/translations/<code>.json` (one file per
/// language). English is always loaded as the fallback, so a language file
/// only needs the keys that have been translated so far.
class AppLocalizations {
  AppLocalizations._(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations._(const Locale('en'), const {});

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Returns the translation for [key]. `{placeholders}` are replaced with
  /// [params], e.g. `tr('hello_name', {'name': 'Sara'})`.
  String translate(String key, [Map<String, String>? params]) {
    var value = _strings[key] ?? key;
    if (params != null) {
      params.forEach((name, replacement) => value = value.replaceAll('{$name}', replacement));
    }
    return value;
  }

  static final Map<String, Map<String, String>> _cache = {};

  static Future<Map<String, String>> _loadFile(String code) async {
    final cached = _cache[code];
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString('assets/translations/$code.json');
      final decoded = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
      return _cache[code] = decoded;
    } catch (error) {
      debugPrint('Missing translation file for "$code": $error');
      return _cache[code] = const {};
    }
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final fallback = await _loadFile(SupportedLanguageModel.fallbackCode);
    final localized = locale.languageCode == SupportedLanguageModel.fallbackCode
        ? const <String, String>{}
        : await _loadFile(locale.languageCode);
    return AppLocalizations._(locale, {...fallback, ...localized});
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => SupportedLanguageModel.isSupported(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Holds the active app locale. The [MaterialApp] listens to it, so calling
/// [changeLanguage] re-renders the app instantly (including RTL flipping for
/// Arabic, handled automatically by `GlobalWidgetsLocalizations`).
class LocaleController extends ChangeNotifier {
  LocaleController(this._storage) : _locale = Locale(_storage.getString(_localeKey) ?? deviceLanguageCode()) {
    AppTextStyles.configureForLanguage(_locale.languageCode);
  }

  final LocalStorageService _storage;
  static const String _localeKey = 'sinkly.locale';

  Locale _locale;
  Locale get locale => _locale;
  SupportedLanguageModel get language => SupportedLanguageModel.byCode(_locale.languageCode);

  /// Whether the user has explicitly chosen a language yet.
  bool get hasUserChosenLanguage => _storage.getString(_localeKey) != null;

  /// Reads the device language and maps it to one of the 10 supported codes.
  static String deviceLanguageCode() {
    final deviceLocales = ui.PlatformDispatcher.instance.locales;
    for (final deviceLocale in deviceLocales) {
      if (SupportedLanguageModel.isSupported(deviceLocale.languageCode)) return deviceLocale.languageCode;
    }
    return SupportedLanguageModel.fallbackCode;
  }

  Future<void> changeLanguage(String code, {bool persist = true}) async {
    final safeCode = SupportedLanguageModel.isSupported(code) ? code : SupportedLanguageModel.fallbackCode;
    if (persist) await _storage.setString(_localeKey, safeCode);
    if (safeCode == _locale.languageCode) return;
    _locale = Locale(safeCode);
    AppTextStyles.configureForLanguage(safeCode);
    notifyListeners();
  }
}

/// Short-hand: `context.tr('key')` / `context.tr('key', {'name': name})`.
extension AppLocalizationsContext on BuildContext {
  String tr(String key, [Map<String, String>? params]) => AppLocalizations.of(this).translate(key, params);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Mirrors a horizontal slide offset so entrance animations travel
  /// "from the reading-start side" in both LTR and RTL.
  double flipX(double value) => isRtl ? -value : value;
}
