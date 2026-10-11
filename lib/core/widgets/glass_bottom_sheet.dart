import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/app_localizations.dart';
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
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: AppTextStyles.title.copyWith(fontSize: 22),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 5,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(sheetContext),
                  initialDateTime: DateTime(2024, 1, 1, initialMinutesOfDay ~/ 60, (initialMinutesOfDay % 60) ~/ 5 * 5),
                  onDateTimeChanged: (value) => selected = value.hour * 60 + value.minute,
                ),
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
