import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage 서비스
/// 이미지 업로드 및 URL 생성 담당
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// 이미지를 Firebase Storage에 업로드
  /// 
  /// 자동으로 폴더 구조 생성:
  /// artworks/2025/09/timestamp_random.png
  Future<Map<String, String>> uploadArtwork(Uint8List imageBytes) async {
    try {
      // 현재 시간 기반 파일명 생성
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final random = Random().nextInt(10000);
      final fileName = '${timestamp}_${random.toString().padLeft(4, '0')}.png';
      
      // 경로 생성 (자동으로 폴더 구조가 생성됨)
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      
      // Firebase Storage 참조 생성
      final ref = _storage
          .ref()
          .child('artworks')
          .child(year)
          .child(month)
          .child(fileName);
      
      if (kDebugMode) {
        print('Firebase Storage 업로드 시작: artworks/$year/$month/$fileName');
      }
      
      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'createdAt': now.toIso8601String(),
          'artworkId': '${timestamp}_$random',
          'exhibition': 'ALL IN',
        },
      );
      
      // 업로드 실행
      final uploadTask = ref.putData(imageBytes, metadata);
      
      // 업로드 진행률 모니터링 (선택적)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        if (kDebugMode) {
          print('업로드 진행률: ${progress.toStringAsFixed(0)}%');
        }
      });
      
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
    try {
      final ref = _storage.ref().child(path);
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
    try {
      final ref = _storage
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