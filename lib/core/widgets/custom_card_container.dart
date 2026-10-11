import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/style.dart';

/// The signature frosted-glass surface of Sinkly.
///
/// * Translucent white fill + subtle top-left sheen
/// * Backdrop blur (grouped for performance when inside a [BackdropGroup])
/// * 1px light inner edge and a soft, large-radius floating shadow
///
/// Set [enableBlur] to `false` for glass nested inside another glass surface
/// (avoids overlapping backdrop filters) or for very long lists.
class CustomCardContainer extends StatelessWidget {
  const CustomCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg - 4),
    this.margin,
    this.borderRadius = AppRadii.cardAll,
    this.fillColor = AppColors.glassFill,
    this.gradient,
    this.borderColor = AppColors.glassBorder,
    this.borderWidth = 1.2,
    this.shadows = AppShadows.floating,
    this.blurSigma = 22,
    this.enableBlur = true,
    this.useSharedBackdrop = true,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Color fillColor;
  final Gradient? gradient;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;
  final double blurSigma;
  final bool enableBlur;

  /// Share the page's [BackdropGroup] blur pass. Set `false` for surfaces that
  /// float OVER other glass (sticky bars, overlays) — overlapping filters must
  /// not share a backdrop key.
  final bool useSharedBackdrop;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? fillColor : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );

    if (gradient == null) {
      // Light sheen layered on top of the fill — sells the "glass" look.
      surface = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.center,
            colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)],
          ),
        ),
        child: surface,
      );
    }

    if (enableBlur) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: useSharedBackdrop
            ? BackdropFilter.grouped(
                filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: surface,
              )
            : BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: surface,
              ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: surface,
    );
  }
}
