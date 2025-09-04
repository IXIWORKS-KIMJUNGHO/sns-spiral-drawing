import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../drawing/drawing_provider.dart';
import '../drawing/spiral_painter.dart';
import 'camera_selector_dialog.dart';
import '../qr/qr_display_screen.dart';
import '../../services/firebase_service.dart';

/// 카메라 캡처 화면
/// 
/// Processing의 Capture 클래스와 유사한 역할
/// 차이점: Flutter는 플랫폼별 카메라 API를 추상화한 camera 패키지 사용
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _cameraKey = GlobalKey(debugLabel: "cameraKey");
  CameraMacOSController? _controller;
  List<CameraMacOSDevice>? _cameras;
  CameraMacOSDevice? _selectedCamera;
  bool _isInitialized = false;
  bool _isCapturing = false;
  CameraMacOSFile? _capturedImage;
  String? _deviceId;
  
  // 이전 세션의 카메라 정보를 저장 (앱이 실행되는 동안 유지)
  static String? _lastUsedDeviceId;
  
  // 애니메이션 컨트롤러
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
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
      
      // 카메라 권한 상태 확인 (디버그용)
      if (kDebugMode) { print('카메라 목록 조회 중...'); }
      
      // CameraMacOS 플랫폼 인스턴스 생성
      final cameraMacOS = CameraMacOS.instance;
      
      // 사용 가능한 카메라 목록 가져오기
      _cameras = await cameraMacOS.listDevices(deviceType: CameraMacOSDeviceType.video);
      
      if (kDebugMode) { print('조회 완료. 카메라 개수: ${_cameras?.length ?? 0}'); }
      
      if (_cameras == null || _cameras!.isEmpty) {
        if (kDebugMode) { print('에러: 카메라를 찾을 수 없습니다'); }
        _showError('카메라를 찾을 수 없습니다.\n\n시스템 설정 > 보안 및 개인 정보 보호 > 카메라에서\n앱 권한을 확인해주세요.');
        return;
      }
      
      // 카메라 목록 디버그 출력
      if (kDebugMode) { print('발견된 카메라 목록:'); }
      for (var cam in _cameras!) {
        if (kDebugMode) { print('- 이름: ${cam.deviceId}'); }
        if (kDebugMode) { print('  제조사: ${cam.manufacturer}'); }
      }
      
      // 이전에 사용한 카메라가 있는지 확인
      if (_lastUsedDeviceId != null) {
        // 저장된 deviceId로 카메라 찾기
        _selectedCamera = _cameras!.firstWhere(
          (camera) => camera.deviceId == _lastUsedDeviceId,
          orElse: () => _cameras!.first, // 못 찾으면 첫 번째 카메라 사용
        );
        _deviceId = _selectedCamera!.deviceId;
        if (kDebugMode) { print('이전 사용 카메라로 복원: ${_selectedCamera!.deviceId}'); }
        setState(() {});
      }
      // 처음 실행이거나 저장된 카메라가 없는 경우
      else if (_cameras!.length > 1 && mounted) {
        // 다이얼로그 표시 전 context 체크
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _showCameraSelector();
        }
      } else {
        // 카메라가 하나만 있으면 자동 선택
        _selectedCamera = _cameras!.first;
        _deviceId = _selectedCamera!.deviceId;
        _lastUsedDeviceId = _deviceId; // 선택한 카메라 저장
        if (kDebugMode) { print('자동 선택된 카메라: ${_selectedCamera!.deviceId}'); }
        setState(() {});
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
  
  /// 카메라 선택 다이얼로그 표시
  Future<void> _showCameraSelector() async {
    final selected = await showDialog<CameraMacOSDevice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CameraSelectorDialog(cameras: _cameras!),
    );
    
    if (selected != null) {
      _selectedCamera = selected;
      _deviceId = selected.deviceId;
      _lastUsedDeviceId = _deviceId; // 선택한 카메라 저장
    } else {
      // 선택하지 않으면 기본 카메라 사용
      _selectedCamera = _cameras!.first;
      _deviceId = _selectedCamera!.deviceId;
      _lastUsedDeviceId = _deviceId; // 선택한 카메라 저장
    }
    setState(() {});
  }
  
  /// 카메라 변경
  Future<void> _changeCamera() async {
    setState(() {
      _isInitialized = false;
    });
    
    await _showCameraSelector();
  }
  
  /// 사진 촬영
  /// Processing: capture.read()와 유사
  Future<void> _capturePhoto() async {
    if (_controller == null || !_isInitialized) {
      return;
    }
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      // 사진 촬영
      final CameraMacOSFile? photo = await _controller!.takePicture();
      
      if (photo != null) {
        setState(() {
          _capturedImage = photo;
          _isCapturing = false;
        });
        
        // 바로 드로잉 화면으로 이동
        _navigateToDrawing();
      } else {
        setState(() {
          _isCapturing = false;
        });
        _showError('사진 촬영 실패');
      }
      
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showError('사진 촬영 실패: $e');
    }
  }
  
  /// 드로잉 화면으로 이동
  Future<void> _navigateToDrawing() async {
    if (_capturedImage == null || _capturedImage!.bytes == null) return;
    
    try {
      // 이미지 데이터를 ui.Image로 변환
      final bytes = _capturedImage!.bytes!;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      // 정사각형으로 크롭 (중앙 부분 추출)
      final ui.Image croppedImage = await _cropToSquare(originalImage);
      
      if (!mounted) return;
      
      // DrawingScreen으로 이동하면서 크롭된 이미지 전달
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DrawingScreenWithImage(image: croppedImage),
        ),
      );
    } catch (e) {
      _showError('이미지 처리 실패: $e');
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
                          child: CameraMacOSView(
                            key: _cameraKey,
                            deviceId: _deviceId,
                            fit: BoxFit.cover,
                            cameraMode: CameraMacOSMode.photo,
                            onCameraInizialized: (CameraMacOSController controller) {
                              setState(() {
                                _controller = controller;
                                _isInitialized = true;
                              });
                            },
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
                    if (_selectedCamera != null)
                      Padding(
                        padding: EdgeInsets.only(top: squareSize * 0.02),
                        child: Transform.scale(
                          scale: squareSize / 1000,  // 기준 크기에 비례하여 스케일 조정
                          child: CameraInfoWidget(
                            currentCamera: _selectedCamera,
                            onChangeCamera: _changeCamera,
                          ),
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
                                onTap: _isInitialized && !_isCapturing ? _capturePhoto : null,
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
                            onTap: _isInitialized && !_isCapturing ? _capturePhoto : null,
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
              
              // 디버그 메뉴 (우상단)
              Positioned(
                top: squareSize * 0.04,
                right: squareSize * 0.04,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.settings,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: squareSize * 0.03,
                  ),
                  color: Colors.grey.shade900,
                  onSelected: (value) {
                    if (value == 'clear_results') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScreen()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear_results',
                      child: Text(
                        '결과 초기화',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: subFontSize * 0.9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController?.dispose();
    // CameraMacOSController doesn't have dispose method
    super.dispose();
  }
  
  /// 이미지를 정사각형으로 크롭 (중앙 부분 추출)
  Future<ui.Image> _cropToSquare(ui.Image image) async {
    final int width = image.width;
    final int height = image.height;
    
    // 정사각형 크기 결정 (짧은 쪽 기준)
    final int squareSize = width < height ? width : height;
    
    // 크롭 시작 좌표 계산 (중앙 정렬)
    final int x = (width - squareSize) ~/ 2;
    final int y = (height - squareSize) ~/ 2;
    
    if (kDebugMode) { print('Original image: ${width}x$height'); }
    if (kDebugMode) { print('Cropping to square: ${squareSize}x$squareSize from position ($x, $y)'); }
    
    // 원본 이미지의 픽셀 데이터 가져오기
    final ByteData? originalData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (originalData == null) {
      if (kDebugMode) { print('Failed to get original image data'); }
      return image;
    }
    
    // 정사각형 이미지용 버퍼 생성
    final Uint8List squarePixels = Uint8List(squareSize * squareSize * 4);
    
    // 중앙 부분을 정사각형으로 크롭
    for (int row = 0; row < squareSize; row++) {
      for (int col = 0; col < squareSize; col++) {
        // 원본 이미지에서의 좌표
        final int sourceX = x + col;
        final int sourceY = y + row;
        
        // 픽셀 인덱스 계산
        final int sourceIndex = (sourceY * width + sourceX) * 4;
        final int targetIndex = (row * squareSize + col) * 4;
        
        // RGBA 값 복사
        squarePixels[targetIndex] = originalData.getUint8(sourceIndex);     // R
        squarePixels[targetIndex + 1] = originalData.getUint8(sourceIndex + 1); // G
        squarePixels[targetIndex + 2] = originalData.getUint8(sourceIndex + 2); // B
        squarePixels[targetIndex + 3] = originalData.getUint8(sourceIndex + 3); // A
      }
    }
    
    // 정사각형 이미지 생성
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      squarePixels,
      squareSize,
      squareSize,
      ui.PixelFormat.rgba8888,
      (ui.Image result) {
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
  
  const DrawingScreenWithImage({
    super.key,
    required this.image,
  });
  
  @override
  State<DrawingScreenWithImage> createState() => _DrawingScreenWithImageState();
}

class _DrawingScreenWithImageState extends State<DrawingScreenWithImage> 
    with TickerProviderStateMixin {
  
  // RepaintBoundary를 위한 GlobalKey
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isProcessing = false; // 중복 처리 방지
  
  @override
  void initState() {
    super.initState();
    
    // 위젯 빌드 후 드로잉 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDrawingWithImage();
    });
    
    // DrawingProvider 리스닝하여 완료 시 자동으로 화면 전환
    final provider = context.read<DrawingProvider>();
    provider.addListener(_onDrawingStateChanged);
  }
  
  @override
  void dispose() {
    final provider = context.read<DrawingProvider>();
    provider.removeListener(_onDrawingStateChanged);
    super.dispose();
  }
  
  void _onDrawingStateChanged() async {
    final provider = context.read<DrawingProvider>();
    
    // 드로잉이 완료되면 (progress가 1.0이고 더 이상 그리지 않을 때)
    if (provider.progress >= 1.0 && !provider.isDrawing && !_isProcessing) {
      _isProcessing = true; // 중복 처리 방지
      
      // 약간의 딜레이 후 처리 (애니메이션 완료 대기)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        try {
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
            
            // 3. QR 코드 화면으로 이동
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QRDisplayScreen(
                    imageUrl: result['url']!,
                    artworkId: result['artworkId']!,
                    onComplete: () {
                      // QR 화면이 끝나면 카메라로 돌아가기
                      Navigator.pushReplacementNamed(context, '/camera');
                    },
                  ),
                ),
              );
            }
          }
        } catch (e, stackTrace) {
          if (kDebugMode) { print('===== Firebase 오류 상세 정보 ====='); }
          if (kDebugMode) { print('오류 타입: ${e.runtimeType}'); }
          if (kDebugMode) { print('오류 메시지: $e'); }
          if (kDebugMode) { print('스택 트레이스:\n$stackTrace'); }
          if (kDebugMode) { print('================================='); }
          
          // 에러를 화면에 표시 (더 자세한 정보 포함)
          if (mounted) {
            String errorMessage = 'Firebase 업로드 실패:\n';
            if (e.toString().contains('Firebase')) {
              errorMessage += '⚠️ Firebase 초기화 문제일 수 있습니다\n';
            }
            errorMessage += e.toString();
            
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
                        Navigator.pushReplacementNamed(context, '/camera');
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