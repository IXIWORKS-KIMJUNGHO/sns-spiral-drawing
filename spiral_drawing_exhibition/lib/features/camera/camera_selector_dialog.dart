import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// 카메라 선택 다이얼로그
/// 
/// 여러 카메라가 연결된 경우 사용자가 선택할 수 있도록 함
class CameraSelectorDialog extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const CameraSelectorDialog({
    super.key,
    required this.cameras,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('카메라 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('사용할 카메라를 선택해주세요:'),
          const SizedBox(height: 20),
          ...cameras.map((camera) => _buildCameraOption(context, camera)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
  
  /// 카메라 타입 분석 (iOS/iPad 기준)
  Map<String, dynamic> _analyzeCameraType(CameraDescription camera, int index, int totalCameras) {
    final name = camera.name.toLowerCase();
    final isBack = camera.lensDirection == CameraLensDirection.back;
    final isFront = camera.lensDirection == CameraLensDirection.front;
    
    String lensType = '';
    String displayName = '';
    String position = '';
    double portraitSuitability = 0.0; // 0~1 scale, 1이 가장 적합
    String recommendationText = '';
    IconData icon = Icons.camera_alt;
    
    // 전면/후면 카메라 구분
    if (isFront) {
      position = '전면 카메라';
      icon = Icons.camera_front;
      lensType = '표준';
      displayName = '셀피 카메라';
      portraitSuitability = 0.9;
      recommendationText = '셀피 및 화상통화에 적합';
    } else if (isBack) {
      position = '후면 카메라';
      icon = Icons.camera_rear;
      
      // iOS/iPad 카메라 인덱스 기반 렌즈 타입 추정
      // 일반적으로: 0=광각, 2=텔레포토, 3=초광각
      if (totalCameras > 2 && isBack) {
        if (index == 0) {
          lensType = '광각 (Wide)';
          displayName = '기본 카메라';
          portraitSuitability = 0.7;
          recommendationText = '일반 촬영용 (약간의 왜곡 있음)';
        } else if (index == 2) {
          lensType = '망원 (Telephoto)';
          displayName = '인물 카메라';
          portraitSuitability = 1.0;
          recommendationText = '✨ 인물 촬영 최적 (왜곡 최소)';
        } else if (index == 3) {
          lensType = '초광각 (Ultra Wide)';
          displayName = '파노라마 카메라';
          portraitSuitability = 0.3;
          recommendationText = '풍경용 (인물에 부적합, 심한 왜곡)';
        } else {
          lensType = '보조 카메라';
          displayName = '추가 카메라';
          portraitSuitability = 0.5;
        }
      } else {
        // 단일 후면 카메라
        lensType = '광각 (Wide)';
        displayName = '기본 카메라';
        portraitSuitability = 0.7;
        recommendationText = '표준 촬영용';
      }
    }
    
    // macOS 카메라 이름 처리
    if (name.contains('facetime')) {
      displayName = '맥북 내장 카메라';
      lensType = 'FaceTime HD';
      recommendationText = '화상회의 최적화';
    } else if (name.contains('studio display')) {
      displayName = '스튜디오 디스플레이';
      lensType = 'Center Stage';
      recommendationText = '자동 프레이밍 지원';
    } else if (name.contains('external') || name.contains('usb')) {
      displayName = '외장 웹캠';
      lensType = '외부 카메라';
      recommendationText = '외부 연결 카메라';
    }
    
    return {
      'displayName': displayName,
      'lensType': lensType,
      'position': position,
      'portraitSuitability': portraitSuitability,
      'recommendationText': recommendationText,
      'icon': icon,
    };
  }
  
  Widget _buildCameraOption(BuildContext context, CameraDescription camera) {
    // 카메라 인덱스 찾기 (렌즈 타입 추정용)
    final cameras = this.cameras;
    final index = cameras.indexOf(camera);
    final cameraInfo = _analyzeCameraType(camera, index, cameras.length);
    
    final bool isRecommended = cameraInfo['portraitSuitability'] >= 0.9;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(camera);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRecommended ? Colors.blue.shade300 : Colors.grey.shade300,
              width: isRecommended ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isRecommended ? Colors.blue.shade50 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    cameraInfo['icon'],
                    color: isRecommended ? Colors.blue : Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cameraInfo['displayName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isRecommended ? Colors.blue.shade700 : null,
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '추천',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cameraInfo['position'],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (cameraInfo['lensType'].isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cameraInfo['lensType'],
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (cameraInfo['recommendationText'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRecommended ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRecommended ? Icons.star : Icons.info_outline,
                        size: 16,
                        color: isRecommended ? Colors.orange : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cameraInfo['recommendationText'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // 인물 촬영 적합도 표시 바
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '인물 촬영 적합도: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: cameraInfo['portraitSuitability'],
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.orange.shade400,
                                  Colors.green.shade400,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(cameraInfo['portraitSuitability'] * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cameraInfo['portraitSuitability'] >= 0.7
                          ? Colors.green
                          : cameraInfo['portraitSuitability'] >= 0.5
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카메라 정보를 표시하는 위젯
class CameraInfoWidget extends StatelessWidget {
  final CameraDescription? currentCamera;
  final VoidCallback onChangeCamera;
  final double? zoomLevel; // 줌 레벨 추가
  
  const CameraInfoWidget({
    super.key,
    this.currentCamera,
    required this.onChangeCamera,
    this.zoomLevel,
  });
  
  @override
  Widget build(BuildContext context) {
    if (currentCamera == null) {
      return const SizedBox.shrink();
    }
    
    String displayName = currentCamera!.name;
    if (displayName.contains('FaceTime')) {
      displayName = '맥북 카메라';
    } else if (displayName.contains('Studio Display')) {
      displayName = '스튜디오 디스플레이';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (zoomLevel != null && zoomLevel! > 1.0)
                Text(
                  '${zoomLevel!.toStringAsFixed(1)}x 줌 (왜곡 감소)',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onChangeCamera,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}