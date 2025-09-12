import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../drawing/drawing_provider.dart';
import '../drawing/spiral_painter.dart';
import '../qr/qr_display_screen.dart';
import '../../services/firebase_service.dart';
import '../../widgets/liquid_glass_settings_button.dart';
import '../../widgets/upload_loading_screen.dart';
import '../setup/setup_screen.dart';

/// 카메라 캡처 화면
/// 
/// Processing의 Capture 클래스와 유사한 역할
/// 차이점: Flutter는 플랫폼별 카메라 API를 추상화한 camera 패키지 사용
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  CameraDescription? _selectedCamera;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _userInitiatedDrawing = false;  // 사용자가 직접 시작한 드로잉인지 추적
  XFile? _capturedImage;
  String? _deviceId;
  
  // 이전 세션의 카메라 정보를 저장 (앱이 실행되는 동안 유지)
  static String? _lastUsedDeviceId;
  
  // 줌 설정
  final double _currentZoomLevel = 1.5; // 1.5배 기본 줌으로 왜곡 감소
  
  // 셀프 타이머
  bool _isTimerActive = false;
  int _timerSeconds = 5;
  Timer? _captureTimer;
  Timer? _debounceTimer;
  
  // 애니메이션 컨트롤러
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 앱 시작 시 모든 상태 완전 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
      drawingProvider.resetAll();
      
      // 로컬 상태도 완전 초기화
      _capturedImage = null;
      _isCapturing = false;
      _userInitiatedDrawing = false;  // 사용자 시작 플래그도 초기화
    });
    
    _initializeCamera();
    
    // 앱 라이프사이클 감지를 위한 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
    
    // 펄스 애니메이션 초기화
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController!,
      curve: Curves.easeInOut,
    ));
    
    // 애니메이션 반복
    _pulseController!.repeat(reverse: true);
  }
  
  /// 카메라 초기화
  /// Processing: capture = new Capture(this, width, height);
  /// Flutter: CameraController 초기화
  Future<void> _initializeCamera() async {
    try {
      if (kDebugMode) { print('카메라 초기화 시작...'); }
      
      if (kDebugMode) { print('카메라 목록 조회 중...'); }
      
      // 사용 가능한 카메라 목록 가져오기
      try {
        _cameras = await availableCameras();
        if (kDebugMode) { print('카메라 조회 결과: ${_cameras?.length ?? 0}'); }
        
        // 전면 카메라만 필터링
        _cameras = _cameras?.where((camera) => 
          camera.lensDirection == CameraLensDirection.front
        ).toList();
        
        if (kDebugMode) { print('전면 카메라만 필터링: ${_cameras?.length ?? 0}개'); }
        
      } catch (e) {
        if (kDebugMode) { print('카메라 목록 조회 중 오류: $e'); }
      }
      
      if (_cameras == null || _cameras!.isEmpty) {
        if (kDebugMode) { print('에러: 전면 카메라를 찾을 수 없습니다'); }
        _showError('전면 카메라를 찾을 수 없습니다.\n\n가능한 원인:\n1. 카메라 권한이 거부되었습니다\n2. 전면 카메라가 없는 디바이스입니다\n3. 사용 중인 카메라가 다른 앱에서 점유되었습니다\n\n해결 방법:\n• 시스템 설정 > 개인정보 보호 및 보안 > 카메라에서 앱 권한을 확인하세요\n• 다른 화상통화 앱을 종료하세요');
        return;
      }
      
      // 전면 카메라 목록 디버그 출력
      if (kDebugMode) { print('사용 가능한 전면 카메라:'); }
      for (var cam in _cameras!) {
        if (kDebugMode) { print('- 이름: ${cam.name}'); }
        if (kDebugMode) { print('  ID: ${cam.name}'); }
        if (kDebugMode) { print('  렌즈 방향: ${cam.lensDirection}'); }
      }
      
      // 이전에 사용한 카메라가 있는지 확인
      if (_lastUsedDeviceId != null) {
        // 저장된 description로 카메라 찾기
        _selectedCamera = _cameras!.firstWhere(
          (camera) => camera.name == _lastUsedDeviceId,
          orElse: () => _cameras!.first, // 못 찾으면 첫 번째 카메라 사용
        );
        _deviceId = _selectedCamera!.name;
        if (kDebugMode) { print('이전 사용 카메라로 복원: ${_selectedCamera!.name}'); }
        await _initializeCameraController();
      } else {
        // 전면 카메라가 하나만 있으면 자동 선택 (다이얼로그 표시하지 않음)
        _selectedCamera = _cameras!.first;
        _deviceId = _selectedCamera!.name;
        _lastUsedDeviceId = _deviceId; // 선택한 카메라 저장
        if (kDebugMode) { print('자동 선택된 카메라: ${_selectedCamera!.name}'); }
        await _initializeCameraController();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) { print('카메라 초기화 실패:'); }
      if (kDebugMode) { print('에러: $e'); }
      if (kDebugMode) { print('스택 트레이스: $stackTrace'); }
      
      String errorMessage = '카메라 초기화 실패:\n\n';
      
      if (e.toString().contains('CameraAccessDenied')) {
        errorMessage += '카메라 접근이 거부되었습니다.\n';
        errorMessage += '시스템 설정에서 권한을 확인해주세요.';
      } else if (e.toString().contains('CameraAccessRestricted')) {
        errorMessage += '카메라 접근이 제한되었습니다.\n';
        errorMessage += '관리자에게 문의해주세요.';
      } else {
        errorMessage += '$e';
      }
      
      _showError(errorMessage);
    }
  }
  
  /// 카메라 컨트롤러 초기화
  Future<void> _initializeCameraController() async {
    if (_selectedCamera == null) return;
    
    try {
      // 기존 컨트롤러가 있다면 정리
      await _controller?.dispose();
      
      // 새 컨트롤러 생성
      _controller = CameraController(
        _selectedCamera!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      // 컨트롤러 초기화
      await _controller!.initialize();
      
      // 줌 레벨 설정 (왜곡 감소를 위한 1.5배 줌)
      await _applyZoomSettings();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (kDebugMode) { print('카메라 컨트롤러 초기화 완료: ${_selectedCamera!.name}'); }
        if (kDebugMode) { print('줌 레벨 설정: ${_currentZoomLevel}x (왜곡 감소 목적)'); }
      }
    } catch (e) {
      if (kDebugMode) { print('카메라 컨트롤러 초기화 실패: $e'); }
      _showError('카메라 연결 실패:\n$e');
    }
  }
  
  /// 줌 설정 적용
  Future<void> _applyZoomSettings() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      // 카메라가 지원하는 줌 범위 확인
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();
      
      // 안전한 줌 레벨 설정
      final safeZoomLevel = _currentZoomLevel.clamp(minZoom, maxZoom);
      
      await _controller!.setZoomLevel(safeZoomLevel);
      
      if (kDebugMode) {
        print('📷 줌 설정 완료: ${safeZoomLevel}x (최소: $minZoom, 최대: $maxZoom)');
        print('🎯 목적: 광각 렌즈 왜곡 감소');
      }
    } catch (e) {
      if (kDebugMode) { print('❌ 줌 설정 실패: $e'); }
    }
  }

  /// 셀프 타이머 시작 (5초 카운트다운)
  void _startSelfTimer() {
    if (_controller == null || !_isInitialized || _isTimerActive) {
      return;
    }
    
    // 디바운싱: 연속 클릭 방지
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      setState(() {
        _isTimerActive = true;
        _timerSeconds = 5;
      });
      
      if (kDebugMode) { print('🕒 셀프 타이머 시작: $_timerSeconds초'); }
      
      // 1초마다 카운트다운
      _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          _timerSeconds--;
        });
        
        if (kDebugMode) { print('⏰ 카운트다운: $_timerSeconds'); }
        
        // 타이머 완료 시 사진 촬영
        if (_timerSeconds <= 0) {
          timer.cancel();
          _executeCameraCapture();
        }
      });
    });
  }
  
  /// 실제 사진 촬영 실행
  Future<void> _executeCameraCapture() async {
    if (_controller == null || !_isInitialized) {
      _resetTimer();
      return;
    }
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      if (kDebugMode) { print('📸 사진 촬영 실행'); }
      
      // 사진 촬영
      final XFile photo = await _controller!.takePicture();
      
      setState(() {
        _capturedImage = photo;
        _userInitiatedDrawing = true;  // 사용자가 직접 시작한 드로잉으로 표시
      });
      
      if (kDebugMode) { print('✅ 사진 촬영 완료'); }
      
      // 바로 드로잉 화면으로 이동
      _navigateToDrawing();
      
    } catch (e) {
      if (kDebugMode) { print('❌ 사진 촬영 실패: $e'); }
      _showError('사진 촬영 실패: $e');
    } finally {
      _resetTimer();
      setState(() {
        _isCapturing = false;
      });
    }
  }
  
  /// 타이머 취소 및 리셋
  void _cancelTimer() {
    _captureTimer?.cancel();
    _resetTimer();
    if (kDebugMode) { print('🚫 타이머 취소됨'); }
  }
  
  /// 타이머 상태 리셋
  void _resetTimer() {
    setState(() {
      _isTimerActive = false;
      _timerSeconds = 5;
    });
  }
  
  /// 드로잉 화면으로 이동
  Future<void> _navigateToDrawing() async {
    if (_capturedImage == null) return;
    
    try {
      // 이미지 데이터를 ui.Image로 변환
      final bytes = await _capturedImage!.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      // 🎯 카메라 프리뷰와 동일한 영역으로 크롭 (OverflowBox 효과 고려)
      final ui.Image croppedImage = await _cropToMatchCameraPreview(originalImage);
      
      // 🔄 전면 카메라 미러 효과 보정 (좌우 반전)
      final ui.Image correctedImage = await _mirrorImageHorizontally(croppedImage);
      
      if (!mounted) return;
      
      // DrawingScreen으로 이동하면서 보정된 이미지 전달 (push 사용으로 카메라 상태 보존)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DrawingScreenWithImage(
            image: correctedImage,
            userInitiated: _userInitiatedDrawing,
            onReturnToCamera: _resetToCamera,  // 카메라로 돌아가는 콜백 전달
          ),
        ),
      );
    } catch (e) {
      _showError('이미지 처리 실패: $e');
    }
  }
  
  /// 카메라 화면으로 돌아가기 (오버레이 숨기기)
  void _resetToCamera() {
    if (mounted) {
      setState(() {
        _capturedImage = null;
        _isCapturing = false;
        _userInitiatedDrawing = false;
      });
      
      // DrawingProvider 초기화
      final drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
      drawingProvider.resetAll();
      
      if (kDebugMode) {
        print('📷 카메라 화면으로 복귀: 상태 초기화 완료');
      }
    }
  }
  
  /// 에러 메시지 표시
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // 정사각형 비율 유지: 짧은 쪽 기준으로 크기 결정
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    // 사이즈 계산 (반응형)
    final cameraSize = squareSize * 0.92; // 카메라 크기는 화면의 92%
    final fontSize = squareSize * 0.07; // 제목 폰트 크기
    final subFontSize = squareSize * 0.018; // 부제목 폰트 크기
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 전체 화면을 채우는 흰색 배경
          Container(
            width: screenWidth,
            height: screenHeight,
            color: Colors.white,
          ),
              
              // 카메라 프리뷰
              if (_deviceId != null)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bloom 효과 레이어 (가장 바깥쪽 글로우)
                      Container(
                        width: cameraSize * 1.15,
                        height: cameraSize * 1.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // 두 번째 Bloom 레이어 (부드러운 빛)
                      Container(
                        width: cameraSize * 1.08,
                        height: cameraSize * 1.08,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // Bloom 글로우 효과
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: squareSize * 0.05,
                              spreadRadius: squareSize * 0.01,
                            ),
                          ],
                        ),
                      ),
                      // 메인 카메라 컨테이너
                      Container(
                        width: cameraSize,
                        height: cameraSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: squareSize * 0.003,
                          ),
                          boxShadow: [
                            // 강한 플로팅 그림자
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: squareSize * 0.15,
                              spreadRadius: squareSize * 0.04,
                              offset: Offset(0, squareSize * 0.04),
                            ),
                            // 중간 그림자
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: squareSize * 0.08,
                              spreadRadius: squareSize * 0.01,
                              offset: Offset(0, squareSize * 0.025),
                            ),
                            // 가까운 그림자
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: squareSize * 0.04,
                              spreadRadius: 0,
                              offset: Offset(0, squareSize * 0.01),
                            ),
                            // 상단 하이라이트 (빛 반사)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: squareSize * 0.02,
                              spreadRadius: -squareSize * 0.01,
                              offset: Offset(0, -squareSize * 0.005),
                            ),
                          ],
                        ),
                        child: ClipOval(  // 원형으로 클립
                          child: (_controller != null && _isInitialized)
                              ? OverflowBox(
                                  alignment: Alignment.center,
                                  child: AspectRatio(
                                    aspectRatio: _controller!.value.aspectRatio,
                                    child: CameraPreview(_controller!),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: squareSize * 0.08,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        SizedBox(height: squareSize * 0.02),
                                        Text(
                                          '카메라 연결 대기 중',
                                          style: TextStyle(
                                            fontSize: subFontSize * 0.8,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: squareSize * 0.02),
                      Text(
                        '카메라 초기화 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: subFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // 상단 타이틀
              Positioned(
                top: squareSize * 0.15,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'ALL IN',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Futura',
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: squareSize * 0.01),
                    Text(
                      '화면을 보고 포즈를 취해주세요',
                      style: TextStyle(
                        fontSize: subFontSize,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 촬영 버튼
              Positioned(
                bottom: squareSize * 0.08,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      // 카운트다운이나 안내 메시지
                      if (_isCapturing)
                        Text(
                          '촬영 중...',
                          style: TextStyle(
                            fontSize: subFontSize * 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      SizedBox(height: squareSize * 0.02),
                      // 셔터 버튼 - 리퀴드 글래스 디자인 with 펄스 애니메이션
                      _pulseAnimation != null ? AnimatedBuilder(
                        animation: _pulseAnimation!,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // 펄스 효과 링
                              if (_isInitialized && !_isCapturing && _capturedImage == null)
                                Container(
                                  width: squareSize * 0.12 * _pulseAnimation!.value,
                                  height: squareSize * 0.12 * _pulseAnimation!.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.3 * (2.0 - _pulseAnimation!.value)),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              // 메인 버튼
                              GestureDetector(
                                onTap: _isInitialized && !_isCapturing && !_isTimerActive ? _startSelfTimer : null,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                            // 블러 배경 효과
                            ClipOval(
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: squareSize * 0.12,
                                  height: squareSize * 0.12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // 반투명 글래스 효과
                                    color: _isInitialized && !_isCapturing
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15),
                                    // 얇은 테두리
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                    // 그라디언트 오버레이
                                    gradient: RadialGradient(
                                      center: Alignment(-0.3, -0.3),
                                      radius: 0.8,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.white.withValues(alpha: 0.1),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 카메라 아이콘
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: squareSize * 0.05,
                                        color: _isInitialized && !_isCapturing 
                                          ? Colors.black.withValues(alpha: 0.6)
                                          : Colors.grey.withValues(alpha: 0.4),
                                      ),
                                      // 상단 하이라이트
                                      Positioned(
                                        top: squareSize * 0.01,
                                        child: Container(
                                          width: squareSize * 0.06,
                                          height: squareSize * 0.025,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(squareSize * 0.02),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withValues(alpha: 0.5),
                                                Colors.white.withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 외부 그림자 효과
                            Positioned(
                              child: Container(
                                width: squareSize * 0.12,
                                height: squareSize * 0.12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: squareSize * 0.03,
                                      spreadRadius: squareSize * 0.005,
                                      offset: Offset(0, squareSize * 0.01),
                                    ),
                                  ],
                                ),
                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ) : Stack(
                        alignment: Alignment.center,
                        children: [
                          // 메인 버튼 (애니메이션 없이)
                          GestureDetector(
                            onTap: _isInitialized && !_isCapturing && !_isTimerActive ? _startSelfTimer : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 블러 배경 효과
                                ClipOval(
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      width: squareSize * 0.12,
                                      height: squareSize * 0.12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isInitialized && !_isCapturing
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          width: 1.5,
                                        ),
                                        gradient: RadialGradient(
                                          center: Alignment(-0.3, -0.3),
                                          radius: 0.8,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.3),
                                            Colors.white.withValues(alpha: 0.1),
                                            Colors.transparent,
                                          ],
                                          stops: [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_rounded,
                                            size: squareSize * 0.05,
                                            color: _isInitialized && !_isCapturing 
                                              ? Colors.black.withValues(alpha: 0.6)
                                              : Colors.grey.withValues(alpha: 0.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: squareSize * 0.015),
                      // 화살표와 안내 텍스트
                      _pulseAnimation != null ? AnimatedBuilder(
                        animation: _pulseAnimation!,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -5 * (1.2 - _pulseAnimation!.value)),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: squareSize * 0.03,
                                  color: Colors.white,
                                ),
                                SizedBox(height: squareSize * 0.005),
                                Text(
                                  '여기를 탭하여 촬영',
                                  style: TextStyle(
                                    fontSize: subFontSize * 1.1,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ) : Text(
                        '여기를 탭하여 촬영',
                        style: TextStyle(
                          fontSize: subFontSize * 1.1,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 타이머 카운트다운 오버레이
              if (_isTimerActive)
                Center(
                  child: Container(
                    width: squareSize * 0.25,
                    height: squareSize * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.8),
                      border: Border.all(
                        color: Colors.red,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_timerSeconds',
                          style: TextStyle(
                            fontSize: squareSize * 0.08,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelTimer,
                          child: Container(
                            margin: EdgeInsets.only(top: squareSize * 0.02),
                            padding: EdgeInsets.symmetric(
                              horizontal: squareSize * 0.015,
                              vertical: squareSize * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontSize: squareSize * 0.02,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // 설정 버튼 (리퀴드 글래스 디자인)
              PositionedSettingsButton(
                top: squareSize * 0.04,
                right: squareSize * 0.04,
                size: squareSize * 0.06,
                backgroundColor: Colors.white,
                iconColor: Colors.black.withValues(alpha: 0.8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SetupScreen()),
                  );
                },
              ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // 타이머 정리
    _captureTimer?.cancel();
    _debounceTimer?.cancel();
    
    // 앱 라이프사이클 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);
    
    // 애니메이션 및 카메라 컨트롤러 정리
    _pulseController?.dispose();
    _controller?.dispose();
    super.dispose();
  }
  
  /// 앱 라이프사이클 변경 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 카메라 컨트롤러가 없으면 처리하지 않음
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    switch (state) {
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 갈 때 카메라 일시 정지
        if (kDebugMode) { print('🔄 앱 백그라운드: 카메라 일시 정지'); }
        break;
        
      case AppLifecycleState.resumed:
        // 앱이 다시 활성화될 때 카메라 상태 확인 및 복구
        if (kDebugMode) { print('🔄 앱 포그라운드: 카메라 상태 확인'); }
        _checkAndRecoverCamera();
        break;
        
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 다른 상태들은 특별한 처리 없음
        break;
    }
  }
  
  /// 카메라 상태 확인 및 복구
  Future<void> _checkAndRecoverCamera() async {
    if (!mounted) return;
    
    try {
      // 카메라 컨트롤러가 여전히 초기화되어 있는지 확인
      if (_controller != null && _controller!.value.isInitialized) {
        // 줌 레벨 재적용 (QR 화면에서 돌아온 후 복구)
        await _applyZoomSettings();
        if (kDebugMode) { print('✅ 카메라 상태 정상: 줌 레벨 재적용 완료'); }
      } else {
        // 카메라가 비정상 상태면 재초기화
        if (kDebugMode) { print('⚠️ 카메라 상태 이상: 재초기화 필요'); }
        await _initializeCameraController();
      }
    } catch (e) {
      if (kDebugMode) { print('❌ 카메라 복구 실패: $e'); }
    }
  }
  
  /// 🎯 크롭 없이 원본 이미지 그대로 반환
  /// 크롭하지 않고 촬영된 이미지를 그대로 사용
  Future<ui.Image> _cropToMatchCameraPreview(ui.Image image) async {
    if (kDebugMode) {
      print('🎯 원본 이미지 그대로 사용 (크롭 없음)');
      print('이미지 크기: ${image.width}x${image.height}');
    }
    
    // 크롭 없이 원본 이미지 그대로 반환
    return image;
  }
  
  /// 실제 이미지 크롭을 수행하는 공통 함수
  Future<ui.Image> _performImageCrop(ui.Image image, int cropX, int cropY, int cropWidth, int cropHeight) async {
    // 원본 이미지의 픽셀 데이터 가져오기
    final ByteData? originalData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (originalData == null) {
      if (kDebugMode) { print('❌ 이미지 데이터 가져오기 실패'); }
      return image;
    }
    
    // 크롭된 이미지용 버퍼 생성
    final Uint8List croppedPixels = Uint8List(cropWidth * cropHeight * 4);
    
    // 크롭 영역 추출
    for (int row = 0; row < cropHeight; row++) {
      for (int col = 0; col < cropWidth; col++) {
        // 원본 이미지에서의 좌표 (경계 체크)
        final int sourceX = (cropX + col).clamp(0, image.width - 1);
        final int sourceY = (cropY + row).clamp(0, image.height - 1);
        
        // 픽셀 인덱스 계산
        final int sourceIndex = (sourceY * image.width + sourceX) * 4;
        final int targetIndex = (row * cropWidth + col) * 4;
        
        // RGBA 값 복사
        croppedPixels[targetIndex] = originalData.getUint8(sourceIndex);     // R
        croppedPixels[targetIndex + 1] = originalData.getUint8(sourceIndex + 1); // G
        croppedPixels[targetIndex + 2] = originalData.getUint8(sourceIndex + 2); // B
        croppedPixels[targetIndex + 3] = originalData.getUint8(sourceIndex + 3); // A
      }
    }
    
    // 크롭된 이미지 생성
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      croppedPixels,
      cropWidth,
      cropHeight,
      ui.PixelFormat.rgba8888,
      (ui.Image result) {
        completer.complete(result);
      },
    );
    
    return completer.future;
  }
  
  /// 기존 정사각형 크롭 함수 (호환성 유지 - 현재 미사용)
  // ignore: unused_element
  Future<ui.Image> _cropToSquare(ui.Image image) async {
    final int width = image.width;
    final int height = image.height;
    
    // 정사각형 크기 결정 (짧은 쪽 기준)
    final int squareSize = width < height ? width : height;
    
    // 크롭 시작 좌표 계산 (중앙 정렬)
    final int x = (width - squareSize) ~/ 2;
    final int y = (height - squareSize) ~/ 2;
    
    if (kDebugMode) { 
      print('기존 정사방형 크롭: ${width}x$height → ${squareSize}x$squareSize at ($x, $y)'); 
    }
    
    return _performImageCrop(image, x, y, squareSize, squareSize);
  }
  
  /// 🔄 이미지를 수평으로 뒤집기 (전면 카메라 미러 효과 보정)
  Future<ui.Image> _mirrorImageHorizontally(ui.Image image) async {
    final int width = image.width;
    final int height = image.height;
    
    if (kDebugMode) { 
      print('🔄 Mirroring image horizontally: ${width}x$height'); 
    }
    
    // 원본 이미지의 픽셀 데이터 가져오기
    final ByteData? originalData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (originalData == null) {
      if (kDebugMode) { print('❌ Failed to get image data for mirroring'); }
      return image; // 실패시 원본 반환
    }
    
    final Uint8List originalPixels = originalData.buffer.asUint8List();
    final Uint8List mirroredPixels = Uint8List(originalPixels.length);
    
    // 픽셀 데이터를 수평으로 뒤집기
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int originalIndex = (y * width + x) * 4;
        final int mirroredIndex = (y * width + (width - 1 - x)) * 4; // X 좌표 반전
        
        // RGBA 픽셀 복사
        for (int i = 0; i < 4; i++) {
          mirroredPixels[mirroredIndex + i] = originalPixels[originalIndex + i];
        }
      }
    }
    
    // 뒤집힌 픽셀 데이터로 새 이미지 생성
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      mirroredPixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image result) {
        if (kDebugMode) { print('✅ Image mirroring completed'); }
        completer.complete(result);
      },
    );
    
    return completer.future;
  }
}

/// 이미지를 포함한 드로잉 화면
/// DrawingScreen을 확장하여 이미지 데이터 전달
class DrawingScreenWithImage extends StatefulWidget {
  final ui.Image image;
  final bool userInitiated; // 사용자가 직접 시작한 드로잉인지 추적
  final VoidCallback? onReturnToCamera; // 카메라로 돌아가는 콜백
  
  const DrawingScreenWithImage({
    super.key,
    required this.image,
    this.userInitiated = false,  // 기본값은 false (자동 시작 방지)
    this.onReturnToCamera,
  });
  
  @override
  State<DrawingScreenWithImage> createState() => _DrawingScreenWithImageState();
}

class _DrawingScreenWithImageState extends State<DrawingScreenWithImage> 
    with TickerProviderStateMixin {
  
  // RepaintBoundary를 위한 GlobalKey
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isProcessing = false; // 중복 처리 방지
  
  // Provider 참조를 안전하게 저장
  DrawingProvider? _drawingProvider;
  
  // 워터마크 이미지
  ui.Image? _watermarkImage;
  
  // 🔧 스마트 로깅을 위한 이전 상태 저장
  double _lastLoggedProgress = -1;
  bool _lastLoggedIsDrawing = false;
  bool _lastLoggedIsResetting = false;
  bool _lastLoggedIsProcessing = false;
  bool _lastLoggedUserInitiated = false;
  
  @override
  void initState() {
    super.initState();
    
    // 🔒 위젯 초기화 시 처리 상태 리셋 (앱 재시작 시 안전장치)
    _isProcessing = false;
    
    // 워터마크 이미지 로드
    _loadWatermarkImage();
    
    // 사용자가 직접 시작한 경우에만 드로잉 시작
    if (widget.userInitiated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDrawingWithImage();
      });
    } else {
      if (kDebugMode) { 
        print('DrawingScreenWithImage: 사용자가 직접 시작하지 않은 드로잉이므로 자동 시작하지 않음'); 
      }
    }
  }
  
  /// 워터마크 이미지 로드
  Future<void> _loadWatermarkImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/watermark.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      setState(() {
        _watermarkImage = fi.image;
      });
      if (kDebugMode) {
        print('🏷️ 워터마크 이미지 로드 완료: ${fi.image.width}x${fi.image.height}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 워터마크 이미지 로드 실패: $e');
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Provider 참조를 안전하게 저장하고 리스너 등록
    if (_drawingProvider == null) {
      _drawingProvider = context.read<DrawingProvider>();
      _drawingProvider!.addListener(_onDrawingStateChanged);
    }
  }
  
  @override
  void dispose() {
    // 안전하게 리스너 해제
    _drawingProvider?.removeListener(_onDrawingStateChanged);
    super.dispose();
  }
  
  void _onDrawingStateChanged() async {
    // Widget이 dispose된 상태에서는 실행하지 않음
    if (!mounted || _drawingProvider == null) return;
    
    final provider = _drawingProvider!;
    
    // === 🔧 스마트 디버깅: 상태 변화가 있을 때만 전체 로그 출력 ===
    if (kDebugMode) {
      final currentProgress = provider.progress;
      final currentIsDrawing = provider.isDrawing;
      final currentIsResetting = provider.isResetting;
      final currentIsProcessing = _isProcessing;
      final currentUserInitiated = widget.userInitiated;
      
      // 진행률만 변경된 경우 (다른 상태는 동일)
      final progressOnlyChange = 
          currentIsDrawing == _lastLoggedIsDrawing &&
          currentIsResetting == _lastLoggedIsResetting &&
          currentIsProcessing == _lastLoggedIsProcessing &&
          currentUserInitiated == _lastLoggedUserInitiated &&
          _lastLoggedProgress != -1; // 최초 실행이 아닌 경우
      
      if (progressOnlyChange && currentIsDrawing) {
        // 진행률만 변경된 경우: 10% 단위로만 업데이트 출력 (스팸 방지)
        final currentProgressPercent = (currentProgress * 100).round();
        final lastProgressPercent = (_lastLoggedProgress * 100).round();
        
        if ((currentProgressPercent ~/ 10) != (lastProgressPercent ~/ 10) || 
            (currentProgressPercent >= 100 && lastProgressPercent < 100)) {
          print('📊 Drawing Progress: $currentProgressPercent%');
        }
      } else {
        // 상태 변화가 있는 경우: 전체 상세 로그 출력
        print('=== _onDrawingStateChanged 호출됨 ===');
        print('mounted: $mounted');
        print('provider.progress: ${currentProgress.toStringAsFixed(4)}');
        print('provider.isDrawing: $currentIsDrawing');
        print('provider.isResetting: $currentIsResetting');
        print('_isProcessing: $currentIsProcessing');
        print('widget.userInitiated: $currentUserInitiated');
        print('==========================================');
      }
      
      // 현재 상태를 다음 비교를 위해 저장
      _lastLoggedProgress = currentProgress;
      _lastLoggedIsDrawing = currentIsDrawing;
      _lastLoggedIsResetting = currentIsResetting;
      _lastLoggedIsProcessing = currentIsProcessing;
      _lastLoggedUserInitiated = currentUserInitiated;
    }
    
    // 앱 재시작 중이거나 사용자가 직접 시작하지 않은 경우 업로드하지 않음
    if (provider.isResetting) {
      if (kDebugMode) { print('🚫 DrawingProvider 재시작 중이므로 Firebase 업로드 건너뛰기'); }
      return;
    }
    
    // 드로잉이 완료되고 사용자가 직접 시작한 경우에만 업로드 (자동 재시작 시 업로드 방지)
    if (provider.progress >= 1.0 && !provider.isDrawing && !_isProcessing && widget.userInitiated) {
      _isProcessing = true; // 중복 처리 방지
      
      // 약간의 딜레이 후 처리 (애니메이션 완료 대기)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 🔒 이중 안전장치: 딜레이 후 조건 재확인 (레이스 컨디션 방지)
      if (!mounted) {
        _isProcessing = false;
        return;
      }
      
      final currentProvider = context.read<DrawingProvider>();
      if (currentProvider.progress < 1.0 || 
          currentProvider.isDrawing || 
          currentProvider.isResetting ||
          !widget.userInitiated) {
        // 조건이 변경되었으므로 업로드 취소
        if (kDebugMode) {
          print('🚫 업로드 조건 변경됨 - 업로드 취소');
          print('현재 progress: ${currentProvider.progress}');
          print('현재 isDrawing: ${currentProvider.isDrawing}');
          print('현재 isResetting: ${currentProvider.isResetting}');
          print('현재 userInitiated: ${widget.userInitiated}');
        }
        _isProcessing = false;
        return;
      }
      
      if (kDebugMode) {
        print('✅ 이중 안전장치 통과 - Firebase 업로드 진행');
      }
      
      try {
        if (mounted) {
          // 로딩 화면과 함께 업로드 진행
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadProgressManager(
                minimumLoadingTime: const Duration(seconds: 2), // 최소 2초 로딩 화면 표시
                uploadTask: () async {
                  // 1. 캔버스를 이미지로 변환
                  final imageBytes = await _captureCanvasAsImage();
                  
                  if (imageBytes != null) {
                    // 2. Firebase에 업로드
                    if (kDebugMode) { print('===== Firebase 상태 체크 ====='); }
                    if (kDebugMode) { print('Firebase 앱 초기화 상태: ${Firebase.apps.isNotEmpty}'); }
                    if (Firebase.apps.isNotEmpty) {
                      if (kDebugMode) { print('Firebase 앱 이름: ${Firebase.apps.first.name}'); }
                      if (kDebugMode) { print('Firebase 프로젝트 ID: ${Firebase.apps.first.options.projectId}'); }
                    }
                    if (kDebugMode) { print('==========================='); }
                    
                    final firebaseService = FirebaseService();
                    if (kDebugMode) { print('FirebaseService 인스턴스 생성 완료'); }
                    
                    final result = await firebaseService.uploadArtwork(imageBytes);
                    if (kDebugMode) { print('uploadArtwork 호출 완료: $result'); }
                    
                    return result;
                  } else {
                    throw Exception('이미지 캡처 실패');
                  }
                },
                onUploadComplete: (result) {
                  if (mounted) {
                    // 성공적으로 업로드 완료되면 처리 상태 리셋
                    setState(() {
                      _isProcessing = false;
                    });
                    
                    // 로딩 화면을 닫고 QR 화면으로 이동
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QRDisplayScreen(
                          imageUrl: result['url']!,
                          artworkId: result['artworkId']!,
                          // onComplete 콜백으로 카메라 복귀 처리 + 드로잉 상태 초기화
                          onComplete: () {
                            // QR 화면에서 popUntil로 모든 화면이 닫혔으므로 상태 초기화만 수행
                            if (!mounted) return;
                            
                            try {
                              // 저장된 DrawingProvider 참조 사용하여 상태 초기화
                              if (_drawingProvider != null) {
                                _drawingProvider!.resetAll();
                                
                                if (kDebugMode) {
                                  print('🔄 카메라로 복귀 완료: DrawingProvider 상태 초기화됨');
                                  print('📷 모든 오버레이 제거됨 - 카메라 화면 표시 중');
                                }
                              }
                              
                              // 카메라 상태도 초기화
                              setState(() {
                                // 캡처 관련 상태 초기화 (필요시)
                              });
                            } catch (e) {
                              if (kDebugMode) {
                                print('⚠️ 상태 초기화 중 오류 (무시됨): $e');
                              }
                            }
                          },
                        ),
                        settings: const RouteSettings(name: '/qr'),
                      ),
                    );
                  }
                },
                onUploadError: (error) {
                  if (mounted) {
                    // 에러 발생 시 처리 상태 리셋
                    setState(() {
                      _isProcessing = false;
                    });
                    
                    // 로딩 화면을 닫고 에러 표시
                    Navigator.of(context).pop();
                    
                    String errorMessage = 'Firebase 업로드 실패:\n';
                    if (error.contains('Firebase')) {
                      errorMessage += '⚠️ Firebase 초기화 문제일 수 있습니다\n';
                    }
                    errorMessage += error;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
              ),
              settings: const RouteSettings(name: '/upload-loading'),
            ),
          );
        }
      } catch (e, stackTrace) {
        if (kDebugMode) { print('===== Firebase 오류 상세 정보 ====='); }
        if (kDebugMode) { print('오류 타입: ${e.runtimeType}'); }
        if (kDebugMode) { print('오류 메시지: $e'); }
        if (kDebugMode) { print('스택 트레이스:\n$stackTrace'); }
        if (kDebugMode) { print('================================='); }
        
        // 에러 발생 시에도 처리 상태 리셋
        _isProcessing = false;
        
        // 에러를 화면에 표시 (더 자세한 정보 포함)
        if (mounted) {
          String errorMessage = 'Firebase 업로드 실패:\n';
          if (e.toString().contains('Firebase')) {
            errorMessage += '⚠️ Firebase 초기화 문제일 수 있습니다\n';
          }
          errorMessage += e.toString();
          
          // Widget 상태 안전성 재확인 후 스낵바 표시 (다음 프레임에서 실행)
          if (mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 8),
                  ),
                );
              }
            });
          }
          
          // 3초 후 카메라로 돌아가기
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/camera');
            }
          });
        }
      }
    }
  }
  
  /// 🏷️ 워터마크 추가 (이미지 기반)
  void _addWatermark(Canvas canvas, double width, double height) {
    if (_watermarkImage == null) {
      if (kDebugMode) {
        print('⚠️ 워터마크 이미지가 로드되지 않았습니다.');
      }
      return;
    }
    
    // 워터마크 이미지 크기 계산 (원본 비율 유지)
    final watermarkWidth = _watermarkImage!.width.toDouble();
    final watermarkHeight = _watermarkImage!.height.toDouble();
    
    // 타겟 너비를 캔버스 너비의 100%로 설정
    // 캔버스 전체 너비에 맞춤
    final targetWidth = width * 1.0;
    final scale = targetWidth / watermarkWidth;
    final targetHeight = watermarkHeight * scale;
    
    // 위치 계산 (중앙 하단)
    final margin = height * 0.02; // 2% 여백 (더 아래로 위치)
    final xPosition = (width - targetWidth) / 2; // 중앙 정렬
    final yPosition = height - targetHeight - margin; // 하단 여백
    
    // 워터마크 그리기
    final srcRect = Rect.fromLTWH(0, 0, watermarkWidth, watermarkHeight);
    final dstRect = Rect.fromLTWH(xPosition, yPosition, targetWidth, targetHeight);
    
    // 반투명 효과 적용 (선택사항)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9); // 90% 불투명도
    
    canvas.drawImageRect(_watermarkImage!, srcRect, dstRect, paint);
    
    if (kDebugMode) {
      print('🏷️ 워터마크 이미지 추가됨');
      print('   캔버스 크기: ${width.toInt()}x${height.toInt()}');
      print('   워터마크 원본: ${watermarkWidth.toInt()}x${watermarkHeight.toInt()}');
      print('   워터마크 표시: ${targetWidth.toInt()}x${targetHeight.toInt()}');
      print('   위치: (${xPosition.toInt()}, ${yPosition.toInt()})');
      print('   스케일: ${(scale * 100).toInt()}% (캔버스의 100%)');
    }
  }
  
  /// 캔버스를 이미지로 변환 (검정 배경 추가)
  Future<Uint8List?> _captureCanvasAsImage() async {
    try {
      // RepaintBoundary를 통해 캔버스 캡처
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      // 이미지로 변환 (디바이스 픽셀 비율 적용)
      final image = await boundary.toImage(pixelRatio: 3.0);
      
      // 검정 배경을 추가하기 위해 새로운 캔버스 생성
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 흰 배경 그리기
      canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Paint()..color = Colors.white,
      );
      
      // 원본 이미지 그리기 (흰색 선)
      canvas.drawImage(image, Offset.zero, Paint());
      
      // 🏷️ 워터마크 추가 (오른쪽 하단 - 원형 영역 밖)
      _addWatermark(canvas, image.width.toDouble(), image.height.toDouble());
      
      // 새로운 이미지 생성
      final newImage = await recorder.endRecording().toImage(image.width, image.height);
      
      // PNG 형식으로 바이트 데이터 변환
      final byteData = await newImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      
      return byteData.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) { print('캔버스 캡처 실패: $e'); }
      return null;
    }
  }
  
  void _startDrawingWithImage() async {
    final provider = context.read<DrawingProvider>();
    
    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // 정사각형 비율 유지: 짧은 쪽 기준으로 크기 결정
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    final canvasSize = squareSize * 0.92; // 캔버스 크기는 화면의 92%
    
    if (kDebugMode) { print('DrawingScreenWithImage: 이미지 크기 = ${widget.image.width}x${widget.image.height}'); }
    if (kDebugMode) { print('DrawingScreenWithImage: 캔버스 크기 = ${canvasSize}x$canvasSize'); }
    
    // 이미지와 함께 드로잉 시작 (동적 캔버스 크기 사용)
    await provider.startDrawing(
      vsync: this,
      canvasSize: Size(canvasSize, canvasSize),
      sourceImage: widget.image, // 캡처한 이미지 전달
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // 정사각형 비율 유지: 짧은 쪽 기준으로 크기 결정
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    // 패딩 및 사이즈 계산 (반응형)
    final canvasSize = squareSize * 0.92; // 캔버스 크기는 화면의 92%
    final fontSize = squareSize * 0.07; // 제목 폰트 크기
    
    // DrawingScreen의 UI를 직접 구현 (중복 초기화 방지)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DrawingProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // 전체 화면을 채우는 흰색 배경
              Container(
                width: screenWidth,
                height: screenHeight,
                color: Colors.white,
              ),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bloom 효과 레이어 (가장 바깥쪽 글로우)
                    Container(
                      width: canvasSize * 1.15,
                      height: canvasSize * 1.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    // 두 번째 Bloom 레이어 (부드러운 빛)
                    Container(
                      width: canvasSize * 1.08,
                      height: canvasSize * 1.08,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Bloom 글로우 효과
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // 원형 드로잉 캔버스
                    Container(
                      width: canvasSize,
                      height: canvasSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          // 메인 그림자
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                          // 부드러운 그림자
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 60,
                            spreadRadius: 10,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        // RepaintBoundary로 감싸서 캔버스 캡처 가능하게 함
                        child: RepaintBoundary(
                          key: _repaintBoundaryKey,
                          child: CustomPaint(
                            painter: SpiralPainter(
                              points: provider.points,
                              progress: provider.progress,
                              showProgress: true,
                            ),
                            size: Size(canvasSize, canvasSize),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 다시 시작 버튼 (진행 중에만 표시)
              if (provider.isDrawing && provider.progress > 0 && provider.progress < 1.0)
                Positioned(
                  bottom: squareSize * 0.08,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        // 드로잉을 중단하고 카메라 화면으로 돌아가기
                        provider.stopDrawing();
                        
                        // 오버레이 방식으로 카메라로 돌아가기
                        if (widget.onReturnToCamera != null) {
                          Navigator.of(context).pop(); // 드로잉 화면 닫기
                          widget.onReturnToCamera!(); // 카메라 상태 초기화
                        } else {
                          Navigator.pushReplacementNamed(context, '/camera');
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 리퀴드 글래스 효과 배경
                          Container(
                            width: canvasSize * 0.25,  // 0.35 -> 0.25로 축소
                            height: canvasSize * 0.08,  // 0.12 -> 0.08로 축소
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(canvasSize * 0.04),  // 0.06 -> 0.04로 축소
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.9),
                                  Colors.white.withValues(alpha: 0.7),
                                ],
                              ),
                              boxShadow: [
                                // 외부 그림자
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 8),
                                ),
                                // 내부 글로우
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: -5,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(canvasSize * 0.04),  // 0.06 -> 0.04로 축소
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(canvasSize * 0.04),  // 0.06 -> 0.04로 축소
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.15),
                                        Colors.white.withValues(alpha: 0.05),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.black87,
                                          size: fontSize * 0.25,  // 0.35 -> 0.25로 축소
                                        ),
                                        SizedBox(width: fontSize * 0.1),  // 0.15 -> 0.1로 축소
                                        Text(
                                          '다시 시작',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: fontSize * 0.22,  // 0.3 -> 0.22로 축소
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}