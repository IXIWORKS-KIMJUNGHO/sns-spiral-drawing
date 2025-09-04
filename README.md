# SNS 나선형 드로잉 전시

> 카메라 입력을 실시간으로 예술적인 나선형 드로잉으로 변환하는 인터랙티브 Flutter macOS 애플리케이션

![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?style=flat&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-DD2C00?style=flat&logo=firebase&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=macos&logoColor=white)

## 프로젝트 개요

라이브 카메라 입력을 받아 매혹적인 나선형 드로잉으로 변환하는 혁신적인 디지털 아트 설치 작품입니다. Processing 알고리즘에서 영감을 받아 Flutter로 구현된 이 애플리케이션은 QR 코드와 Firebase 연동을 통해 실시간 생성 아트와 소셜 공유 기능을 macOS에서 제공합니다.

## 🎨 주요 기능

### 핵심 기능
- **실시간 카메라 캡처**: macOS 카메라 통합을 통한 라이브 비디오 피드 처리
- **이미지-나선 변환**: 밝기 패턴을 나선형 아트워크로 변환하는 고급 알고리즘
- **다중 드로잉 프리셋**: 빠름(20초), 표준(30초), 상세(45초), 사용자 정의 설정
- **라이브 드로잉 애니메이션**: 진행률 표시기와 함께 실시간으로 아트워크 생성 과정 관찰

### 고급 이미지 처리
- **흑백 변환**: ITU-R BT.709 표준 밝기 계산
- **대비 향상**: 극적인 효과를 위한 자동 대비 조정
- **히스토그램 균등화**: 밝기 분포 최적화
- **적응형 선 굵기**: 이미지 밝기에 따른 선 굵기 변화 (0.5-8.0px 범위)

### 소셜 통합
- **Firebase Storage**: 자동 작품 업로드 및 클라우드 저장소
- **QR 코드 생성**: 모바일 접근을 위한 즉석 QR 코드 공유
- **익명 인증**: 회원가입 없는 원활한 사용자 경험
- **체계적 저장**: 날짜 기반 폴더 구조 (artworks/YYYY/MM/)

### 기술적 우수성
- **성능 최적화**: 부드러운 60fps 애니메이션을 위한 미리 계산된 나선 경로
- **메모리 효율성**: 지능적 이미지 처리 및 리소스 관리
- **카메라 관리**: 선택 다이얼로그를 통한 다중 카메라 지원
- **최신 Flutter**: 최신 API, 슈퍼 매개변수, 디버그 모드 통합

## 🚀 빠른 시작

### 필수 요구사항
- **macOS 10.14+** (Mojave 이상)
- **Flutter 3.9+** Dart SDK 포함
- **Xcode 12.0+** iOS 배포 도구용
- **카메라 권한** (자동으로 요청됨)

### 설치 방법

1. **저장소 클론**
   ```bash
   git clone https://github.com/IXIWORKS-KIMJUNGHO/sns-spiral-drawing.git
   cd sns-spiral-drawing
   ```

2. **의존성 설치**
   ```bash
   cd spiral_drawing_exhibition
   flutter pub get
   ```

3. **macOS 설정**
   ```bash
   cd macos && pod install && cd ..
   ```

4. **Firebase 설정** (선택사항)
   - `GoogleService-Info.plist` 파일을 `macos/Runner/`에 추가
   - 스토리지용 Firebase 프로젝트 설정

5. **애플리케이션 실행**
   ```bash
   flutter run -d macos
   ```

## 🏗️ 아키텍처

### 프로젝트 구조
```
spiral_drawing_exhibition/
├── lib/
│   ├── core/
│   │   ├── algorithms/     # 나선 처리 로직
│   │   ├── constants/      # 드로잉 프리셋 및 설정
│   │   ├── models/         # 데이터 모델 및 구조
│   │   └── utils/          # 이미지 처리 유틸리티
│   ├── features/
│   │   ├── camera/         # 카메라 캡처 및 관리
│   │   ├── drawing/        # 드로잉 프로바이더 및 페인터
│   │   └── qr/             # QR 코드 생성 및 표시
│   ├── services/           # Firebase 및 외부 서비스
│   └── widgets/            # 재사용 가능한 UI 컴포넌트
├── assets/                 # 이미지, 폰트, 리소스
└── macos/                  # macOS 전용 설정
```

### 기술 스택
- **프레임워크**: Flutter 3.9+ with Dart
- **상태 관리**: Provider 패턴
- **카메라**: macOS 통합을 위한 camera_macos 플러그인
- **이미지 처리**: dart:ui를 사용한 커스텀 알고리즘
- **클라우드 저장소**: 자동 조직화된 Firebase Storage
- **인증**: Firebase 익명 인증
- **QR 생성**: 즉석 공유를 위한 qr_flutter

## 🎯 작동 원리

### 1. 이미지 캡처
- 실시간 카메라 피드 처리
- 선택 다이얼로그가 있는 다중 카메라 지원
- 자동 이미지 최적화 및 전처리

