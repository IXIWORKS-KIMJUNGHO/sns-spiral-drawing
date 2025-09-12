import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// 로딩 영상을 재생하는 화면
/// 앱 초기화 중에 loading.mp4를 반복 재생하여 부드러운 로딩 경험 제공
class LoadingVideoScreen extends StatefulWidget {
  final Duration? minimumDisplayTime; // 최소 표시 시간
  final VoidCallback? onLoadingComplete; // 로딩 완료 콜백
  
  const LoadingVideoScreen({
    super.key,
    this.minimumDisplayTime,
    this.onLoadingComplete,
  });

  @override
  State<LoadingVideoScreen> createState() => _LoadingVideoScreenState();
}

class _LoadingVideoScreenState extends State<LoadingVideoScreen> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  /// 비디오 초기화 및 재생 시작
  Future<void> _initializeVideo() async {
    try {
      if (kDebugMode) {
        print('🎬 로딩 영상 초기화 시작...');
      }
      
      // assets/videos/loading.mp4 파일로 VideoPlayerController 생성
      _controller = VideoPlayerController.asset('assets/videos/loading.mp4');
      
      // 비디오 초기화
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // 루프 설정 및 재생 시작
        _controller!.setLooping(true);
        _controller!.play();
        
        if (kDebugMode) {
          print('✅ 로딩 영상 재생 시작');
          print('📐 비디오 크기: ${_controller!.value.size}');
          print('⏱️ 비디오 길이: ${_controller!.value.duration}');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로딩 영상 초기화 실패: $e');
      }
      
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black, // 검정색 배경
      body: Stack(
        children: [
          // 비디오 플레이어 (1/3 크기로 축소)
          if (_isVideoInitialized && _controller != null)
            Center(
              child: SizedBox(
                width: screenSize.width / 3,  // 화면 너비의 1/3
                height: screenSize.height / 3, // 화면 높이의 1/3
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            )
          else if (_hasError)
            // 에러 발생 시 대체 로딩 화면
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ALL IN 텍스트 (기본 로딩)
                  const Text(
                    'ALL IN',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Futura',
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  // 로딩 인디케이터
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  const Text(
                    '초기화 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  // 디버그 모드에서만 에러 정보 표시
                  if (kDebugMode) ...[
                    SizedBox(height: screenSize.height * 0.02),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '비디오 로드 실패: $_errorMessage',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            // 비디오 로딩 중
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ALL IN 텍스트
                  const Text(
                    'ALL IN',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Futura',
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  // 로딩 인디케이터
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  const Text(
                    '로딩 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 로딩 화면을 표시하고 초기화 작업을 수행하는 위젯
/// 비동기 초기화 작업이 완료되면 자동으로 다음 화면으로 전환
class LoadingScreenManager extends StatefulWidget {
  final Future<Widget> Function() buildNextScreen;
  final Duration minimumLoadingTime;
  
  const LoadingScreenManager({
    super.key,
    required this.buildNextScreen,
    this.minimumLoadingTime = const Duration(milliseconds: 2000), // 최소 2초 표시
  });

  @override
  State<LoadingScreenManager> createState() => _LoadingScreenManagerState();
}

class _LoadingScreenManagerState extends State<LoadingScreenManager> {
  bool _isLoading = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _performLoading();
  }

  /// 로딩 작업 수행
  Future<void> _performLoading() async {
    final startTime = DateTime.now();
    
    try {
      // 다음 화면 빌드 (초기화 작업 포함)
      final nextScreen = await widget.buildNextScreen();
      
      // 최소 로딩 시간 보장
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = widget.minimumLoadingTime - elapsed;
      
      if (remainingTime.inMilliseconds > 0) {
        await Future.delayed(remainingTime);
      }
      
      if (mounted) {
        setState(() {
          _nextScreen = nextScreen;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로딩 중 오류 발생: $e');
      }
      
      // 에러 발생 시에도 기본 화면으로 이동
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingVideoScreen();
    } else {
      return _nextScreen ?? const SizedBox.shrink();
    }
  }
}