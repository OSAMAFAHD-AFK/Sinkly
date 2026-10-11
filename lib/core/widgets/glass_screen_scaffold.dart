import 'package:flutter/material.dart';

import 'mesh_gradient_background_widget.dart';

/// Base page scaffold: mesh gradient backdrop + a [BackdropGroup] so every
/// glass card on the page shares one blur pass (big perf win on iOS).
class GlassScreenScaffold extends StatelessWidget {
  const GlassScreenScaffold({
    super.key,
    required this.body,
    this.palette = MeshPalette.sky,
    this.animateBackground = false,
    this.bottomBar,
    this.useSafeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final MeshPalette palette;
  final bool animateBackground;
  final Widget? bottomBar;
  final bool useSafeArea;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: MeshGradientBackgroundWidget(palette: palette, animate: animateBackground),
          ),
          Positioned.fill(
            child: BackdropGroup(
              child: useSafeArea ? SafeArea(bottom: bottomBar == null, child: body) : body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
