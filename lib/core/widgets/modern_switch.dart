import 'package:flutter/material.dart';

class ModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final double width;
  final double height;

  const ModernSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.activeIcon,
    this.inactiveIcon,
    this.width = 54.0,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor = activeColor ?? theme.colorScheme.primary;
    final effectiveInactiveColor =
        inactiveColor ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final effectiveThumbColor = thumbColor ?? Colors.white;

    final knobSize = height - 6.0;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        width: width,
        height: height,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? effectiveActiveColor : effectiveInactiveColor,
          border: Border.all(
            color: value
                ? effectiveActiveColor.withValues(alpha: 0.8)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: effectiveActiveColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveThumbColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      value
                          ? (activeIcon ?? Icons.check_rounded)
                          : (inactiveIcon ?? Icons.close_rounded),
                      key: ValueKey<bool>(value),
                      size: knobSize * 0.58,
                      color: value ? effectiveActiveColor : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
