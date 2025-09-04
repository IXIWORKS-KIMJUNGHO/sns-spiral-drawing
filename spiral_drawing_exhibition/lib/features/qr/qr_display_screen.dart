import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

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
    
    // 10초 후 자동으로 다음 화면으로 이동
    _autoCloseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }
  
  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animationController.dispose();
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
      body: AnimatedBuilder(
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
                      'QR 코드를 스캔하여 작품을 다운로드하세요',
                      style: TextStyle(
                        fontSize: fontSize * 0.95,
                        color: Colors.black.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    
                    SizedBox(height: squareSize * 0.02),
                    
                    // 추가 안내 텍스트
                    Text(
                      '프린트된 종이를 벽면에 붙여주세요',
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
                      '10초 후 자동으로 다음 화면으로 이동합니다',
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
    );
  }
}