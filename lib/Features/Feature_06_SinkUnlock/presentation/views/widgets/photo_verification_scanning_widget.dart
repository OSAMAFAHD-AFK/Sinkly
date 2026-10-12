import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/utils/app_localizations.dart';
import '../../../../../core/utils/style.dart';

/// Stage 3 — the captured photo inside a glass frame with a sweeping sky
/// scan line and corner brackets while verification runs.
class PhotoVerificationScanningWidget extends StatelessWidget {
  const PhotoVerificationScanningWidget({super.key, required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) => _buildContent(context, constraints.maxHeight));
  }

  Widget _buildContent(BuildContext context, double availableHeight) {
    final width = MediaQuery.sizeOf(context).width - AppSpacing.screenGutter * 2;
    // Portrait photo, but always leave room for the status text on short phones.
    final photoHeight = math.min(width * 1.1, availableHeight * 0.68);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: photoHeight,
            decoration: BoxDecoration(
              borderRadius: AppRadii.largeAll,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: AppShadows.floating,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(AppRadii.large - 4)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    // Decode at display size only — avoids huge memory spikes.
                    cacheWidth: (width * pixelRatio).round(),
                    errorBuilder: (_, _, _) => Container(color: AppColors.primarySoft),
                  ),
                  Container(color: AppColors.primary.withValues(alpha: 0.08)),
                  // Scan line
                  Align(
                    alignment: Alignment.topCenter,
                    child:
                        Container(
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0),
                                    AppColors.primary.withValues(alpha: 0.55),
                                  ],
                                ),
                                border: const Border(bottom: BorderSide(color: Colors.white, width: 2.5)),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: -70, end: photoHeight - 8, duration: 1500.ms, curve: Curves.easeInOut),
                  ),
                  const _CornerBrackets(),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.95, curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primaryInk),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(context.tr('verify_in_progress'), style: AppTextStyles.titleSmall)),
            ],
          ),
          const SizedBox(height: 4),
          Text(context.tr('verify_in_progress_hint'), textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.white, width: 4);
    Widget corner(Alignment alignment, Border border) => Align(
      alignment: alignment,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(border: border),
      ),
    );
    return Stack(
      children: [
        corner(Alignment.topLeft, const Border(top: side, left: side)),
        corner(Alignment.topRight, const Border(top: side, right: side)),
        corner(Alignment.bottomLeft, const Border(bottom: side, left: side)),
        corner(Alignment.bottomRight, const Border(bottom: side, right: side)),
      ],
    );
  }
}
