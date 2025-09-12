# Firebase App Distribution 설정 가이드

## 1. Firebase 프로젝트 설정

### Firebase Console에서:
1. [Firebase Console](https://console.firebase.google.com) 접속
2. "프로젝트 만들기" 또는 기존 프로젝트 선택
3. 좌측 메뉴에서 "App Distribution" 클릭
4. "시작하기" 클릭

### iOS 앱 등록:
1. "iOS 앱 추가" 버튼 클릭
2. Bundle ID: `com.kimjungho.spiralDrawingExhibition` 입력
3. 앱 닉네임: "Spiral Drawing Exhibition" 입력
4. "앱 등록" 클릭
5. GoogleService-Info.plist 다운로드 (iOS 폴더에 추가)

## 2. Firebase 로그인

```bash
# Firebase 로그인
firebase login

# 프로젝트 초기화 (프로젝트 폴더에서)
firebase init
```

## 3. App Distribution 설정

Firebase Console에서:
1. App Distribution → "테스터 및 그룹"
2. "테스터 추가" 클릭
3. 테스터 이메일 추가
4. 그룹 만들기 (예: "beta-testers")

## 4. IPA 업로드 방법

### 방법 1: Firebase CLI 사용
```bash
# IPA 파일 업로드
firebase appdistribution:distribute build/ios/ipa/spiral_drawing_exhibition.ipa \
  --app YOUR_APP_ID \
  --groups "beta-testers" \
  --release-notes "새로운 테스트 빌드"
```

### 방법 2: Firebase Console 사용
1. App Distribution → "릴리스"
2. "새 릴리스" 버튼 클릭
3. IPA 파일 드래그 앤 드롭
4. 테스터 그룹 선택
5. 릴리스 노트 작성
6. "배포" 클릭

## 5. 테스터가 앱 설치하는 방법

### iPad에서:
1. 초대 이메일 확인
2. "테스터 되기" 링크 클릭
3. Firebase App Distribution 프로필 설치
   - 설정 → 일반 → 프로파일 및 기기 관리
   - Firebase App Distribution 프로필 설치
4. 다시 이메일의 "앱 다운로드" 링크 클릭
5. 앱 설치

## 6. 앱 ID 찾기

Firebase Console에서:
1. 프로젝트 설정 (톱니바퀴 아이콘)
2. "일반" 탭
3. iOS 앱 섹션에서 "앱 ID" 확인
   - 형식: `1:123456789:ios:abcdef123456`

## 7. 빠른 배포 스크립트

`deploy.sh` 파일 생성:
```bash
#!/bin/bash
# Flutter 빌드
flutter build ipa --release --export-method=ad-hoc

# Firebase 배포
firebase appdistribution:distribute build/ios/ipa/*.ipa \
  --app "YOUR_APP_ID" \
  --groups "beta-testers" \
  --release-notes "버전 1.0.0 테스트"
```

## 주의사항

- Ad Hoc 빌드 필요 (App Store 빌드와 다름)
- 테스터 디바이스 UDID 등록 필요할 수 있음
- 프로비저닝 프로파일 확인 필요
- 첫 설치 시 프로필 설치 필수

## 문제 해결

### "앱을 설치할 수 없음" 오류
1. 프로비저닝 프로파일 확인
2. 디바이스 UDID 등록 확인
3. Ad Hoc 빌드 여부 확인

### 프로필 설치 안됨
1. 설정 → 일반 → 프로파일 및 기기 관리
2. Firebase 프로필 수동 설치
3. 신뢰 설정

## 유용한 링크
- [Firebase Console](https://console.firebase.google.com)
- [App Distribution 문서](https://firebase.google.com/docs/app-distribution)
- [iOS 배포 가이드](https://firebase.google.com/docs/app-distribution/ios/distribute-console)