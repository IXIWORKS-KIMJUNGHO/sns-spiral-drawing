import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/algorithms/spiral_processor.dart';

/// CustomPainter - FlutterX T 
/// 
///  X DP:
/// - Unity: OnRenderObject()  Graphics.DrawMesh()
/// - Unreal: DrawPrimitive() 
/// - Processing: draw() h 
/// - Flutter: paint() T (GPU  Skia )
/// 
/// u (t:
/// 1. Flutter " " - 4D   Xt t \T
/// 2. Unity/Unreal@ "9" -     
/// 3. Processing@ " " -   |  
/// 4. Flutter "  " -    
class SpiralPainter extends CustomPainter {
  final List<SpiralPoint> points;
  final double progress;  // 0.0 ~ 1.0 `TtX ĉ
  final Color strokeColor;
  final bool showProgress;
  
  SpiralPainter({
    required this.points,
    required this.progress,
    this.strokeColor = Colors.black,
    this.showProgress = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // UnityX Graphics.DrawLine()t ProcessingX line()  
    // X Flutter Path| X \   t (
    
    if (points.isEmpty) return;
    
    //  X  İ (`TtX ĉ 0|)
    final pointsToDraw = (points.length * progress).floor();
    if (pointsToDraw == 0) return;
    
    // ==== ) 1:    0 (Processing |) ====
    // ProcessingX line() h@  Q
    // : 1t  (draw callt L)
    /*
    for (int i = 0; i < pointsToDraw - 1; i++) {
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = points[i].strokeWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        points[i].previousPosition,
        points[i].position,
        paint,
      );
    }
    */
    
    // ==== ) 2: Path\ \  0 (\T) ====
    // UnityX LineRenderer UnrealX Spline  
    // GPU \  X\ , `
    
    //   u0 X l\ Path 
    double currentStrokeWidth = points[0].strokeWidth;
    Path currentPath = Path()..moveTo(points[0].position.dx, points[0].position.dy);
    
    for (int i = 1; i < pointsToDraw; i++) {
      final point = points[i];
      
      //   u0 l Xt  Path ܑ
      if ((point.strokeWidth - currentStrokeWidth).abs() > 0.5) {
        //  Path 0
        _drawPath(canvas, currentPath, currentStrokeWidth);
        
        //  Path ܑ
        currentPath = Path()..moveTo(point.previousPosition.dx, point.previousPosition.dy);
        currentStrokeWidth = point.strokeWidth;
      }
      
      currentPath.lineTo(point.position.dx, point.position.dy);
    }
    
    //  Path 0
    _drawPath(canvas, currentPath, currentStrokeWidth);
    
    // ==== ĉ i \ (5X) ====
    if (showProgress && progress < 1.0) {
      _drawProgressIndicator(canvas, size, progress);
    }
  }
  
  /// Path| \  | T
  void _drawPath(Canvas canvas, Path path, double strokeWidth) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true  // Anti-aliasing for smooth edges
      ..filterQuality = FilterQuality.high;  // High quality filtering
    
    canvas.drawPath(path, paint);
  }
  
  /// ĉ i xt0 0
  void _drawProgressIndicator(Canvas canvas, Size size, double progress) {
    final progressPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // ĉ`  0
    final center = Offset(size.width - 50, 50);
    canvas.drawCircle(center, 30, progressPaint);
    
    final progressArcPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 30),
      -pi / 2,  // 12 ) ܑ
      2 * pi * progress,  // ĉ| 8 0
      false,
      progressArcPaint,
    );
    
    // |< M
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
  
  @override
  bool shouldRepaint(covariant SpiralPainter oldDelegate) {
    // FlutterX \T u:    
    // UnityX SetDirty() UnrealX MarkRenderStateDirty()@  
    
    // ĉ p   t  0
    return oldDelegate.progress != progress ||
           oldDelegate.points.length != points.length;
  }
  
  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}