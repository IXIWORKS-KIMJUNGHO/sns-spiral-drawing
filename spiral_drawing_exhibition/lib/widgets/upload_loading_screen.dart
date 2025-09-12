import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Firebase 업로드 중 로딩 영상을 표시하는 화면
/// 작품 완성 후 QR 화면으로 넘어가기 전 업로드 진행 상황을 보여줌
class UploadLoadingScreen extends StatefulWidget {
  final VoidCallback? onLoadingComplete;
  
  const UploadLoadingScreen({
    super.key,
    this.onLoadingComplete,
  });

  @override
  State<UploadLoadingScreen> createState() => _UploadLoadingScreenState();
}

class _UploadLoadingScreenState extends State<UploadLoadingScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // 텍스트 애니메이션
  late AnimationController _textAnimationController;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeTextAnimation();
  }

  /// 비디오 초기화 및 재생 시작
  Future<void> _initializeVideo() async {
    try {
      if (kDebugMode) {
        print('🎬 업로드 로딩 영상 초기화 시작...');
      }
      
      _controller = VideoPlayerController.asset('assets/videos/loading.mp4');
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        _controller!.setLooping(true);
        _controller!.play();
        
        if (kDebugMode) {
          print('✅ 업로드 로딩 영상 재생 시작');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 업로드 로딩 영상 초기화 실패: $e');
      }
      
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// 텍스트 애니메이션 초기화
  void _initializeTextAnimation() {
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textFadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _textScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // 반복 애니메이션 시작
    _textAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final baseSize = isLandscape ? screenSize.height : screenSize.width;
    
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
            // 에러 발생 시 단색 배경
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
            )
          else
            // 비디오 로딩 중 단색 배경
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
            ),

          // 반투명 오버레이 (텍스트 가독성 향상)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),

          // 중앙 텍스트 영역
          Center(
            child: AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _textScaleAnimation.value,
                  child: Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 로딩 인디케이터만 표시
                        SizedBox(
                          width: baseSize * 0.08,
                          height: baseSize * 0.08,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: baseSize * 0.008,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 하단 텍스트 - QR 다운로드 중
          Positioned(
            bottom: baseSize * 0.08,
            left: baseSize * 0.05,
            right: baseSize * 0.05,
            child: Text(
              'QR을 다운로드 중입니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: baseSize * 0.02,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
                shadows: [
                  Shadow(
                    offset: Offset(0, baseSize * 0.001),
                    blurRadius: baseSize * 0.008,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),

          // 디버그 모드에서만 에러 정보 표시
          if (kDebugMode && _hasError)
            Positioned(
              top: baseSize * 0.1,
              left: baseSize * 0.05,
              right: baseSize * 0.05,
              child: Container(
                padding: EdgeInsets.all(baseSize * 0.02),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(baseSize * 0.02),
                ),
                child: Text(
                  '비디오 로드 실패: $_errorMessage',
                  style: TextStyle(
                    fontSize: baseSize * 0.025,
                    color: Colors.red.shade300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 업로드 진행 상황을 관리하고 로딩 화면을 표시하는 위젯
class UploadProgressManager extends StatefulWidget {
  final Future<Map<String, String>> Function() uploadTask;
  final Function(Map<String, String> result) onUploadComplete;
  final Function(String error)? onUploadError;
  final Duration minimumLoadingTime;
  
  const UploadProgressManager({
    super.key,
    required this.uploadTask,
    required this.onUploadComplete,
    this.onUploadError,
    this.minimumLoadingTime = const Duration(milliseconds: 2000),
  });

  @override
  State<UploadProgressManager> createState() => _UploadProgressManagerState();
}

class _UploadProgressManagerState extends State<UploadProgressManager> {
  bool _isUploading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performUpload();
  }

  /// 업로드 작업 수행
  Future<void> _performUpload() async {
    final startTime = DateTime.now();
    
    try {
      // 업로드 작업 실행
      final result = await widget.uploadTask();
      
      // 최소 로딩 시간 보장
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = widget.minimumLoadingTime - elapsed;
      
      if (remainingTime.inMilliseconds > 0) {
        await Future.delayed(remainingTime);
      }
      
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        // 업로드 완료 콜백 실행
        widget.onUploadComplete(result);
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 업로드 중 오류 발생: $e');
      }
      
      // 최소 로딩 시간 보장 (에러 시에도)
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = widget.minimumLoadingTime - elapsed;
      
      if (remainingTime.inMilliseconds > 0) {
        await Future.delayed(remainingTime);
      }
      
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = e.toString();
        });
        
        // 에러 콜백 실행
        if (widget.onUploadError != null) {
          widget.onUploadError!(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return const UploadLoadingScreen();
    } else {
      // 업로드 완료 후에는 빈 화면 (부모에서 처리)
      return const SizedBox.shrink();
    }
  }
}