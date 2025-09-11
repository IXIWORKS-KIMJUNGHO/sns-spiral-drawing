import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../services/printer_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/liquid_glass_settings_button.dart';
import '../setup/setup_screen.dart';

/// QR 코드 표시 화면
/// Firebase Storage URL을 QR 코드로 변환하여 표시
class QRDisplayScreen extends StatefulWidget {
  final String imageUrl;
  final String artworkId;
  final VoidCallback? onComplete;
  
  const QRDisplayScreen({
    super.key,
    required this.imageUrl,
    required this.artworkId,
    this.onComplete,
  });
  
  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _autoCloseTimer;
  Timer? _countdownTimer;
  
  bool _isPrinting = false;
  String _printStatus = '메모닉 프린터 연결 중...';
  final PrinterService _printerService = PrinterService();
  final SettingsService _settingsService = SettingsService();
  
  int _remainingSeconds = 30;
  
  @override
  void initState() {
    super.initState();
    
    // 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // 애니메이션 시작
    _animationController.forward();
    
    // 🖨️ 자동 프린터 연결 및 인쇄 시작 (macOS 제외)
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      _startAutoPrinting();
    } else {
      // macOS는 UI 테스트 모드
      setState(() {
        _printStatus = '💻 macOS UI 테스트 모드 - 프린터 기능 비활성화';
        _isPrinting = false;
      });
    }
    
