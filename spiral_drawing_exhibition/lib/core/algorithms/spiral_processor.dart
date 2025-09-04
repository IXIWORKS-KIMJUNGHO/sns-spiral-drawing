import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/drawing_config.dart';
import '../utils/image_analyzer.dart';

/// 나선형 드로잉 핵심 알고리즘 (Processing 코드 포팅)
/// 
/// Unity/Unreal/Processing의 Update/Draw 패러다임과 달리,
/// Flutter는 선언적 UI를 사용합니다:
/// - Processing: draw() 함수에서 매 프레임 그리기
/// - Unity: Update() 에서 매 프레임 계산
/// - Flutter: 상태 변화에 따라 Widget rebuild 트리거
class SpiralProcessor {
  final DrawingConfig config;
  final Size canvasSize;
  final ui.Image? sourceImage;
  ImageAnalyzer? _imageAnalyzer;
  
  // Processing 변수 매핑
  double r = 1.0;          // radius
  double degree = 0.0;     // rotation degree
  double px = 0.0, py = 0.0;           // previous point
  double cx = 0.0, cy = 0.0;           // current point
  double x = 0.0, y = 0.0;             // center point
  
  // Flutter 추가 변수
  final List<SpiralPoint> points = [];
  bool isComplete = false;
  
  SpiralProcessor({
    required this.config,
    required this.canvasSize,
    this.sourceImage,
  }) {
    // Processing setup() 함수 역할
    x = canvasSize.width / 2;
    y = canvasSize.height / 2;
    px = x + r * cos(degree);
    py = y + r * sin(degree);
    
    r = config.initialRadius;
    
    if (kDebugMode) {
      print('SpiralProcessor: 캔버스 크기 = ${canvasSize.width}x${canvasSize.height}');
      print('SpiralProcessor: 중심점 설정 = ($x, $y)');
    }
    
    // 이미지가 있으면 분석기 초기화
    if (sourceImage != null) {
      if (kDebugMode) {
        print('SpiralProcessor: 이미지 수신됨 - ${sourceImage!.width}x${sourceImage!.height}');
      }
      _imageAnalyzer = ImageAnalyzer(sourceImage!);
    } else {
      if (kDebugMode) {
        print('SpiralProcessor: 이미지 없음 - 노이즈 패턴 사용');
      }
    }
  }
  
  /// Processing의 draw() 함수를 대체하는 메서드
  /// Unity의 Update()와 유사하지만, Flutter에서는 
  /// AnimationController로 호출 빈도를 제어합니다
  void processFrame(double deltaTime) {
    if (isComplete) return;
    
    final maxRadius = canvasSize.width / 2;
    
    // Processing 코드: for (int i=0; i<(1+r/100); i++)
    // 반경이 클수록 더 많은 포인트를 그려 밀도 유지
    int pointsPerFrame = config.getPointsPerFrame(r, maxRadius);
    
    for (int i = 0; i < pointsPerFrame; i++) {
      // Processing 코드 매핑
      // degree += map(r, 0, width/2, 0.1, 0.005)
      degree += config.getAdjustedDegreeIncrement(r, maxRadius) * config.speedMultiplier;
      
      // r = r + map(r, 0, width/2, 0.1, 0.02)
      r += config.getAdjustedRadiusIncrement(r, maxRadius) * config.speedMultiplier;
      
      // 종료 조건: if (r > width/2) noLoop()
      if (r > maxRadius) {
        isComplete = true;
        break;
      }
      
      // 좌표 계산: cx = x + r*cos(degree)
      cx = x + r * cos(degree);
      cy = y + r * sin(degree);
      
      // 이미지 밝기 기반 선 굵기 계산
      double strokeWidth = _calculateStrokeWidth(cx, cy);
      
      // 포인트 저장 (Flutter는 상태 기반이므로 데이터 저장 필요)
      points.add(SpiralPoint(
        position: Offset(cx, cy),
        previousPosition: Offset(px, py),
        strokeWidth: strokeWidth,
        brightness: _getBrightness(cx, cy),
      ));
      
      // 이전 포인트 업데이트
      px = cx;
      py = cy;
    }
  }
  
  /// 모든 포인트를 미리 계산 (성능 최적화)
  /// Unity의 Start()나 Awake()에서 미리 계산하는 것과 유사
  Future<void> preCalculateAll() async {
    // 이미지 분석기 초기화
    if (_imageAnalyzer != null) {
      if (kDebugMode) {
        print('SpiralProcessor: 이미지 분석기 초기화 중...');
      }
      await _imageAnalyzer!.initialize();
      if (kDebugMode) {
        print('SpiralProcessor: 이미지 분석기 초기화 완료');
      }
    } else {
      if (kDebugMode) {
        print('SpiralProcessor: 이미지 분석기 없음');
      }
    }
    
    final maxRadius = canvasSize.width / 2;
    
    // Debug: Log initial and periodic spacing changes
    int debugCounter = 0;
    
    while (!isComplete) {
      // 각도와 반경 증가 계산
      final radiusInc = config.getAdjustedRadiusIncrement(r, maxRadius);
      final degreeInc = config.getAdjustedDegreeIncrement(r, maxRadius);
      
      degree += degreeInc;
      r += radiusInc;
      
      // Debug output every 1000 points to track spacing changes
      if (debugCounter % 1000 == 0) {
        final ratio = r / maxRadius;
        if (kDebugMode) {
          print('Point $debugCounter: r=${r.toStringAsFixed(1)}, ratio=${ratio.toStringAsFixed(2)}, radiusInc=${radiusInc.toStringAsFixed(4)}, degreeInc=${degreeInc.toStringAsFixed(4)}');
        }
      }
      debugCounter++;
      
      if (r > maxRadius) {
        isComplete = true;
        break;
      }
      
      cx = x + r * cos(degree);
      cy = y + r * sin(degree);
      
      double strokeWidth = _calculateStrokeWidth(cx, cy);
      
      points.add(SpiralPoint(
        position: Offset(cx, cy),
        previousPosition: Offset(px, py),
        strokeWidth: strokeWidth,
        brightness: _getBrightness(cx, cy),
      ));
      
      px = cx;
      py = cy;
    }
  }
  
