# 📁 프로젝트 폴더 구조

## ✅ 생성 완료된 구조

```
spiral_drawing_exhibition/
│
├── lib/
│   ├── main.dart                    # 앱 진입점
│   │
│   ├── core/                        # 핵심 비즈니스 로직
│   │   ├── algorithms/
│   │   │   ├── spiral_processor.dart      # Processing 알고리즘 포팅
│   │   │   └── image_analyzer.dart        # 밝기 분석 로직
│   │   ├── models/
│   │   │   ├── drawing_config.dart        # 드로잉 설정 모델
│   │   │   ├── artwork_data.dart          # 작품 데이터 모델
│   │   │   └── session_info.dart          # 세션 정보
│   │   └── constants/
│   │       ├── app_config.dart            # 앱 전역 설정
│   │       └── drawing_presets.dart       # 속도 프리셋
│   │
│   ├── features/                    # 기능별 모듈
│   │   ├── camera/
│   │   │   ├── camera_screen.dart         # 카메라 촬영 화면
│   │   │   ├── camera_controller.dart     # 카메라 제어 로직
│   │   │   └── camera_preview.dart        # 미리보기 위젯
│   │   ├── drawing/
│   │   │   ├── drawing_screen.dart        # 드로잉 화면
│   │   │   ├── spiral_painter.dart        # CustomPainter 구현
│   │   │   └── drawing_provider.dart      # 드로잉 상태 관리
│   │   ├── admin/
│   │   │   ├── admin_panel.dart           # 관리자 패널
│   │   │   ├── control_widgets.dart       # 제어 위젯들
│   │   │   └── statistics_view.dart       # 전시 통계
│   │   ├── printing/
│   │   │   ├── printer_service.dart       # 메모닉 프린터 서비스
│   │   │   ├── print_queue.dart           # 인쇄 대기열 관리
│   │   │   └── print_preview.dart         # 인쇄 미리보기
│   │   └── sharing/
│   │       ├── qr_generator.dart          # QR 코드 생성
│   │       ├── cloud_storage.dart         # Firebase 업로드
│   │       └── download_page.dart         # 모바일 다운로드 페이지
│   │
│   ├── shared/                      # 공유 컴포넌트
│   │   ├── widgets/
│   │   │   ├── loading_overlay.dart       # 로딩 오버레이
│   │   │   ├── countdown_timer.dart       # 카운트다운 타이머
│   │   │   └── custom_button.dart         # 커스텀 버튼
│   │   └── utils/
│   │       ├── image_utils.dart           # 이미지 처리 유틸
│   │       ├── file_manager.dart          # 파일 관리
│   │       └── device_info.dart           # 디바이스 정보
│   │
│   └── app/
│       ├── app.dart                       # 앱 설정
│       ├── routes.dart                    # 라우팅 설정
│       └── theme.dart                      # 테마 설정
│
├── assets/
│   ├── images/                     # 기본 이미지
│   ├── fonts/                      # 커스텀 폰트
│   └── sounds/                     # 효과음 (선택)
│
├── test/
│   ├── unit/                       # 단위 테스트
│   ├── widget/                     # 위젯 테스트
│   └── integration/                # 통합 테스트
│
├── web/                            # 웹 배포용
├── macos/                          # macOS 네이티브 설정
├── pubspec.yaml                    # 패키지 의존성
└── README.md                       # 프로젝트 문서
```

## 📊 생성 통계
- **총 31개 Dart 파일** 생성
- **5개 주요 기능 모듈** (camera, drawing, admin, printing, sharing)
- **3개 core 모듈** (algorithms, models, constants)
- **6개 shared 유틸리티**

## 🎯 완료 상태
✅ Flutter 프로젝트 생성 (macOS, Web 플랫폼)
✅ 전체 폴더 구조 생성
✅ 모든 placeholder 파일 생성
✅ assets 폴더 구성
✅ test 폴더 구성