# 🎨 Spiral Drawing Exhibition

인터랙티브 나선형 드로잉 전시 앱 - 카메라로 캡처한 이미지를 나선형 예술 작품으로 변환하고 SNS 공유 및 프린트를 지원하는 iPad 전시용 애플리케이션

## 📱 프로젝트 개요

이 프로젝트는 전시회나 이벤트에서 관람객들이 직접 참여하여 자신만의 나선형 예술 작품을 만들 수 있는 인터랙티브 iPad 애플리케이션입니다. 카메라로 촬영한 이미지를 실시간으로 나선형 드로잉으로 변환하고, QR 코드를 통해 작품을 다운로드하거나 메모닉 프린터로 즉석 출력할 수 있습니다.

### 주요 특징
- 🎭 실시간 카메라 캡처 및 나선형 변환
- 🖼️ 다양한 드로잉 프리셋 지원 (기본, 섬세함, 대담함, 미니멀)
- 📤 Firebase Storage를 통한 클라우드 저장
- 📱 QR 코드를 통한 작품 다운로드
- 🖨️ 메모닉 프린터 블루투스 연동
- 🎬 커스텀 로딩 애니메이션
- 🔄 30초 자동 초기화 기능

## 🛠️ 기술 스택

- **프레임워크**: Flutter 3.9+
- **언어**: Dart
- **상태관리**: Provider
- **백엔드**: Firebase (Storage, Auth)
- **하드웨어**: 메모닉 프린터 SDK
- **주요 라이브러리**:
  - `camera`: 카메라 기능
  - `image`: 이미지 처리 및 변환
  - `qr_flutter`: QR 코드 생성
  - `video_player`: 로딩 화면 애니메이션
  - `nemonic_sdk`: 프린터 연동

## 📋 필수 요구사항

- Flutter SDK 3.9.0 이상
- iOS 15.0 이상 (iPad 전용)
- Xcode 14.0 이상
- Firebase 프로젝트 설정
- 메모닉 프린터 (선택사항)

## 🚀 설치 및 실행

### 1. 프로젝트 클론
```bash
git clone https://github.com/yourusername/spiral-drawing-exhibition.git
cd spiral_drawing_exhibition
```

### 2. 의존성 설치
```bash
# Flutter 패키지 설치
flutter pub get

# iOS 의존성 설치
cd ios && pod install
cd ..
```

### 3. Firebase 설정
1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. iOS 앱 추가 (Bundle ID: `com.example.spiralDrawingExhibition`)
3. `GoogleService-Info.plist` 다운로드 후 `ios/Runner/` 폴더에 추가
4. Firebase Storage 활성화

### 4. 메모닉 SDK 설정
```bash
# nemonic_sdk_flutter를 상위 폴더에 클론
cd ..
git clone [nemonic_sdk_repository_url] nemonic_sdk_flutter
cd spiral_drawing_exhibition
```

### 5. 앱 실행
```bash
# 개발 모드 실행
flutter run

# 릴리즈 빌드
flutter build ipa --release
```

## 📁 프로젝트 구조

```
lib/
├── main.dart                     # 앱 진입점
├── core/                         # 핵심 비즈니스 로직
│   ├── algorithms/
│   │   └── spiral_processor.dart # 나선형 변환 알고리즘
│   ├── constants/
│   │   └── drawing_presets.dart  # 드로잉 프리셋 설정
│   ├── models/
│   │   └── drawing_config.dart   # 드로잉 설정 모델
│   └── utils/
│       ├── image_analyzer.dart   # 이미지 분석 유틸
│       └── image_converter.dart  # 이미지 변환 유틸
├── features/                     # 주요 기능별 화면
│   ├── camera/
│   │   ├── camera_screen.dart    # 카메라 캡처 화면
│   │   └── camera_selector_dialog.dart
│   ├── drawing/
│   │   ├── drawing_provider.dart # 드로잉 상태 관리
│   │   └── spiral_painter.dart   # 나선형 드로잉 렌더러
│   ├── qr/
│   │   └── qr_display_screen.dart # QR 코드 표시 화면
│   └── setup/
│       └── setup_screen.dart     # 초기 설정 화면
├── services/                     # 외부 서비스 연동
│   ├── firebase_service.dart     # Firebase 업로드
│   ├── printer_service.dart      # 메모닉 프린터 연동
│   └── settings_service.dart     # 앱 설정 관리
├── widgets/                      # 재사용 가능한 위젯
│   ├── loading_video_screen.dart # 로딩 애니메이션
│   ├── upload_loading_screen.dart # 업로드 로딩 화면
│   └── liquid_glass_settings_button.dart
└── utils/
    └── logger_service.dart       # 로깅 서비스
```

## 🎮 사용 방법

### 관람객 플로우
1. **카메라 화면**: 촬영 버튼을 눌러 사진 캡처
2. **드로잉 화면**: 나선형으로 변환된 작품 확인 및 설정 조정
3. **완료**: 작품 저장 및 QR 코드 생성
4. **QR 스캔**: 스마트폰으로 QR 코드 스캔하여 다운로드
5. **자동 초기화**: 30초 후 자동으로 처음 화면으로 돌아감

### 관리자 설정
- 설정 버튼(우측 상단)을 통해 접근
- 프린터 연결 관리
- 드로잉 프리셋 선택
- 워터마크 설정

## 🔧 주요 설정

### 드로잉 프리셋
- **기본**: 균형잡힌 설정
- **섬세함**: 얇은 선과 높은 디테일
- **대담함**: 굵은 선과 강한 대비
- **미니멀**: 단순하고 깔끔한 스타일

### 카메라 설정
- 전면/후면 카메라 전환
- 미러링 모드 (전면 카메라)
- 자동 초점 및 노출

## 📱 배포

### TestFlight 배포
```bash
# App Store Connect용 빌드
flutter build ipa --release

# Transporter 앱으로 업로드
# build/ios/ipa/*.ipa 파일을 Transporter로 드래그
```

### Firebase App Distribution
```bash
# Ad Hoc 빌드
flutter build ipa --release --export-method=ad-hoc

# Firebase Console에서 업로드
# App Distribution → 새 릴리스 → IPA 업로드
```

## 🐛 문제 해결

### 카메라 권한 오류
- 설정 → 개인정보 보호 → 카메라에서 앱 권한 확인

### 프린터 연결 실패
- 블루투스 활성화 확인
- 메모닉 프린터 전원 확인
- 설정에서 프린터 재연결

### Firebase 업로드 실패
- 네트워크 연결 확인
- Firebase Storage 규칙 확인
- 할당량 초과 여부 확인

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 👥 기여

버그 리포트, 기능 제안, Pull Request 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 문의

프로젝트 관련 문의사항은 [이메일/이슈 트래커]로 연락주세요.

---

© 2024 Spiral Drawing Exhibition. All rights reserved.