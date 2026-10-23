import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/app_toast_widget.dart';
import '../app_localizations.dart';

/// Small, stateless helpers shared across features.
abstract final class AppFunctions {
  // ── Haptics (subtle feedback makes the glass UI feel tactile) ──────────
  static void selectionHaptic() => HapticFeedback.selectionClick();
  static void lightHaptic() => HapticFeedback.lightImpact();
  static void mediumHaptic() => HapticFeedback.mediumImpact();
  static void successHaptic() => HapticFeedback.heavyImpact();

  // ── Time formatting ────────────────────────────────────────────────────
  /// 1260 → "9:00 PM" (or "21:00" depending on device settings).
  /// Digits are always 0-9 (product decision), even in Arabic; the AM/PM
  /// marker stays localized (ص / م).
  static String formatMinutesOfDay(BuildContext context, int minutesOfDay) {
    final time = TimeOfDay(hour: minutesOfDay ~/ 60, minute: minutesOfDay % 60);
    return westernDigits(
      MaterialLocalizations.of(context)
          .formatTimeOfDay(time, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context)),
    );
  }

  /// "١٢:٠٥" / "۱۲:۰۵" → "12:05".
  static String westernDigits(String text) => text.replaceAllMapped(
    RegExp('[٠-٩۰-۹]'),
    (match) => '${match[0]!.codeUnitAt(0) & 0x0F}',
  );

  /// A store price ("US$ ٣٩٫٩٩") as the app shows it: 0-9 digits and "." / ",",
  /// inside a left-to-right isolate so Arabic / Hebrew text around it can't
  /// reverse "US$39.99" into "$US 39.99". Display only: never parse it.
  static String priceText(String price) {
    final plain = westernDigits(price).replaceAll('٫', '.').replaceAll('٬', ',').trim();
    return plain.isEmpty ? plain : '\u2066$plain\u2069';
  }

  static String formatDateTimeClock(BuildContext context, DateTime dateTime) =>
      formatMinutesOfDay(context, dateTime.hour * 60 + dateTime.minute);

  /// 2h 14m / 14m / 45s — compact, language-neutral units from translations.
  static String formatCompactDuration(BuildContext context, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return context.tr('duration_hours_minutes', {'h': '$hours', 'm': '$minutes'});
    if (duration.inMinutes > 0) return context.tr('duration_minutes', {'m': '${duration.inMinutes}'});
    return context.tr('duration_seconds', {'s': '${duration.inSeconds.clamp(0, 59)}'});
  }

  /// 240 → "04:00" for countdowns.
  static String formatCountdown(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Translation key for a short weekday label (1 = Monday).
  static String weekdayShortKey(int weekday) => 'weekday_short_$weekday';
  static String weekdayLongKey(int weekday) => 'weekday_long_$weekday';

  /// Greeting translation key based on the hour.
  static String greetingKey(DateTime now) {
    if (now.hour < 12) return 'greeting_morning';
    if (now.hour < 18) return 'greeting_afternoon';
    return 'greeting_evening';
  }

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  /// Initial letter for avatar bubbles.
  static String initialOf(String name) => name.trim().isEmpty ? '🙂' : name.trim().characters.first.toUpperCase();

  /// Temporary branded message (glass card, centred text, animated).
  /// Use [AppToastTone.error] for failures, [AppToastTone.success] for wins.
  static void showSnack(BuildContext context, String message, {AppToastTone tone = AppToastTone.info}) =>
      AppToast.show(context, message, tone: tone);
}
