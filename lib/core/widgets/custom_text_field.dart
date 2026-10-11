import 'package:flutter/material.dart';

import '../utils/style.dart';
import 'custom_card_container.dart';

/// Glass text field: pill-shaped for single line, rounded card for multi-line.
/// Glows softly in sky blue while focused.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardType,
    this.prefixIcon,
    this.textAlign = TextAlign.start,
    this.textStyle,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final TextAlign textAlign;
  final TextStyle? textStyle;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_hasFocus != _focusNode.hasFocus) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines > 1;
    final radius = isMultiline ? AppRadii.cardAll : AppRadii.pillAll;

    return AnimatedContainer(
      duration: AppDurations.medium,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 26,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: CustomCardContainer(
        borderRadius: radius,
        fillColor: AppColors.glassFillStrong,
        borderColor: _hasFocus ? AppColors.primary : AppColors.glassBorder,
        borderWidth: _hasFocus ? 1.6 : 1.2,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg - 2, vertical: isMultiline ? AppSpacing.md : 4),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          maxLines: widget.maxLines,
          minLines: isMultiline ? widget.maxLines : 1,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          textAlign: widget.textAlign,
          textInputAction: widget.textInputAction ?? (isMultiline ? TextInputAction.newline : TextInputAction.done),
          textCapitalization: widget.textCapitalization,
          keyboardType: widget.keyboardType ?? (isMultiline ? TextInputType.multiline : TextInputType.text),
          style: widget.textStyle ?? AppTextStyles.bodyStrong.copyWith(fontSize: 16),
          cursorRadius: const Radius.circular(4),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
            hintMaxLines: widget.maxLines,
            border: InputBorder.none,
            counterStyle: AppTextStyles.caption.copyWith(fontSize: 11),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, color: _hasFocus ? AppColors.primaryInk : AppColors.inkMuted),
            contentPadding: EdgeInsets.symmetric(vertical: isMultiline ? 0 : 18),
          ),
        ),
      ),
    );
  }
}
