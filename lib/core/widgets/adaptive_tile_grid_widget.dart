import 'package:flutter/material.dart';

import '../utils/style.dart';

/// Grid of selection tiles (apps, languages) that adapts to the device:
///
/// * two columns normally, one column when a tile would be narrower than
///   [minTileWidth] (scaled by the user's text size) — compact phones or
///   large accessibility text keep readable labels instead of "I…";
/// * tile height grows with the text size ([AppResponsive.scaledExtent]).
class AdaptiveTileGridWidget extends StatelessWidget {
  const AdaptiveTileGridWidget({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minTileWidth = 132,
    this.fixedExtent = 28,
    this.textExtent = 38,
    this.scrollable = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minTileWidth;

  /// Non-text part of the tile height (paddings, borders).
  final double fixedExtent;

  /// Text part of the tile height at 100 % text size.
  final double textExtent;

  /// `false` when the grid sits inside another scroll view.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumnsFit = constraints.maxWidth >= minTileWidth * textScale * 2 + AppSpacing.sm;
        return GridView.builder(
          shrinkWrap: true,
          physics: scrollable ? null : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: twoColumnsFit ? 2 : 1,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: AppResponsive.scaledExtent(context, fixed: fixedExtent, text: textExtent),
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
