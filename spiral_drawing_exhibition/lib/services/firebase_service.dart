import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage 서비스
/// 이미지 업로드 및 URL 생성 담당
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  // 웹 환경에서는 Firebase 비활성화
  FirebaseStorage? get _storage {
    if (kIsWeb) {
      if (kDebugMode) {
        print('🌐 웹 환경에서는 Firebase Storage를 사용할 수 없습니다.');
      }
      return null;
    }
    return FirebaseStorage.instance;
  }
  
  /// 이미지를 Firebase Storage에 업로드
  /// 
  /// 자동으로 폴더 구조 생성:
  /// artworks/2025/09/timestamp_random.png
  Future<Map<String, String>> uploadArtwork(Uint8List imageBytes) async {
    // 웹 환경에서는 Firebase 사용 불가
    if (kIsWeb) {
      if (kDebugMode) {
        print('🌐 웹 환경에서는 Firebase Storage를 사용할 수 없습니다. 로컬 저장소 사용.');
      }
      // 웹 환경에서는 임시 데이터 반환
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final random = Random().nextInt(10000);
      return {
        'url': 'web://local-storage/artwork_${timestamp}_$random.png',
        'path': 'web/local/${timestamp}_$random.png',
        'artworkId': '${timestamp}_$random',
        'fileName': 'artwork_${timestamp}_$random.png',
      };
    }
    
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage를 초기화할 수 없습니다.');
    }
    
    try {
      // 인증 상태 확인 (키체인 오류가 있어도 업로드 시도)
      final user = FirebaseAuth.instance.currentUser;
      if (kDebugMode) {
        if (user != null) {
          print('Firebase 인증 상태: 로그인됨 (UID: ${user.uid})');
        } else {
          print('Firebase 인증 상태: 비로그인 (익명 업로드 시도)');
        }
      }
      // 현재 시간 기반 파일명 생성
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final random = Random().nextInt(10000);
      final fileName = '${timestamp}_${random.toString().padLeft(4, '0')}.png';
      
      // 경로 생성 (자동으로 폴더 구조가 생성됨)
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      
      // Firebase Storage 참조 생성
      final ref = storage
          .ref()
          .child('artworks')
          .child(year)
          .child(month)
          .child(fileName);
      
      if (kDebugMode) {
        print('Firebase Storage 업로드 시작: artworks/$year/$month/$fileName');
      }
      
      // 메타데이터 설정 (최적화: 필수 항목만)
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'artworkId': '${timestamp}_$random',
        },
      );
      
      // 업로드 실행
      final uploadTask = ref.putData(imageBytes, metadata);
      
      // 업로드 진행률 모니터링 (최적화: 25% 단위로만 로깅)
      if (kDebugMode) {
        int lastLoggedProgress = -1;
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = ((snapshot.bytesTransferred / snapshot.totalBytes) * 100).round();
          if (progress >= lastLoggedProgress + 25) { // 25% 단위로만 로깅
            print('📤 업로드 진행: ${progress}%');
            lastLoggedProgress = progress;
          }
        });
      }
      
      // 업로드 완료 대기
      final snapshot = await uploadTask;
      
      // 다운로드 URL 가져오기
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Firebase Storage 업로드 완료!');
        print('URL: $downloadUrl');
      }
      
      // 결과 반환
      return {
        'url': downloadUrl,
        'path': 'artworks/$year/$month/$fileName',
        'artworkId': '${timestamp}_$random',
        'fileName': fileName,
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Storage 업로드 실패: $e');
      }
      throw Exception('이미지 업로드 실패: $e');
    }
  }
  
  /// Storage에서 이미지 삭제 (선택적)
  Future<void> deleteArtwork(String path) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('🌐 웹 환경에서는 이미지 삭제를 지원하지 않습니다.');
      }
      return;
    }
    
    final storage = _storage;
    if (storage == null) return;
    
    try {
      final ref = storage.ref().child(path);
      await ref.delete();
      if (kDebugMode) {
        print('이미지 삭제 완료: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('이미지 삭제 실패: $e');
      }
    }
  }
  
  /// 특정 월의 작품 목록 가져오기 (선택적)
  Future<List<String>> listArtworks(int year, int month) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('🌐 웹 환경에서는 작품 목록 조회를 지원하지 않습니다.');
      }
      return [];
    }
    
    final storage = _storage;
    if (storage == null) return [];
    
    try {
      final ref = storage
          .ref()
          .child('artworks')
          .child(year.toString())
          .child(month.toString().padLeft(2, '0'));
      
      final result = await ref.listAll();
      final urls = <String>[];
      
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      if (kDebugMode) {
        print('작품 목록 가져오기 실패: $e');
      }
      return [];
    }
  }
}