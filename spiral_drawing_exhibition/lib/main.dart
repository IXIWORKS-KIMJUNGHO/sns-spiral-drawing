import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/drawing/drawing_provider.dart';
import 'features/camera/camera_screen.dart';
import 'features/setup/setup_screen.dart';
import 'services/settings_service.dart';
import 'widgets/loading_video_screen.dart';

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
    
    // 익명 인증으로 로그인 (실패해도 앱 실행은 계속)
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (kDebugMode) {
        print('익명 인증 성공! UID: ${userCredential.user?.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('익명 인증 실패: $e');
        if (e.toString().contains('keychain-error')) {
          print('ℹ️  키체인 접근 오류: 앱이 키체인 접근 권한 없이도 실행됩니다.');
          print('   Firebase Storage 기능은 제한될 수 있습니다.');
        }
      }
      // 인증 실패해도 앱은 계속 실행
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
        home: const AppRouter(),
        routes: {
          '/camera': (context) => const CameraScreen(),
          '/setup': (context) => const SetupScreen(),
        },
      ),
    );
  }
}

/// 앱 라우팅 관리 위젯
/// 첫 실행 시 설정 화면, 이후에는 카메라 화면으로 이동
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final SettingsService _settingsService = SettingsService();
  
  @override
  Widget build(BuildContext context) {
    return LoadingScreenManager(
      minimumLoadingTime: const Duration(milliseconds: 2500), // 2.5초 최소 로딩
      buildNextScreen: () async {
        // 🔧 디버그 모드에서 설정 테스트를 위해 설정 초기화
        if (kDebugMode) {
          await _settingsService.resetSettings();
          if (kDebugMode) {
            print('🔄 디버그 모드: 설정이 초기화되어 설정 페이지가 표시됩니다.');
          }
        }
        
        // 설정 확인
        final isFirstRun = await _settingsService.isFirstRun();
        
        if (kDebugMode) {
          print(isFirstRun ? '🆕 첫 실행 - 설정 화면으로 이동' : '🔄 재실행 - 카메라 화면으로 이동');
        }
        
        // 첫 실행 시 설정 화면, 이후 카메라 화면 반환
        return isFirstRun ? const SetupScreen() : const CameraScreen();
      },
    );
  }
}