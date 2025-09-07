import 'dart:ui';
import 'package:flutter/material.dart';

/// 리퀴드 글래스 디자인의 설정 버튼
/// 
/// 특징:
/// - 반투명 백그라운드
/// - 블러 효과 (backdrop filter)
/// - 부드러운 그라디언트 
/// - 미묘한 그림자
/// - 설정 아이콘
class LiquidGlassSettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const LiquidGlassSettingsButton({
    super.key,
    required this.onTap,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3), // 부드러운 모서리
          boxShadow: [
            // 외부 그림자
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            // 내부 하이라이트
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 6,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.3),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor?.withValues(alpha: 0.3) ?? 
                      Colors.white.withValues(alpha: 0.3),
                    backgroundColor?.withValues(alpha: 0.1) ?? 
                      Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(size * 0.3),
              ),
              child: Center(
                child: Icon(
                  Icons.settings,
                  size: size * 0.5,
                  color: iconColor ?? Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 위치 지정 가능한 설정 버튼 (Positioned 포함)
class PositionedSettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const PositionedSettingsButton({
    super.key,
    required this.onTap,
    this.top,
    this.right = 16.0, // 기본값: 우측 상단
    this.bottom,
    this.left,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: SafeArea(
        child: LiquidGlassSettingsButton(
          onTap: onTap,
          size: size,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
        ),
      ),
    );
  }
}