    // 30초 후 자동으로 카메라 화면으로 돌아가기
    _autoCloseTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        // onComplete 콜백 실행 또는 카메라 화면으로 복귀
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          // 카메라 상태를 보존하면서 복귀
          // 안전한 방식: QR 화면만 pop하여 이전 화면(카메라)으로 복귀
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            // fallback: 카메라 화면으로 직접 이동
            Navigator.of(context).pushReplacementNamed('/camera');
          }
        }
      }
    });
    
    // 카운트다운 타이머 시작
    _startCountdown();
  }
  
  /// 🖨️ 자동 프린터 인쇄 시작 (기존 연결 우선 사용)
  Future<void> _startAutoPrinting() async {
    if (!mounted) return;
    
    setState(() {
      _isPrinting = true;
      _printStatus = '프린터 연결 상태 확인 중...';
    });
    
    try {
      // 1. 이미지 먼저 다운로드
      setState(() {
        _printStatus = '이미지 다운로드 중...';
      });
      
      final imageBytes = await _downloadImage(widget.imageUrl);
      if (imageBytes == null || !mounted) return;
      
      // 2. 프린터 서비스 콜백 설정
      _printerService.onPrintProgress = (current, total) {
        if (mounted) {
          setState(() {
            _printStatus = '인쇄 중... ($current/$total)';
          });
        }
      };
      
      _printerService.onPrintComplete = (success, message) {
        if (mounted) {
          setState(() {
            _printStatus = success ? '✅ 인쇄 완료!' : '❌ $message';
            _isPrinting = false;
          });
        }
      };
      
      // 3. 기존 연결 확인 및 사용
      if (_printerService.isConnected()) {
        final connectedPrinter = _printerService.getConnectedPrinter();
        if (mounted) {
          setState(() {
            _printStatus = '${connectedPrinter?.getName() ?? "연결된 프린터"}로 인쇄 중...';
          });
        }
        
        // 기존 연결된 프린터로 바로 인쇄
        final printResult = await _printerService.printImage(imageBytes);
        if (mounted && !printResult) {
          setState(() {
            _printStatus = '❌ 인쇄 실패';
            _isPrinting = false;
          });
        }
        return;
      }
      
      // 4. 연결이 없는 경우 저장된 프린터로 연결 시도
      final savedPrinter = await _settingsService.getSavedPrinter();
      if (savedPrinter == null) {
        setState(() {
          _printStatus = '📱 프린터가 설정되지 않았습니다';
          _isPrinting = false;
        });
        return;
      }
      
      setState(() {
        _printStatus = '${savedPrinter.getName()}로 연결 중...';
      });
      
      // 5. 프린터 연결 및 인쇄
      final connectResult = await _printerService.connectToPrinter(savedPrinter);
      if (!connectResult) {
        setState(() {
          _printStatus = '❌ ${savedPrinter.getName()} 연결 실패';
          _isPrinting = false;
        });
        return;
      }
      
      // 6. 이미지 인쇄
      final printResult = await _printerService.printImage(imageBytes);
      if (mounted && !printResult) {
        setState(() {
          _printStatus = '❌ 인쇄 실패';
          _isPrinting = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _printStatus = '❌ 오류: $e';
          _isPrinting = false;
        });
      }
    }
  }
  
  /// Firebase URL에서 이미지 다운로드
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('이미지 다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('이미지 다운로드 오류: $e');
    }
  }
  
  /// 카운트다운 타이머 시작
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 1) {
            _remainingSeconds--;
          } else {
            _countdownTimer?.cancel();
            _remainingSeconds = 0;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    // 프린터 연결은 앱 전체에서 유지 (세션 간 재사용을 위해)
    // _printerService.disconnect(); // 제거: 매번 연결 해제하지 않음
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    // QR 코드 크기 (원의 크기는 화면의 50%, QR 자체는 원의 70%)
    final circleSize = squareSize * 0.5;
    final qrSize = circleSize * 0.7;
    final fontSize = squareSize * 0.02; // 폰트 크기 축소
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 타이틀
                    Text(
                      'ALL IN',
                      style: TextStyle(
                        fontSize: fontSize * 2.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Futura',
                        letterSpacing: 3,
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.05),
                    
                    // QR 코드를 원 안에 배치 (카메라 화면과 동일한 스타일)
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: qrSize,
                          height: qrSize,
                          padding: EdgeInsets.all(squareSize * 0.015),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: QrImageView(
                            data: widget.imageUrl,
                            version: QrVersions.auto,
                            size: qrSize - (squareSize * 0.03),
                            backgroundColor: Colors.white,
                            errorStateBuilder: (context, error) {
                              return Center(
                                child: Text(
                                  'QR 생성 오류',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.05),
                    
                    // 안내 텍스트 (한 줄로 표시)
                    Text(
                      '스마트폰으로 QR 코드를 스캔하세요',
                      style: TextStyle(
                        fontSize: fontSize * 0.95,
                        color: Colors.black.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.02),
                    
                    // 프린터 상태 표시
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: squareSize * 0.04,
                        vertical: squareSize * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: _isPrinting 
                            ? Colors.blue.withValues(alpha: 0.1)
                            : _printStatus.contains('✅')
                                ? Colors.green.withValues(alpha: 0.1)
                                : _printStatus.contains('❌')
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPrinting 
                              ? Colors.blue.withValues(alpha: 0.3)
                              : _printStatus.contains('✅')
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : _printStatus.contains('❌')
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isPrinting)
                            Container(
                              width: fontSize * 0.8,
                              height: fontSize * 0.8,
                              margin: EdgeInsets.only(right: squareSize * 0.01),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          Text(
                            _printStatus,
                            style: TextStyle(
                              fontSize: fontSize * 0.8,
                              color: _isPrinting 
                                  ? Colors.blue
                                  : _printStatus.contains('✅')
                                      ? Colors.green.shade700
                                      : _printStatus.contains('❌')
                                          ? Colors.red.shade700
                                          : Colors.black.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.02),
                    
                    // 추가 안내 텍스트
                    Text(
                      _printStatus.contains('✅') 
                          ? '프린트된 종이를 벽면에 붙여주세요'
                          : '작품을 저장하거나 공유할 수 있습니다',
                      style: TextStyle(
                        fontSize: fontSize * 0.85,
                        color: Colors.black.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.06),
                    
                    // 다음 버튼
                    GestureDetector(
                      onTap: () {
                        _autoCloseTimer?.cancel();
                        if (widget.onComplete != null) {
                          widget.onComplete!();
                        } else {
                          // 카메라 상태를 보존하면서 복귀
                          // 안전한 방식: QR 화면만 pop하여 이전 화면(카메라)으로 복귀
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            // fallback: 카메라 화면으로 직접 이동
                            Navigator.of(context).pushReplacementNamed('/camera');
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: squareSize * 0.06,
                          vertical: squareSize * 0.015,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '다음 작품 만들기',
                          style: TextStyle(
                            fontSize: fontSize * 0.85,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.02),
                    
                    // 자동 전환 카운터
                    Text(
                      '$_remainingSeconds초 후 자동으로 다음 화면으로 이동합니다',
                      style: TextStyle(
                        fontSize: fontSize * 0.65,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
}