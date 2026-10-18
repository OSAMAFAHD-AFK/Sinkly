import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/app_localizations.dart';
import '../utils/functions/app_functions.dart';
import '../utils/style.dart';
import 'custom_primary_button.dart';

/// Presents [child] inside a frosted-glass bottom sheet with a grabber.
Future<T?> showGlassBottomSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.18),
    builder: (sheetContext) => GlassBottomSheetContainer(child: builder(sheetContext)),
  );
}

class GlassBottomSheetContainer extends StatelessWidget {
  const GlassBottomSheetContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(AppRadii.large));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xEBFFFFFF),
              borderRadius: radius,
              border: Border(top: BorderSide(color: Colors.white, width: 1.5)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.inkMuted.withValues(alpha: 0.4),
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style wheel time picker in a glass sheet. Returns minutes-of-day.
Future<int?> showGlassTimePickerSheet({
  required BuildContext context,
  required String title,
  required int initialMinutesOfDay,
}) {
  return showGlassBottomSheet<int>(
    context: context,
    builder: (sheetContext) {
      var selected = initialMinutesOfDay;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(sheetContext.tr('time_picker_hint'), style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 220,
              child: _TimeWheel(
                initialMinutesOfDay: initialMinutesOfDay,
                onChanged: (minutesOfDay) => selected = minutesOfDay,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomPrimaryButton(
              label: sheetContext.tr('save'),
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(sheetContext).pop(selected),
            ),
          ],
        ),
      );
    },
  );
}

/// Hour · minute (1-minute steps) · AM/PM wheel.
///
/// Always written left-to-right with 0-9 digits (product decision), while
/// the AM/PM labels stay in the app language (ص / م in Arabic).
class _TimeWheel extends StatelessWidget {
  const _TimeWheel({required this.initialMinutesOfDay, required this.onChanged});

  final int initialMinutesOfDay;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final digits = _WesternDigitsCupertinoLocalizations(
      am: material.anteMeridiemAbbreviation,
      pm: material.postMeridiemAbbreviation,
    );
    // iOS already ticks on every row; give Android the same tactile feel.
    final tick = defaultTargetPlatform != TargetPlatform.iOS;

    return Localizations.override(
      context: context,
      delegates: [_WesternDigitsCupertinoDelegate(digits)],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              // Tabular figures: rows don't wobble sideways while spinning.
              dateTimePickerTextStyle: AppTextStyles.title.copyWith(
                fontSize: 23,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            itemExtent: 44,
            initialDateTime: DateTime(2024, 1, 1, initialMinutesOfDay ~/ 60, initialMinutesOfDay % 60),
            selectionOverlayBuilder: (context, {required selectedIndex, required columnCount}) =>
                CupertinoPickerDefaultSelectionOverlay(
                  background: AppColors.primary.withValues(alpha: 0.16),
                  capStartEdge: selectedIndex == 0,
                  capEndEdge: selectedIndex == columnCount - 1,
                ),
            onDateTimeChanged: (value) {
              if (tick) AppFunctions.selectionHaptic();
              onChanged(value.hour * 60 + value.minute);
            },
          ),
        ),
      ),
    );
  }
}

/// English Cupertino strings (0-9 digits) with the app's own AM/PM labels.
class _WesternDigitsCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _WesternDigitsCupertinoLocalizations({required this.am, required this.pm});

  final String am;
  final String pm;

  @override
  String get anteMeridiemAbbreviation => am;

  @override
  String get postMeridiemAbbreviation => pm;
}

class _WesternDigitsCupertinoDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _WesternDigitsCupertinoDelegate(this.localizations);

  final CupertinoLocalizations localizations;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => SynchronousFuture(localizations);

  @override
  bool shouldReload(_WesternDigitsCupertinoDelegate old) =>
      old.localizations.anteMeridiemAbbreviation != localizations.anteMeridiemAbbreviation ||
      old.localizations.postMeridiemAbbreviation != localizations.postMeridiemAbbreviation;
}
