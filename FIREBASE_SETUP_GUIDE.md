# Firebase 설정 가이드

## 현재 상태
- ❌ GoogleService-Info.plist 파일이 없음 (iOS/macOS)
- ❌ google-services.json 파일이 없음 (Android - 현재 Android 빌드 미지원)
- ✅ Firebase SDK는 pubspec.yaml에 설정됨
- ✅ Firebase 초기화 코드는 main.dart에 구현됨

## Firebase 설정 방법

### 1. Firebase Console에서 프로젝트 생성/접근
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 기존 프로젝트 선택 또는 새 프로젝트 생성

### 2. iOS/macOS용 GoogleService-Info.plist 다운로드

#### 2.1 Firebase Console에서:
1. 프로젝트 설정 > 일반 탭으로 이동
2. iOS 앱이 없다면 "앱 추가" 클릭 > iOS 선택
3. iOS 번들 ID 입력: `com.example.spiralDrawingExhibition` (또는 실제 번들 ID)
4. `GoogleService-Info.plist` 파일 다운로드

#### 2.2 파일 위치:
**iOS 프로젝트:**
```
/Users/kimjungho/Documents/coding/sns-spiral-drawing/spiral_drawing_exhibition/ios/Runner/GoogleService-Info.plist
```

**macOS 프로젝트:**
```
/Users/kimjungho/Documents/coding/sns-spiral-drawing/spiral_drawing_exhibition/macos/Runner/GoogleService-Info.plist
```

### 3. Xcode에서 파일 추가 (macOS의 경우)
1. Xcode에서 프로젝트 열기:
   ```bash
   open /Users/kimjungho/Documents/coding/sns-spiral-drawing/spiral_drawing_exhibition/macos/Runner.xcworkspace
   ```
2. Runner 폴더에 GoogleService-Info.plist 드래그 앤 드롭
3. "Copy items if needed" 체크
4. Target: Runner 선택

### 4. Firebase 서비스 활성화
Firebase Console에서 필요한 서비스 활성화:
- **Firebase Storage**: 빌드 > Storage 메뉴에서 활성화
- **Authentication**: 빌드 > Authentication 메뉴에서 활성화
  - Sign-in method 탭에서 "익명" 활성화

### 5. Firebase Storage 규칙 설정
Storage > Rules 탭에서:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /artworks/{year}/{month}/{filename} {
      // 모든 사용자가 읽기 가능
      allow read: if true;
      // 인증된 사용자만 쓰기 가능 (익명 인증 포함)
      allow write: if request.auth != null;
    }
  }
}
```

### 6. 앱 실행 테스트
```bash
cd /Users/kimjungho/Documents/coding/sns-spiral-drawing/spiral_drawing_exhibition
flutter run -d macos
```

## 트러블슈팅

### Keychain 오류가 발생하는 경우:
```
keychain-error: SecKeychainItemImport failed with error -25308
```
이 오류는 macOS의 키체인 접근 권한 문제입니다. 해결 방법:
1. macOS 시스템 설정 > 개인정보 보호 및 보안 > 전체 디스크 접근 권한
2. 터미널 또는 IDE에 권한 부여
3. 또는 앱을 다시 빌드하여 키체인 접근 권한 요청

### Firebase 초기화 실패:
- GoogleService-Info.plist 파일이 올바른 위치에 있는지 확인
- Bundle ID가 Firebase 프로젝트와 일치하는지 확인
- Firebase Console에서 iOS/macOS 앱이 등록되어 있는지 확인

## 현재 코드 상태
- ✅ Firebase 초기화 코드 구현 완료
- ✅ 익명 인증 구현 완료
- ✅ Firebase Storage 업로드 기능 구현 완료
- ✅ 오류 처리 및 로깅 구현 완료

## 다음 단계
1. GoogleService-Info.plist 파일 다운로드 및 설치
2. Firebase Console에서 서비스 활성화
3. 앱 실행 및 테스트