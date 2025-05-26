import 'package:flutter/material.dart';

class CurvedNavPainter extends CustomPainter {
  Color color;
  late double loc;
  TextDirection textDirection;
  final double indicatorSize;
  final int itemsLength;
  final double startingLoc;

  final Color indicatorColor;
  double borderRadius;

  CurvedNavPainter({
    required this.startingLoc,
    required this.itemsLength,
    required this.color,
    required this.textDirection,
    this.indicatorColor = Colors.lightBlue,
    this.indicatorSize = 5,
    this.borderRadius = 25,
  }) {
    loc = 1.0 / itemsLength * (startingLoc + 0.48);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final circlePaint =
        Paint()
          ..color = indicatorColor
          ..style = PaintingStyle.fill;

    final height = size.height;
    final width = size.width;

    const s = 0.06;
    const depth = 0.20;
    final valleyWith = indicatorSize + 5;

    // 修正loc计算，使指示器居中
    final centerLoc = 1.0 / itemsLength * (startingLoc + 0.5);
    final path =
        Path()
          // top Left Corner
          ..moveTo(0, borderRadius)
          ..quadraticBezierTo(0, 0, borderRadius, 0)
          ..lineTo(centerLoc * width - valleyWith * 2, 0)
          ..cubicTo(
            (centerLoc + s * 0.20) * size.width - valleyWith,
            size.height * 0.05,
            centerLoc * size.width - valleyWith,
            size.height * depth,
            centerLoc * size.width,
            size.height * depth,
          )
          ..cubicTo(
            centerLoc * size.width + valleyWith,
            size.height * depth,
            (centerLoc - s * 0.20) * size.width + valleyWith,
            size.height * 0.05,
            centerLoc * width + valleyWith * 2,
            0,
          )
          // top right corner
          ..lineTo(size.width - borderRadius, 0)
          ..quadraticBezierTo(width, 0, width, borderRadius)
          // bottom right corner
          ..lineTo(width, height - borderRadius)
          ..quadraticBezierTo(width, height, width - borderRadius, height)
          // bottom left corner
          ..lineTo(borderRadius, height)
          ..quadraticBezierTo(0, height, 0, height - borderRadius)
          ..close();

    canvas.drawPath(path, paint);

    // 绘制指示器，使用centerLoc而不是loc
    canvas.drawCircle(
      Offset(centerLoc * width, indicatorSize),
      indicatorSize,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}
