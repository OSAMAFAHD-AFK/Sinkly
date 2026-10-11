import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  SINKLY DESIGN TOKENS — the single source of truth for the visual system.
///  Change a value here and the whole app updates.
///  Style: Soft Glassmorphism + Modern Soft Minimalism (light only).
/// ─────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  /// Primary brand sky blue.
  /// Alternative calmer option to try later: Color(0xFF96CBFF)
  static const Color primary = Color(0xFF89CFF0);

  /// Slightly deeper sky used for gradients' end stop and pressed states.
  static const Color primaryDeep = Color(0xFF5DB4E6);

  /// Accessible sky used for text and icons on white (meets contrast).
  static const Color primaryInk = Color(0xFF2B8BC6);

  /// Very faint sky wash for selected backgrounds and shadows.
  static const Color primarySoft = Color(0xFFE8F6FD);

  /// Text/icon color placed ON the primary sky button.
  static const Color onPrimary = Color(0xFF0B2540);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);

  /// Translucent white used by every glass card / field.
  static const Color glassFill = Color(0xB3FFFFFF); // 70% white
  static const Color glassFillStrong = Color(0xE6FFFFFF); // 90% white
  static const Color glassBorder = Color(0x99FFFFFF); // inner light edge

  // ── Ink (text) ─────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF0F1B2D);
  static const Color inkSoft = Color(0xFF5B6B80);
  static const Color inkMuted = Color(0xFF98A4B5);
  static const Color divider = Color(0xFFEDF0F4);

  // ── Mesh gradient blobs (very light, calm) ─────────────────────────────
  static const Color meshSky = Color(0xFFD6EFFC);
  static const Color meshLavender = Color(0xFFE9E7FF);
  static const Color meshMint = Color(0xFFDFF6EE);
  static const Color meshPeach = Color(0xFFFFEEE3);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C38F);
  static const Color successSoft = Color(0xFFE3F8EF);
  static const Color warning = Color(0xFFFFB547);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color dangerSoft = Color(0xFFFFECEC);
  static const Color flame = Color(0xFFFF8A3D);
}

abstract final class AppRadii {
  static const double small = 14;
  static const double medium = 20;
  static const double card = 28;
  static const double large = 32;
  static const double pill = 100;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Horizontal page gutter used by every screen.
  static const double screenGutter = 22;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration page = Duration(milliseconds: 460);
}

abstract final class AppShadows {
  /// Large-blur, low-opacity ambient shadow that makes glass float.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1489CFF0), // faint sky
      blurRadius: 40,
      spreadRadius: -4,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x0A1F2A44), // warm ambient gray
      blurRadius: 18,
      spreadRadius: -6,
      offset: Offset(0, 6),
    ),
  ];

  /// Softer variant for small chips / list tiles.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F1F2A44), blurRadius: 22, spreadRadius: -8, offset: Offset(0, 8)),
  ];

  /// Colored glow under the sky-blue primary CTA.
  static List<BoxShadow> primaryGlow({double strength = 1}) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.55 * strength),
      blurRadius: 28,
      spreadRadius: -6,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: AppColors.primaryDeep.withValues(alpha: 0.25 * strength),
      blurRadius: 10,
      spreadRadius: -4,
      offset: const Offset(0, 4),
    ),
  ];
}

abstract final class AppGradients {
  /// Primary CTA fill: sky → slightly deeper sky.
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA6DCF5), AppColors.primary, Color(0xFF74C3EC)],
    stops: [0, 0.5, 1],
  );

  /// Thin glass sheen laid over translucent surfaces.
  static const LinearGradient glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCCFFFFFF), Color(0x80FFFFFF)],
  );

  /// Dark premium card (used sparingly, e.g. selected chip / paywall badge).
  static const LinearGradient ink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2940), Color(0xFF0F1B2D)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7FE0BC), AppColors.success],
  );

  static const LinearGradient flame = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFC36B), AppColors.flame],
  );
}

/// Typography scale. Plus Jakarta Sans gives the soft geometric feel seen in
/// the reference designs while staying highly legible.
abstract final class AppTextStyles {
  /// Plus Jakarta Sans has no Arabic glyphs, so Arabic switches to Cairo
  /// (similar geometric, friendly feel). Set by `LocaleController`.
  static bool _useArabicFont = false;
  static void configureForLanguage(String languageCode) => _useArabicFont = languageCode == 'ar';

  /// Font family name used for the global TextTheme.
  static String? get fontFamily =>
      _useArabicFont ? GoogleFonts.cairo().fontFamily : GoogleFonts.plusJakartaSans().fontFamily;

  static TextStyle _base(
    double size,
    FontWeight weight, {
    double height = 1.3,
    Color color = AppColors.ink,
    double letterSpacing = 0,
  }) {
    // Arabic letters must stay joined: no tracking, slightly taller lines.
    final style = _useArabicFont ? GoogleFonts.cairo : GoogleFonts.plusJakartaSans;
    return style(
      fontSize: size,
      fontWeight: weight,
      height: _useArabicFont ? height * 1.08 : height,
      color: color,
      letterSpacing: _useArabicFont ? 0 : letterSpacing,
    );
  }

  static TextStyle get display => _base(34, FontWeight.w800, height: 1.12, letterSpacing: -0.8);
  static TextStyle get headline => _base(27, FontWeight.w800, height: 1.18, letterSpacing: -0.5);
  static TextStyle get title => _base(20, FontWeight.w700, height: 1.25, letterSpacing: -0.2);
  static TextStyle get titleSmall => _base(16, FontWeight.w700, height: 1.3);
  static TextStyle get body => _base(15, FontWeight.w500, height: 1.5, color: AppColors.inkSoft);
  static TextStyle get bodyStrong => _base(15, FontWeight.w600, height: 1.45);
  static TextStyle get caption => _base(13, FontWeight.w500, height: 1.4, color: AppColors.inkSoft);
  static TextStyle get label => _base(12, FontWeight.w700, height: 1.2, color: AppColors.inkMuted, letterSpacing: 0.6);
  static TextStyle get button =>
      _base(16, FontWeight.w700, height: 1.2, color: AppColors.onPrimary, letterSpacing: 0.1);
  static TextStyle get statNumber => _base(40, FontWeight.w800, height: 1.0, letterSpacing: -1.2);
}
