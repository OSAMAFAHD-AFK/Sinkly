import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'style.dart';

/// Builds the single light theme of Sinkly (no dark mode by design).
abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primaryInk,
        surface: AppColors.surface,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // iOS-style page transitions everywhere, matching the target audience.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      // google_fonts 9 builds TextTheme against the decoupled `material_ui`
      // package, so apply the family to Flutter's own TextTheme instead.
      textTheme: base.textTheme.apply(
        fontFamily: AppTextStyles.fontFamily,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryInk,
        selectionColor: AppColors.primarySoft,
        selectionHandleColor: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.divider,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: AppColors.primaryInk),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent, elevation: 0),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent, elevation: 0),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mediumAll),
      ),
    );
  }
}