  /// Processing의 brightness() 함수 역할
  double _getBrightness(double x, double y) {
    if (_imageAnalyzer == null) {
      // 이미지가 없으면 노이즈 패턴 (테스트용)
      return (sin(x * 0.01) * cos(y * 0.01) + 1) * 127.5;
    }
    
    // 실제 이미지의 밝기값 가져오기
    // 캔버스 좌표를 정규화된 이미지 좌표로 변환
    double normalizedX = x / canvasSize.width;
    double normalizedY = y / canvasSize.height;
    
    // Processing: brightness(img.get(int(cx), int(cy)))
    // getBrightnessNormalized already returns 0.0-1.0, multiply by 255 for 0-255 range
    double brightness = _imageAnalyzer!.getBrightnessNormalized(normalizedX, normalizedY) * 255.0;
    
    // Enhanced debugging - check if we're getting varied brightness values
    if (points.length < 20) {
      if (kDebugMode) {
        print('Point ${points.length}: pos($x, $y) norm($normalizedX, $normalizedY) -> brightness: $brightness');
      }
      
      // Sample different parts of the image to verify variation
      if (points.length == 10) {
        if (kDebugMode) {
          print('Sampling different areas:');
          print('  Top-left: ${_imageAnalyzer!.getBrightnessNormalized(0.1, 0.1) * 255}');
          print('  Center: ${_imageAnalyzer!.getBrightnessNormalized(0.5, 0.5) * 255}');
          print('  Bottom-right: ${_imageAnalyzer!.getBrightnessNormalized(0.9, 0.9) * 255}');
        }
      }
    }
    
    return brightness;
  }
  
  /// Processing의 map() 함수 역할 - 세밀한 Processing 스타일 매핑
  /// 더 섬세한 선 굵기 변화로 디테일 표현
  double _calculateStrokeWidth(double x, double y) {
    double brightness = _getBrightness(x, y);
    
    // Normalize brightness (0-255 to 0-1)
    double normalizedBrightness = brightness / 255.0;
    
    // Simple inversion - dark areas become thick lines
    double inverted = 1.0 - normalizedBrightness;
    
    // Use a gentler power curve for more natural gradation
    // Power of 1.2 preserves more midtone detail than 1.5
    double curve = pow(inverted, 1.2).toDouble();
    
    // Use config values directly for consistency
    double strokeWidth = config.minStrokeWidth + 
                        (config.maxStrokeWidth - config.minStrokeWidth) * curve;
    
    // Fine adjustments for extreme values
    if (normalizedBrightness > 0.95) {
      // Very bright areas - ultra thin
      strokeWidth = config.minStrokeWidth;
    } else if (normalizedBrightness > 0.90) {
      // Bright areas - very thin
      strokeWidth *= 0.7;
    } else if (normalizedBrightness < 0.05) {
      // Very dark areas - maximum thickness
      strokeWidth = config.maxStrokeWidth;
    } else if (normalizedBrightness < 0.10) {
      // Dark areas - near maximum
      strokeWidth = config.maxStrokeWidth * 0.9;
    }
    
    // Debug output for first few strokes
    if (points.length < 5) {
      if (kDebugMode) {
        print('Stroke ${points.length}: brightness=$brightness (${normalizedBrightness.toStringAsFixed(2)}) → width=${strokeWidth.toStringAsFixed(2)}px');
      }
    }
    
    return strokeWidth.clamp(config.minStrokeWidth, config.maxStrokeWidth);
  }
  
  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress {
    final maxRadius = canvasSize.width / 2;
    return min(r / maxRadius, 1.0);
  }
  
  /// 현재까지 계산된 포인트 수
  int get pointCount => points.length;
  
  /// 예상 총 포인트 수 (근사값)
  int get estimatedTotalPoints {
    final maxRadius = canvasSize.width / 2;
    return (maxRadius * maxRadius * 0.5).round(); // 경험적 근사값
  }
}

/// 나선형의 각 포인트
class SpiralPoint {
  final Offset position;
  final Offset previousPosition;
  final double strokeWidth;
  final double brightness;
  
  const SpiralPoint({
    required this.position,
    required this.previousPosition,
    required this.strokeWidth,
    required this.brightness,
  });
}