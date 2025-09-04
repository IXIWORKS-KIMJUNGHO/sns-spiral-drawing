import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/drawing/drawing_provider.dart';
import 'features/camera/camera_screen.dart';

/// Flutter 앱의 진입점
/// 
/// 리얼타임 엔진과의 비교:
/// - Unity: Main Camera + GameManager 오브젝트
/// - Unreal: GameMode + PlayerController
/// - Processing: setup() 함수
/// - Flutter: main() 함수 + Widget 트리
void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase 초기화
    await Firebase.initializeApp();
    if (kDebugMode) {
      print('Firebase 초기화 성공!');
    }
    
    // 익명 인증으로 로그인
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (kDebugMode) {
        print('익명 인증 성공! UID: ${userCredential.user?.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('익명 인증 실패: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase 초기화 실패: $e');
      print('GoogleService-Info.plist 파일이 올바른 위치에 있는지 확인하세요.');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider 패턴으로 상태 관리
    // Unity의 Singleton이나 Processing의 전역 변수 역할
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrawingProvider()),
      ],
      child: MaterialApp(
        title: 'Spiral Drawing Exhibition',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const CameraScreen(),
      ),
    );
  }
}