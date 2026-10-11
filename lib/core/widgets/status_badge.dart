import 'package:flutter/material.dart';

enum StatusBadgeType { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;

    switch (type) {
      case StatusBadgeType.success:
        backgroundColor = Colors.green.shade50;
        foregroundColor = Colors.green.shade800;
        break;
      case StatusBadgeType.warning:
        backgroundColor = Colors.amber.shade50;
        foregroundColor = Colors.amber.shade900;
        break;
      case StatusBadgeType.error:
        backgroundColor = Colors.red.shade50;
        foregroundColor = Colors.red.shade800;
        break;
      case StatusBadgeType.info:
        backgroundColor = Colors.blue.shade50;
        foregroundColor = Colors.blue.shade800;
        break;
      case StatusBadgeType.neutral:
        backgroundColor = Colors.grey.shade100;
        foregroundColor = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
