import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nemonic_sdk/n_printer.dart';

/// 앱 설정 관리 서비스
/// 카메라 및 프린터 설정을 영구 저장하여 재실행 시 자동 로드
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();
  
  static const String _keyIsFirstRun = 'is_first_run';
  static const String _keySelectedCamera = 'selected_camera';
  static const String _keySelectedPrinterName = 'selected_printer_name';
  static const String _keySelectedPrinterMac = 'selected_printer_mac';
  static const String _keySelectedPrinterType = 'selected_printer_type';
  static const String _keyDrawingDuration = 'drawing_duration';
  
  /// 첫 실행 여부 확인
  Future<bool> isFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsFirstRun) ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 첫 실행 확인 오류: $e');
      }
      return true; // 오류 시 첫 실행으로 처리
    }
  }
  
  /// 설정 저장 (프린터는 선택사항)
  Future<void> saveSettings({
    required String selectedCamera,
    NPrinter? selectedPrinter, // null 허용
    int? drawingDuration, // 드로잉 지속 시간 (초)
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 첫 실행 완료 표시
      await prefs.setBool(_keyIsFirstRun, false);
      
      // 카메라 설정 저장
      await prefs.setString(_keySelectedCamera, selectedCamera);
      
      // 프린터 설정 저장 (있는 경우만)
      if (selectedPrinter != null) {
        await prefs.setString(_keySelectedPrinterName, selectedPrinter.getName());
        await prefs.setString(_keySelectedPrinterMac, selectedPrinter.getMacAddress());
        await prefs.setInt(_keySelectedPrinterType, selectedPrinter.getType().index);
      } else {
        // 프린터 설정 초기화
        await prefs.remove(_keySelectedPrinterName);
        await prefs.remove(_keySelectedPrinterMac);
        await prefs.remove(_keySelectedPrinterType);
      }
      
      // 드로잉 지속 시간 저장
      if (drawingDuration != null) {
        await prefs.setInt(_keyDrawingDuration, drawingDuration);
      }
      
      if (kDebugMode) {
        print('✅ 설정 저장 완료');
        print('📷 카메라: $selectedCamera');
        if (selectedPrinter != null) {
          print('🖨️ 프린터: ${selectedPrinter.getName()} (${selectedPrinter.getMacAddress()})');
        } else {
          print('🖨️ 프린터: 선택하지 않음');
        }
        if (drawingDuration != null) {
          print('⏱️ 드로잉 시간: ${drawingDuration}초');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 설정 저장 오류: $e');
      }
      rethrow;
    }
  }
  
  
  /// 저장된 카메라 설정 로드
  Future<String?> getSavedCamera() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySelectedCamera);
    } catch (e) {
      if (kDebugMode) {
        print('❌ 카메라 설정 로드 오류: $e');
      }
      return null;
    }
  }
  
  /// 저장된 프린터 설정 로드
  Future<NPrinter?> getSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final name = prefs.getString(_keySelectedPrinterName);
      final mac = prefs.getString(_keySelectedPrinterMac);
      final typeIndex = prefs.getInt(_keySelectedPrinterType);
      
      if (name == null || mac == null || typeIndex == null) {
        return null;
      }
      
      // NPrinter 객체 재구성
      final printer = NPrinter();
      printer.setName(name);
      printer.setMacAddress(mac);
      // Note: NPrinterType enum 값으로 타입 설정 필요
      
      if (kDebugMode) {
        print('📱 저장된 프린터 로드: $name ($mac)');
      }
      
      return printer;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 프린터 설정 로드 오류: $e');
      }
      return null;
    }
  }
  
  /// 저장된 드로잉 지속 시간 로드 (기본값: 45초)
  Future<int> getSavedDrawingDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyDrawingDuration) ?? 45; // 기본값 45초
    } catch (e) {
      if (kDebugMode) {
        print('❌ 드로잉 지속 시간 로드 오류: $e');
      }
      return 45; // 오류 시 기본값
    }
  }
  
  /// 설정 초기화 (디버그용)
  Future<void> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (kDebugMode) {
        print('🔄 설정 초기화 완료');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 설정 초기화 오류: $e');
      }
    }
  }
  
  /// 설정 상태 확인 (디버그용)
  Future<void> printSettings() async {
    if (!kDebugMode) return;
    
    try {
      final isFirst = await isFirstRun();
      final camera = await getSavedCamera();
      final printer = await getSavedPrinter();
      final duration = await getSavedDrawingDuration();
      
      print('=== 설정 상태 ===');
      print('첫 실행: $isFirst');
      print('카메라: $camera');
      print('프린터: ${printer?.getName()} (${printer?.getMacAddress()})');
      print('드로잉 시간: ${duration}초');
      print('================');
      
    } catch (e) {
      print('❌ 설정 상태 확인 오류: $e');
    }
  }
}