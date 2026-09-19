import 'package:flutter/material.dart';
import 'package:stars/utils/theme.dart';

const executionMetricTextStyle = TextStyle(
  fontSize: 12,
  height: 1.2,
  fontWeight: FontWeight.w400,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Shared icon, baseline and text treatment for message and task statistics.
final class ExecutionMetric extends StatelessWidget {
  const ExecutionMetric({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = StarsDesktopTokens.of(context).secondaryText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 14,
          child: Center(child: Icon(icon, size: 14, color: color)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: executionMetricTextStyle.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