### 2. 나선 생성
```dart
// Processing에서 영감을 받은 핵심 알고리즘
for (int i = 0; i < pointsPerFrame; i++) {
  degree += getAdjustedDegreeIncrement(radius, maxRadius);
  radius += getAdjustedRadiusIncrement(radius, maxRadius);
  
  // 밝기에 따른 선 굵기 계산
  strokeWidth = calculateStrokeWidth(x, y, brightness);
}
```

### 3. 렌더링 파이프라인
- **경로 기반 렌더링**: GPU 최적화
- **점진적 드로잉**: 애니메이션 컨트롤러 사용
- **안티앨리어싱**: 고품질 필터링
- **메모리 효율적**: 픽셀 버퍼 관리

### 4. 공유 워크플로
- Firebase Storage 자동 업로드
- 작품 URL이 포함된 QR 코드 생성
- 날짜별 정리된 클라우드 저장소
- 모바일 친화적 공유 인터페이스

## ⚙️ 설정

### 드로잉 프리셋
```dart
// DrawingPresets 클래스에서 사용 가능한 프리셋
'fast':     20초 지속, 2.0x 속도, 0.8-3.0px 선 굵기
'standard': 30초 지속, 1.5x 속도, 1.0-4.0px 선 굵기
'detailed': 45초 지속, 1.0x 속도, 0.5-6.0px 선 굵기
'custom':   사용자 정의 매개변수
```

### 카메라 설정
- **해상도**: 나선 처리에 최적화
- **프레임 속도**: 부드러운 캡처를 위한 30fps
- **권한**: macOS 카메라 권한 자동 처리

### Firebase 설정
```dart
// 저장소 구조
artworks/
├── 2025/
│   ├── 01/
│   │   ├── 1704067200000_1234.png
│   │   └── 1704153600000_5678.png
│   └── 02/
│       └── ...
```

## 🔧 개발

### 빌드 명령어
```bash
# 디버그 빌드
flutter run -d macos --debug

# 릴리즈 빌드
flutter build macos --release

# 클린 빌드
flutter clean && flutter pub get
```

### 코드 품질
- **린팅**: 엄격한 규칙을 적용한 flutter_lints 6.0+
- **분석**: analysis_options.yaml을 사용한 정적 분석
- **디버그 모드**: 모든 콘솔 출력을 kDebugMode 체크로 래핑
- **타입 안전성**: 사운드 타입 시스템으로 null 안전성 활성화

## 📱 사용법

1. **애플리케이션 실행**: 앱을 시작하고 카메라 권한 허용
2. **카메라 선택**: 사용 가능한 카메라 중 선택 (내장 또는 외장)
3. **프리셋 선택**: 드로잉 속도 및 세부 수준 선택
4. **캡처 및 드로잉**: 사진을 찍고 나선형 아트워크 생성 과정 관찰
5. **공유**: QR 코드를 스캔하여 모바일 기기에서 작품에 접근

## 🎨 알고리즘 세부사항

### 밝기 분석
- **ITU-R BT.709 표준**: 전문적인 컬러-흑백 변환
- **가중 RGB**: 인간의 눈 민감도를 위한 R(0.2126) + G(0.7152) + B(0.0722)
- **적응형 처리**: 지역 밝기에 따른 동적 선 굵기

### 나선 수학
```dart
// 매개변수화된 나선 방정식
x = centerX + radius * cos(angle)
y = centerY + radius * sin(angle)

// 동적 증분 계산
radiusIncrement = map(radius, 0, maxRadius, 0.1, 0.02)
angleIncrement = map(radius, 0, maxRadius, 0.1, 0.005)
```

## 🚀 배포

### macOS 앱 배포
1. 릴리즈 버전 빌드: `flutter build macos --release`
2. 앱 위치: `build/macos/Build/Products/Release/spiral_drawing_exhibition.app`
3. 배포를 위한 코드 서명 및 공증

### Firebase 설정
1. Firebase 프로젝트 생성
2. Storage 및 Authentication 활성화
3. `GoogleService-Info.plist`를 `macos/Runner/`에 추가
4. 퍼블릭 읽기 접근을 위한 스토리지 규칙 설정

## 🤝 기여하기

1. **Fork** 저장소
2. **생성** 기능 브랜치 (`git checkout -b feature/amazing-feature`)
3. **커밋** 변경사항 (`git commit -m 'feat: 멋진 기능 추가'`)
4. **푸시** 브랜치 (`git push origin feature/amazing-feature`)
5. **열기** Pull Request

## 📄 라이선스

이 프로젝트는 오픈 소스이며 [MIT 라이선스](LICENSE) 하에 제공됩니다.

## 🙏 감사의 말

- **Processing 커뮤니티**: 원본 나선형 드로잉 알고리즘 영감
- **Flutter 팀**: 훌륭한 크로스 플랫폼 프레임워크
- **Firebase**: 신뢰할 수 있는 클라우드 인프라
- **Camera 플러그인들**: macOS 카메라 통합

---

<div align="center">
<strong>ALL IN 전시를 위해 제작됨</strong><br>
인터랙티브 디지털 아트 설치<br>
<em>현실을 예술로, 한 번에 하나의 나선으로</em>
</div>