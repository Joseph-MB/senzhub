import 'package:flutter/material.dart';

enum StatusTone { positive, warning, critical, neutral, info }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  Color get backgroundColor {
    switch (tone) {
      case StatusTone.positive:
        return const Color(0xFF1E8F5E).withValues(alpha: 0.18);
      case StatusTone.warning:
        return const Color(0xFFFFC857).withValues(alpha: 0.18);
      case StatusTone.critical:
        return const Color(0xFFFF5F6D).withValues(alpha: 0.18);
      case StatusTone.info:
        return const Color(0xFF5DD7FF).withValues(alpha: 0.18);
      case StatusTone.neutral:
        return const Color(0xFFB8C7C4).withValues(alpha: 0.18);
    }
  }

  Color get foregroundColor {
    switch (tone) {
      case StatusTone.positive:
        return const Color(0xFF146B48);
      case StatusTone.warning:
        return const Color(0xFF8D5A00);
      case StatusTone.critical:
        return const Color(0xFFB72637);
      case StatusTone.info:
        return const Color(0xFF0B6A84);
      case StatusTone.neutral:
        return const Color(0xFF30423F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? backgroundColor : backgroundColor.withValues(alpha: 0.12);
    final foreground = isDark ? foregroundColor : foregroundColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
