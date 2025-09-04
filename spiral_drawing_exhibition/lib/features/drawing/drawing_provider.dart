import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/algorithms/spiral_processor.dart';
import '../../core/models/drawing_config.dart';
import '../../core/utils/image_converter.dart';

/// \   (Provider (4)
/// 
/// Unity/Unreal/ProcessingX u (t:
/// 
/// 1. Unity: MonoBehaviourX Update()    l
///    Flutter: ChangeNotifier\    UI pt
/// 
/// 2. Processing:  \  
///    Flutter: 1(Immutability) Y,    notifyListeners()
/// 
/// 3. Unreal: Tick() h DeltaTime<\ `TtX
///    Flutter: AnimationController  , vsync\ 60FPS 
class DrawingProvider extends ChangeNotifier {
  // `TtX d (UnityX Animator, UnrealX Timeline  )
  AnimationController? _animationController;
  
  // t \8
  SpiralProcessor? _processor;
  
  // \ $
  DrawingConfig _config = const DrawingConfig();
  
  //  
  bool _isDrawing = false;
  bool _isPaused = false;
  double _progress = 0.0;
  
  
  // Getters
  bool get isDrawing => _isDrawing;
  bool get isPaused => _isPaused;
  double get progress => _progress;
  DrawingConfig get config => _config;
  List<SpiralPoint> get points => _processor?.points ?? [];
  int get pointCount => _processor?.pointCount ?? 0;
  
  /// 드로잉 시작
  /// Unity의 Start() 또는 Processing의 setup() 역할
  Future<void> startDrawing({
    required TickerProvider vsync,
    required Size canvasSize,
    ui.Image? sourceImage,
  }) async {
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
    
    //  \8 1
    _processor = SpiralProcessor(
      config: _config,
      canvasSize: canvasSize,
      sourceImage: processedImage,
    );
    
    // ===== ) 1:  İ () =====
    // UnityX Tt UnrealX D0 \)  
    //  D  İX `TtX 
    await _processor!.preCalculateAll();
    
    // AnimationController 1 (UnityX Animator Controller@  )
    _animationController = AnimationController(
      duration: Duration(seconds: _config.maxDuration),
      vsync: vsync,
    );
    
    // `TtX  (UnityX Update()| )
    _animationController!.addListener(_onAnimationUpdate);
    
    // `TtX D 
    _animationController!.addStatusListener(_onAnimationStatus);
    
    // `TtX ܑ
    _isDrawing = true;
    _isPaused = false;
    _animationController!.forward();
    
    notifyListeners();
  }
  
  /// `TtX pt (  8)
  /// UnityX Update()  ProcessingX draw()| 
  void _onAnimationUpdate() {
    // AnimationControllerX value 0.0 ~ 1.0
    _progress = _animationController!.value;
    
    // ===== ) 2:  İ ( ) =====
    // ProcessingX draw() h   İ
    // 1t    
    /*
    if (!_processor!.isComplete) {
      // deltaTime İ (UnityX Time.deltaTime  )
      final deltaTime = 1.0 / 60.0; // 60 FPS 
      _processor!.processFrame(deltaTime);
    }
    */
    
    // UI pt p (FlutterX u)
    // UnityX SetDirty() UnrealX MarkRenderStateDirty()@  
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
  
  /// \ |/
  /// UnityX Time.timeScale = 0  
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
    // Keep progress at 1.0 to show completed drawing
    // Don't reset to 0.0 which would clear the canvas
    
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
    
    _isDrawing = false;
    _isPaused = false;
    // Keep progress at 1.0 to show the complete drawing
    _progress = 1.0;
    
    notifyListeners();
  }
  
  /// \ $ 
  void updateConfig(DrawingConfig newConfig) {
    _config = newConfig;
    
    // ĉ x \t <t  p
    if (_isDrawing && _animationController != null) {
      // @  İ
      final remainingProgress = 1.0 - _progress;
      final remainingDuration = Duration(
        milliseconds: (newConfig.maxDuration * 1000 * remainingProgress).round(),
      );
      
      // `TtX  p (UnityX Animator.speed@  )
      _animationController!.duration = remainingDuration;
    }
    
    notifyListeners();
  }
  
  /// K 
  
  /// ĉ` M
  String get progressText => '${(_progress * 100).toInt()}%';
  
  ///  D 
  String get estimatedTimeRemaining {
    if (!_isDrawing) return '--:--';
    
    final totalSeconds = _config.maxDuration;
    final elapsedSeconds = (totalSeconds * _progress).round();
    final remainingSeconds = totalSeconds - elapsedSeconds;
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}