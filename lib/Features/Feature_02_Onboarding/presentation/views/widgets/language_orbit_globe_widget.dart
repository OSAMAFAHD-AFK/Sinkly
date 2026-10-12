import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/models/supported_language_model.dart';
import '../../../../../core/utils/style.dart';
import '../../../../../core/widgets/glass_icon_orb_widget.dart';
import '../../../../../core/widgets/pulse_rings_widget.dart';

/// Screen 1 hero: a glowing globe with "hello" in every supported language
/// orbiting it in 3D-ish depth. The chip of the selected language lights up.
class LanguageOrbitGlobeWidget extends StatefulWidget {
  const LanguageOrbitGlobeWidget({super.key, required this.selectedCode});

  final String selectedCode;

  @override
  State<LanguageOrbitGlobeWidget> createState() => _LanguageOrbitGlobeWidgetState();
}

class _LanguageOrbitGlobeWidgetState extends State<LanguageOrbitGlobeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 22))
    ..repeat();

  /// Same order as [SupportedLanguageModel.all].
  static const Map<String, String> _greetings = {
    'en': 'Hello',
    'ar': 'مرحبا',
    'es': 'Hola',
    'de': 'Hallo',
    'fr': 'Bonjour',
    'pt': 'Olá',
    'ja': 'こんにちは',
    'ko': '안녕하세요',
    'it': 'Ciao',
    'hi': 'नमस्ते',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codes = SupportedLanguageModel.all.map((language) => language.code).toList(growable: false);
    return SizedBox(
      width: 330,
      height: 215,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const PulseRingsWidget(
            size: 190,
            child: GlassIconOrbWidget(icon: Icons.language_rounded, size: 84, floating: false),
          ),
          // Orbit chips: positions recomputed each frame, painted back-to-front.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final items = <({double depth, Widget widget})>[];
              for (var i = 0; i < codes.length; i++) {
                final angle = _controller.value * 2 * math.pi + i * 2 * math.pi / codes.length;
                final depth = (math.sin(angle) + 1) / 2; // 0 = far, 1 = near
                final isSelected = codes[i] == widget.selectedCode;
                final scale = 0.78 + 0.34 * depth + (isSelected ? 0.12 : 0);
                items.add((
                  depth: depth + (isSelected ? 1 : 0),
                  widget: Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(math.cos(angle) * 128, math.sin(angle) * 64 - 4),
                      child: Opacity(
                        opacity: (0.45 + 0.55 * depth).clamp(0, 1),
                        child: Transform.scale(
                          scale: scale,
                          child: Center(
                            child: _GreetingChip(text: _greetings[codes[i]] ?? '', isSelected: isSelected),
                          ),
                        ),
                      ),
                    ),
                  ),
                ));
              }
              items.sort((a, b) => a.depth.compareTo(b.depth));
              return Stack(fit: StackFit.expand, children: [for (final item in items) item.widget]);
            },
          ),
        ],
      ),
    );
  }
}

class _GreetingChip extends StatelessWidget {
  const _GreetingChip({required this.text, required this.isSelected});

  final String text;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: isSelected ? AppGradients.primaryButton : null,
        color: isSelected ? null : Colors.white.withValues(alpha: 0.92),
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: isSelected ? AppShadows.primaryGlow(strength: 0.6) : AppShadows.soft,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.onPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
