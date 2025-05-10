import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';

// 格式化时间戳
String formatTimestamp(BuildContext context, DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays > 0) {
    return '${timestamp.year}-${timestamp.month}-${timestamp.day}';
  } else if (difference.inHours > 0) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else if (difference.inMinutes > 0) {
    return S.of(context).minutesAgo(difference.inMinutes);
  } else {
    return S.of(context).justNow;
  }
}
