import 'package:flutter/material.dart';

/// 카메라 영역을 제외한 리퀴드 글래스 효과를 위한 클리퍼
class CircleHoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleHoleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.fillType = PathFillType.evenOdd;
    
    // 전체 사각형 추가
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // 원형 구멍 추가
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    
    return path;
  }

  @override
  bool shouldReclip(CircleHoleClipper oldClipper) {
    return center != oldClipper.center || radius != oldClipper.radius;
  }
}