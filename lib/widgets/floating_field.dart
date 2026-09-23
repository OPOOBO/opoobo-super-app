import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FloatingField extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const FloatingField({
    super.key,
    required this.label,
    this.icon,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<FloatingField> createState() => _FloatingFieldState();
}

class _FloatingFieldState extends State<FloatingField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _obscured = true;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _obscured = widget.obscure;
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _focusNode,
      builder: (context, child) {
        final focused = _focusNode.hasFocus;
        final showLabel = focused || _hasText;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.surface)
                .withValues(alpha: 0.7),
            border: Border.all(
              color: focused
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.input),
              width: focused ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                const SizedBox(width: 14),
                Icon(
                  widget.icon,
                  size: 20,
                  color: focused
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground),
                ),
              ],
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Floating label
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      top: showLabel ? 8 : 18,
                      left: widget.icon != null ? 42 : 16,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.inter(
                          fontSize: showLabel ? 10 : 14,
                          fontWeight: FontWeight.w600,
                          color: focused
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.mutedForeground),
                          letterSpacing: showLabel ? 0.5 : 0,
                        ),
                        child: Text(widget.label.toUpperCase()),
                      ),
                    ),
                    // Input
                    Positioned.fill(
                      left: widget.icon != null ? 42 : 16,
                      right: widget.obscure ? 48 : 16,
                      top: showLabel ? 18 : 0,
                      bottom: showLabel ? 8 : 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: widget.keyboardType,
                        obscureText: widget.obscure && _obscured,
                        maxLines: widget.maxLines,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.obscure)
                GestureDetector(
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
