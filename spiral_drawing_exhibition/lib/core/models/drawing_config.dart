/// 드로잉 설정 클래스
/// 나선형 드로잉의 모든 파라미터 관리
class DrawingConfig {
  // 애니메이션 설정
  final double speedMultiplier;    // 속도 배수 (0.5x ~ 3.0x)
  final int maxDuration;           // 최대 실행 시간 (초)
  final bool autoStop;              // 자동 정지 여부
  
  // 선 설정
  final double minStrokeWidth;     // 최소 선 굵기
  final double maxStrokeWidth;     // 최대 선 굵기
  final int samplingDensity;       // 샘플링 밀도 (높을수록 정밀)
  
  // 나선형 파라미터
  final double initialRadius;      // 초기 반경
  final double radiusIncrement;    // 반경 증가량
  final double degreeIncrement;    // 각도 증가량
  
  // 이미지 매핑 설정
  final double imageMappingScale;  // 이미지 매핑 스케일 (카메라/드로잉 크기 보정)
  
  // 프리셋 이름
  final String presetName;
  
  const DrawingConfig({
    this.speedMultiplier = 0.7,
    this.maxDuration = 45,
    this.autoStop = true,
    this.minStrokeWidth = 0.05,     // Ultra-thin for bright areas
    this.maxStrokeWidth = 4.0,      // Reduced for more refined appearance
    this.samplingDensity = 250,     // Higher sampling for smoother curves
    this.initialRadius = 0.2,       // Very small starting point for tight center
    this.radiusIncrement = 0.06,    // Base increment (will be dynamically adjusted)
    this.degreeIncrement = 0.04,    // Base angle (will be dynamically adjusted)
    this.imageMappingScale = 1.0,  // 새로운 크롭 방식으로 1:1 매핑 가능
    this.presetName = 'default',
  });
  
  
  /// 값 복사 및 수정
  DrawingConfig copyWith({
    double? speedMultiplier,
    int? maxDuration,
    bool? autoStop,
    double? minStrokeWidth,
    double? maxStrokeWidth,
    int? samplingDensity,
    double? initialRadius,
    double? radiusIncrement,
    double? degreeIncrement,
    double? imageMappingScale,
    String? presetName,
  }) {
    return DrawingConfig(
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      maxDuration: maxDuration ?? this.maxDuration,
      autoStop: autoStop ?? this.autoStop,
      minStrokeWidth: minStrokeWidth ?? this.minStrokeWidth,
      maxStrokeWidth: maxStrokeWidth ?? this.maxStrokeWidth,
      samplingDensity: samplingDensity ?? this.samplingDensity,
      initialRadius: initialRadius ?? this.initialRadius,
      radiusIncrement: radiusIncrement ?? this.radiusIncrement,
      degreeIncrement: degreeIncrement ?? this.degreeIncrement,
      imageMappingScale: imageMappingScale ?? this.imageMappingScale,
      presetName: presetName ?? this.presetName,
    );
  }
  
  /// Processing 스타일 동적 반경 증가량 계산
  double getAdjustedRadiusIncrement(double currentRadius, double maxRadius) {
    // 중앙에서 시작: 매우 촘촘 (radiusIncrement * 0.3)
    // 바깥쪽으로: 점점 넓어짐 (radiusIncrement * 2.0)
    final ratio = currentRadius / maxRadius;
    
    // Exponential growth for natural spiral expansion
    // Start at 30% of base increment, grow to 200%
    final multiplier = 0.3 + (1.7 * ratio * ratio);
    return radiusIncrement * multiplier;
  }
  
  /// Processing 스타일 동적 각도 증가량 계산
  double getAdjustedDegreeIncrement(double currentRadius, double maxRadius) {
    // 중앙: 작은 각도 변화 (촘촘한 회전)
    // 바깥: 큰 각도 변화 (넓은 회전)
    final ratio = currentRadius / maxRadius;
    
    // Gradual increase in angle increment
    // This maintains visual density as radius increases
    final multiplier = 0.5 + (1.5 * ratio);
    return degreeIncrement * multiplier;
  }
  
  /// 프레임당 처리할 포인트 수 계산
  int getPointsPerFrame(double currentRadius, double maxRadius) {
    // Processing 코드: (1+r/100)
    return 1 + (currentRadius / samplingDensity).floor();
  }
}