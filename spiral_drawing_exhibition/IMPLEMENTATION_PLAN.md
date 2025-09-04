# 🎯 스파이럴 드로잉 전시 프로젝트 구현 계획

## 📅 전체 일정
**목표 기간**: 3주 (개발 2주 + 테스트/최적화 1주)
**대상 플랫폼**: macOS (전시용), Web (모바일 다운로드용)

---

## 🚀 Phase 1: 기초 설정 및 핵심 알고리즘 (2-3일)

### 1.1 패키지 의존성 설정 ⚙️
**파일**: `pubspec.yaml`
**필수 패키지**:
```yaml
dependencies:
  camera: ^0.10.5          # 카메라 접근
  image: ^4.0.17           # 이미지 처리
  bluetooth_print: ^4.3.0  # 메모닉 프린터
  qr_flutter: ^4.1.0       # QR 생성
  firebase_storage: ^11.5.0 # 이미지 업로드
  provider: ^6.0.5         # 상태 관리
  path_provider: ^2.1.1    # 파일 경로
  permission_handler: ^11.0.1 # 권한 관리
```

### 1.2 드로잉 설정 모델 정의 📊
**파일**: 
- `lib/core/models/drawing_config.dart` - 설정 모델
- `lib/core/constants/drawing_presets.dart` - 프리셋 정의
- `lib/core/constants/app_config.dart` - 전역 상수

**핵심 구현**:
- 속도 제어 파라미터 (0.5x ~ 3.0x)
- 드로잉 시간 설정 (10초 ~ 60초)
- 선 굵기 범위 설정
- 나선 밀도 조절

### 1.3 Processing 알고리즘 포팅 🎨
**파일**: `lib/core/algorithms/spiral_processor.dart`
**핵심 로직**:
- 극좌표 → 직교좌표 변환
- 거리 기반 변속 시스템
- 밝기 → 선 굵기 매핑
- 프레임당 다중 처리 최적화

---

## 🎥 Phase 2: 카메라 및 이미지 처리 (2일)

### 2.1 카메라 캡처 화면 구현
**파일**:
- `lib/features/camera/camera_screen.dart` - UI
- `lib/features/camera/camera_controller.dart` - 제어 로직
- `lib/features/camera/camera_preview.dart` - 미리보기

**기능**:
- macOS 카메라 권한 요청
- 실시간 미리보기
- 캡처 및 확인 화면
- 재촬영 옵션

### 2.2 이미지 분석 로직
**파일**: `lib/core/algorithms/image_analyzer.dart`
**구현**:
- 이미지 밝기 추출
- 픽셀 샘플링 최적화
- 메모리 효율적 처리

---

## 🌀 Phase 3: 드로잉 시스템 (3일)

### 3.1 실시간 스파이럴 렌더링
**파일**:
- `lib/features/drawing/spiral_painter.dart` - CustomPainter
- `lib/features/drawing/drawing_screen.dart` - 화면
- `lib/features/drawing/drawing_provider.dart` - 상태 관리

**핵심 기능**:
- 60 FPS 렌더링
- 실시간 진행 표시
- 부드러운 애니메이션

### 3.2 속도 제어 시스템
**구현 내용**:
- 관리자 조절 가능한 파라미터
- 실시간 속도 변경
- 프리셋 시스템 (빠른/표준/디테일)

---

## 🖨️ Phase 4: 출력 및 공유 (2-3일)

### 4.1 메모닉 프린터 연동
**파일**:
- `lib/features/printing/printer_service.dart` - 블루투스 통신
- `lib/features/printing/print_queue.dart` - 큐 관리
- `lib/features/printing/print_preview.dart` - 미리보기

**구현**:
- 블루투스 자동 연결
- 2x3" 이미지 포맷 변환
- 인쇄 대기열 관리
- 오류 처리

### 4.2 QR 코드 및 클라우드 저장
**파일**:
- `lib/features/sharing/qr_generator.dart` - QR 생성
- `lib/features/sharing/cloud_storage.dart` - Firebase
- `lib/features/sharing/download_page.dart` - 웹 페이지

**기능**:
- 고유 URL 생성
- Firebase Storage 업로드
- QR 코드 화면 표시
- 모바일 다운로드 페이지

---

## 🎛️ Phase 5: 관리자 기능 (2일)

### 5.1 관리자 제어 패널
**파일**:
- `lib/features/admin/admin_panel.dart` - 메인 패널
- `lib/features/admin/control_widgets.dart` - 제어 위젯

**기능**:
- 속도 슬라이더
- 프리셋 선택 버튼
- 실시간 파라미터 조정
- 긴급 정지 버튼

### 5.2 전시 통계
**파일**: `lib/features/admin/statistics_view.dart`
**통계 항목**:
- 참여자 수 카운트
- 평균 처리 시간
- 프린터 상태
- 시간별 통계

---

## 🧪 Phase 6: 테스트 및 최적화 (3일)

### 6.1 기능 테스트
- 카메라 → 드로잉 → 출력 전체 플로우
- 예외 상황 처리
- 성능 측정

### 6.2 현장 시뮬레이션
- 150명 처리 시뮬레이션
- 병목 지점 파악
- 최적화 적용

### 6.3 최종 점검
- 프린터 연동 안정성
- 네트워크 장애 대응
- 백업 시나리오

---

## 📊 우선순위 매트릭스

| 우선순위 | 기능 | 중요도 | 난이도 | 예상 시간 |
|---------|------|--------|--------|-----------|
| 1 | 패키지 설정 | 🔴 필수 | ⭐ | 1시간 |
| 2 | 알고리즘 포팅 | 🔴 필수 | ⭐⭐⭐ | 4시간 |
| 3 | 카메라 구현 | 🔴 필수 | ⭐⭐ | 3시간 |
| 4 | 스파이럴 렌더링 | 🔴 필수 | ⭐⭐⭐ | 5시간 |
| 5 | 프린터 연동 | 🔴 필수 | ⭐⭐⭐ | 4시간 |
| 6 | QR 시스템 | 🟡 중요 | ⭐⭐ | 3시간 |
| 7 | 관리자 패널 | 🟡 중요 | ⭐ | 2시간 |
| 8 | 통계 시스템 | 🟢 선택 | ⭐ | 2시간 |

---

## 🎯 마일스톤

### Week 1
- ✅ 프로젝트 구조 완성
- ⏳ 핵심 알고리즘 구현
- ⏳ 카메라 기능 완성
- ⏳ 기본 드로잉 동작

### Week 2
- ⏳ 프린터 연동 완성
- ⏳ QR/클라우드 시스템
- ⏳ 관리자 기능
- ⏳ 통합 테스트

### Week 3
- ⏳ 성능 최적화
- ⏳ 현장 테스트
- ⏳ 버그 수정
- ⏳ 최종 배포

---

## 💡 리스크 관리

### 기술적 리스크
- **프린터 호환성**: 사전 테스트 필수
- **카메라 권한**: macOS 설정 확인
- **성능 이슈**: 프로파일링 도구 활용

### 운영 리스크
- **대기 줄 관리**: 속도 프리셋 활용
- **프린터 용지**: 200장 이상 준비
- **네트워크 장애**: 로컬 저장 후 일괄 업로드

---

## 🚀 다음 단계

**즉시 시작 가능한 작업**:
1. **pubspec.yaml 패키지 추가** (30분)
2. **드로잉 설정 모델 정의** (1시간)
3. **Processing 알고리즘 포팅 시작** (2-3시간)

**병렬 진행 가능**:
- UI 디자인 작업
- Firebase 프로젝트 설정
- 프린터 SDK 문서 검토