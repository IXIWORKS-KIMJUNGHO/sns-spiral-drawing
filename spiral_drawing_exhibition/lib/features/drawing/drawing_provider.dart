import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/algorithms/spiral_processor.dart';
import '../../core/models/drawing_config.dart';
import '../../core/utils/image_converter.dart';
import '../../services/settings_service.dart';

/// Drawing Provider (Provider 패턴 적용)
/// 
/// Unity/Unreal/Processing과의 비교 설명:
/// 
/// 1. Unity: MonoBehaviour의 Update()로 매 프레임 호출
///    Flutter: ChangeNotifier로 상태 변경 시 UI 업데이트
/// 
/// 2. Processing: 실시간 렌더링
///    Flutter: 불변성(Immutability) 유지, 상태 변경 시 notifyListeners()
/// 
/// 3. Unreal: Tick() 함수에서 DeltaTime으로 애니메이션
///    Flutter: AnimationController 사용, vsync로 60FPS 동기화
class DrawingProvider extends ChangeNotifier {
  // 애니메이션 컨트롤러 (Unity의 Animator, Unreal의 Timeline 역할)
  AnimationController? _animationController;
  
  // 스파이럴 프로세서
  SpiralProcessor? _processor;
  
  // 설정 정보
  DrawingConfig _config = const DrawingConfig();
  
  // 설정 서비스
  final SettingsService _settingsService = SettingsService();
  
  // 상태 변수
  bool _isDrawing = false;
  bool _isPaused = false;
  double _progress = 0.0;
  bool _isResetting = false; // 앱 재시작 중인지 추적
  
  
  // Getters
  bool get isDrawing => _isDrawing;
  bool get isPaused => _isPaused;
  double get progress => _progress;
  bool get isResetting => _isResetting;
  DrawingConfig get config => _config;
  List<SpiralPoint> get points => _processor?.points ?? [];
  int get pointCount => _processor?.pointCount ?? 0;
  
  /// 설정에서 드로잉 구성 로드
  Future<void> _loadConfigFromSettings() async {
    try {
      final savedDuration = await _settingsService.getSavedDrawingDuration();
      _config = _config.copyWith(maxDuration: savedDuration);
      
      if (kDebugMode) {
        print('✅ 설정에서 드로잉 시간 로드: ${savedDuration}초');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 설정 로드 오류, 기본값 사용: $e');
      }
      // 기본값 유지
    }
  }
  
  /// 드로잉 시작
  /// Unity의 Start() 또는 Processing의 setup() 역할
  Future<void> startDrawing({
    required TickerProvider vsync,
    required Size canvasSize,
    ui.Image? sourceImage,
  }) async {
    // 설정에서 드로잉 구성 로드
    await _loadConfigFromSettings();
    
    // Reset progress to 0 when starting new drawing
    _progress = 0.0;
    
    // 기존 애니메이션 정리
    _animationController?.dispose();
    
    // 이미지가 있으면 흑백으로 변환
    ui.Image? processedImage = sourceImage;
    if (sourceImage != null) {
      if (kDebugMode) {
        print('원본 이미지 크기: ${sourceImage.width}x${sourceImage.height}');
        print('흑백 변환 중...');
      }
      processedImage = await ImageConverter.convertToGrayscale(sourceImage);
      if (kDebugMode) {
        print('흑백 변환 완료');
      }
      
      // 선택적: 대비 향상
      if (kDebugMode) {
        print('대비 향상 중...');
      }
      processedImage = await ImageConverter.enhanceContrast(processedImage, contrastFactor: 1.8);
      if (kDebugMode) {
        print('대비 향상 완료');
      }
    }
    
    // 스파이럴 프로세서 생성
    _processor = SpiralProcessor(
      config: _config,
      canvasSize: canvasSize,
      sourceImage: processedImage,
    );
    
    // ===== 단계 1: 스파이럴 포인트 사전 계산 =====
    // Unity의 Start() 또는 Unreal의 BeginPlay()와 같은 역할
    // 실제 드로잉 전에 모든 스파이럴 포인트를 계산
    await _processor!.preCalculateAll();
    
    // AnimationController 생성 (Unity의 Animator Controller와 같은 역할)
    _animationController = AnimationController(
      duration: Duration(seconds: _config.maxDuration),
      vsync: vsync,
    );
    
    // 애니메이션 진행 상황 리스너 (Unity의 Update()와 같은 역할)
    _animationController!.addListener(_onAnimationUpdate);
    
    // 애니메이션 상태 리스너
    _animationController!.addStatusListener(_onAnimationStatus);
    
    // 애니메이션 시작
    _isDrawing = true;
    _isPaused = false;
    _animationController!.forward();
    
    notifyListeners();
  }
  
