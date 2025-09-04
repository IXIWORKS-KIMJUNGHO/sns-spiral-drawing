import 'package:flutter/material.dart';
import 'package:camera_macos/camera_macos.dart';

/// 카메라 선택 다이얼로그
/// 
/// 여러 카메라가 연결된 경우 사용자가 선택할 수 있도록 함
class CameraSelectorDialog extends StatelessWidget {
  final List<CameraMacOSDevice> cameras;
  
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
  
  Widget _buildCameraOption(BuildContext context, CameraMacOSDevice camera) {
    // 카메라 이름과 위치 정보 표시
    String cameraName = camera.deviceId;
    String cameraPosition = camera.manufacturer ?? '';
    
    // macOS에서 일반적인 카메라 이름 매핑
    if (cameraName.contains('FaceTime')) {
      cameraName = '맥북 내장 카메라 (FaceTime)';
    } else if (cameraName.contains('Studio Display')) {
      cameraName = '스튜디오 디스플레이 카메라';
    } else if (cameraName.contains('External')) {
      cameraName = '외장 웹캠';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(camera);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cameraName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (cameraPosition.isNotEmpty)
                      Text(
                        cameraPosition,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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
        ),
      ),
    );
  }
}

/// 카메라 정보를 표시하는 위젯
class CameraInfoWidget extends StatelessWidget {
  final CameraMacOSDevice? currentCamera;
  final VoidCallback onChangeCamera;
  
  const CameraInfoWidget({
    super.key,
    this.currentCamera,
    required this.onChangeCamera,
  });
  
  @override
  Widget build(BuildContext context) {
    if (currentCamera == null) {
      return const SizedBox.shrink();
    }
    
    String displayName = currentCamera!.deviceId;
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
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
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