  /// 애니메이션 업데이트 (매 프레임)
  /// Unity의 Update()나 Processing의 draw()와 같은 역할
  void _onAnimationUpdate() {
    // AnimationController의 value는 0.0 ~ 1.0
    _progress = _animationController!.value;
    
    // ===== 단계 2: 실시간 렌더링 (사용하지 않음) =====
    // Processing의 draw() 함수와 같은 실시간 렌더링
    // 현재는 모든 포인트를 미리 계산하므로 사용하지 않음
    /*
    if (!_processor!.isComplete) {
      // deltaTime 기반 처리 (Unity의 Time.deltaTime과 같은 역할)
      final deltaTime = 1.0 / 60.0; // 60 FPS 기준
      _processor!.processFrame(deltaTime);
    }
    */
    
    // UI 업데이트 요청 (Flutter의 setState()와 같은 역할)
    // Unity의 SetDirty() 또는 Unreal의 MarkRenderStateDirty()와 같은 개념
    notifyListeners();
  }
  
  /// 애니메이션 상태 변경 처리
  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Animation is complete, keep progress at 1.0
      _progress = 1.0;
      _isDrawing = false;
      notifyListeners();
      
      // Don't call stopDrawing() here as it's already complete
      // Just clean up the animation controller
      if (_config.autoStop) {
        _animationController?.dispose();
        _animationController = null;
      }
    }
  }
  
  /// 일시정지/재개
  /// Unity의 Time.timeScale = 0과 같은 역할
  void togglePause() {
    if (!_isDrawing) return;
    
    if (_isPaused) {
      _animationController?.forward();
    } else {
      _animationController?.stop();
    }
    
    _isPaused = !_isPaused;
    notifyListeners();
  }
  
  /// 드로잉 정지
  void stopDrawing() {
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
    
    _isDrawing = false;
    _isPaused = false;
    
    // CRITICAL: 재시작 중이 아닐 때만 progress를 1.0으로 설정
    // 재시작 중에는 progress를 0.0으로 유지하여 Firebase 업로드 방지
    if (!_isResetting) {
      // 일반적인 드로잉 완료 시에만 1.0으로 설정
      _progress = 1.0;
    } else {
      // 재시작 중에는 0.0으로 유지
      _progress = 0.0;
    }
    
    notifyListeners();
  }
  
  /// 설정 변경
  void updateConfig(DrawingConfig newConfig) {
    _config = newConfig;
    
    // 진행 중인 애니메이션이 있으면 설정 반영
    if (_isDrawing && _animationController != null) {
      // 남은 시간 계산
      final remainingProgress = 1.0 - _progress;
      final remainingDuration = Duration(
        milliseconds: (newConfig.maxDuration * 1000 * remainingProgress).round(),
      );
      
      // 애니메이션 속도 변경 (Unity의 Animator.speed와 같은 역할)
      _animationController!.duration = remainingDuration;
    }
    
    notifyListeners();
  }
  
  /// 진행률 텍스트
  String get progressText => '${(_progress * 100).toInt()}%';
  
  /// 예상 소요 시간
  String get estimatedTimeRemaining {
    if (!_isDrawing) return '--:--';
    
    final totalSeconds = _config.maxDuration;
    final elapsedSeconds = (totalSeconds * _progress).round();
    final remainingSeconds = totalSeconds - elapsedSeconds;
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// 앱 재시작 시 모든 상태 초기화
  void resetAll() {
    // CRITICAL: 재시작 플래그를 가장 먼저 설정하여 Firebase 업로드 완전 차단
    _isResetting = true;
    
    // 애니메이션 정리 (notifyListeners 호출하지 않음)
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
    
    // 상태 완전 초기화 (Firebase 업로드 조건 모두 차단)
    _isDrawing = false;
    _isPaused = false;
    _progress = 0.0;  // 0.0으로 설정하여 업로드 조건 차단
    
    // 프로세서 초기화
    _processor = null;
    
    // 설정은 기본값으로 유지
    _config = const DrawingConfig();
    
    // 리스너에게 알림 (재시작 중이라는 정보와 progress=0.0 포함)
    notifyListeners();
    
    // 추가 안전 장치: 재시작 플래그를 약간의 지연 후 해제
    Future.delayed(const Duration(milliseconds: 100), () {
      _isResetting = false;
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}