import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nemonic_sdk/i_n_printer_controller.dart';
import 'package:nemonic_sdk/i_n_printer_scan_controller.dart';
import 'package:nemonic_sdk/n_print_info.dart';
import 'package:nemonic_sdk/n_printer.dart';
import 'package:nemonic_sdk/n_printer_controller.dart';
import 'package:nemonic_sdk/n_printer_scan_controller.dart';
import 'package:nemonic_sdk/constants/n_result.dart';
import 'dart:ui' as ui;

/// 메모닉 프린터 서비스
/// 프린터 스캔, 연결, 인쇄를 담당
/// 연결 상태 유지 기능 포함
class PrinterService implements INPrinterController, INPrinterScanController {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();
  
  NPrinterScanController? _scanController;
  NPrinterController? _printerController;
  NPrinter? _connectedPrinter;
  
  // 연결 상태 추가
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = '';
  
  // 프린터 발견 및 상태 콜백
  Function(NPrinter printer)? onPrinterFound;
  Function(int current, int total)? onPrintProgress;
  Function(bool success, String message)? onPrintComplete;
  Function()? onDisconnected;
  Function(String status)? onConnectionStatusChanged; // 연결 상태 변경 콜백 추가
  
  /// 프린터 연결 상태 확인 (개선된 버전)
  bool isConnected() {
    return _isConnected && _connectedPrinter != null && _printerController != null;
  }
  
  /// 연결 중 상태 확인
  bool isConnecting() {
    return _isConnecting;
  }
  
  /// 연결 상태 메시지 가져오기
  String getConnectionStatus() {
    return _connectionStatus;
  }
  
  /// 연결된 프린터 정보 가져오기
  NPrinter? getConnectedPrinter() {
    return _connectedPrinter;
  }
  
  /// 사용 가능한 프린터 자동 스캔 및 연결
  /// 
  /// 자동화된 플로우:
  /// 1. 이미 연결된 프린터가 있으면 바로 인쇄
  /// 2. 프린터 스캔 시작
  /// 3. 첫 번째 발견된 프린터에 자동 연결
  /// 4. 연결 완료 후 이미지 인쇄
  Future<bool> autoConnectAndPrint(Uint8List imageBytes) async {
    try {
      if (kDebugMode) {
        print('🖨️ 메모닉 프린터 자동 연결 및 인쇄 시작');
      }
      
      // 이미 연결된 프린터가 있으면 바로 인쇄
      if (isConnected()) {
        if (kDebugMode) {
          print('✅ 이미 연결된 프린터 사용: ${_connectedPrinter!.getName()}');
        }
        return await printImage(imageBytes);
      }
      
      // 1. 프린터 스캔 시작
      final scanResult = await startPrinterScan();
      if (!scanResult) {
        if (kDebugMode) print('❌ 프린터 스캔 시작 실패');
        return false;
      }
      
      // 2. 프린터 발견 대기 (최대 10초)
      NPrinter? foundPrinter = await _waitForPrinter();
      if (foundPrinter == null) {
        if (kDebugMode) print('❌ 프린터를 찾을 수 없습니다');
        await stopPrinterScan();
        return false;
      }
      
      // 3. 스캔 중단
      await stopPrinterScan();
      
      // 4. 프린터 연결
      final connectResult = await connectToPrinter(foundPrinter);
      if (!connectResult) {
        if (kDebugMode) print('❌ 프린터 연결 실패');
        return false;
      }
      
      // 5. 이미지 인쇄
      final printResult = await printImage(imageBytes);
      if (!printResult) {
        if (kDebugMode) print('❌ 이미지 인쇄 실패');
        return false;
      }
      
      if (kDebugMode) {
        print('✅ 프린터 연결 및 인쇄 완료');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 프린터 서비스 오류: $e');
      }
      return false;
    }
  }
  
  /// 프린터 스캔 시작
  Future<bool> startPrinterScan() async {
    try {
      _scanController = NPrinterScanController(this);
      final result = await _scanController!.startScan();
      
      if (result == NResult.ok.code) {
        if (kDebugMode) print('🔍 프린터 스캔 시작됨');
        return true;
      } else {
        if (kDebugMode) print('❌ 프린터 스캔 시작 실패: $result');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ 프린터 스캔 시작 오류: $e');
      return false;
    }
  }
  
  /// 프린터 스캔 중단
  Future<void> stopPrinterScan() async {
    try {
      await _scanController?.stopScan();
      _scanController = null;
      if (kDebugMode) print('🔍 프린터 스캔 중단됨');
    } catch (e) {
      if (kDebugMode) print('❌ 프린터 스캔 중단 오류: $e');
    }
  }
  
  /// 프린터 발견 대기 (최대 10초)
  Future<NPrinter?> _waitForPrinter() async {
    NPrinter? foundPrinter;
    
    // 프린터 발견 콜백 설정
    onPrinterFound = (printer) {
      foundPrinter = printer;
      if (kDebugMode) {
        print('📱 프린터 발견: ${printer.getName()}');
      }
    };
    
    // 최대 10초 대기
    for (int i = 0; i < 100; i++) {
      if (foundPrinter != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    onPrinterFound = null;
    return foundPrinter;
  }
  
  /// 프린터 연결 (개선된 버전 - 상태 추적 포함)
  Future<bool> connectToPrinter(NPrinter printer) async {
    try {
      _isConnecting = true;
      _isConnected = false;
      _connectionStatus = '${printer.getName()} 연결 중...';
      onConnectionStatusChanged?.call(_connectionStatus);
      
      _printerController = NPrinterController(this);
      final result = await _printerController!.connect(printer);
      
      if (result == NResult.ok.code) {
        _connectedPrinter = printer;
        _isConnecting = false;
        _isConnected = true;
        _connectionStatus = '${printer.getName()} 연결됨 ✅';
        onConnectionStatusChanged?.call(_connectionStatus);
        
        if (kDebugMode) {
          print('🔗 프린터 연결 성공: ${printer.getName()}');
        }
        return true;
      } else {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = '${printer.getName()} 연결 실패 ❌';
        onConnectionStatusChanged?.call(_connectionStatus);
        
        if (kDebugMode) {
          print('❌ 프린터 연결 실패: $result');
        }
        return false;
      }
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionStatus = '연결 오류: $e ❌';
      onConnectionStatusChanged?.call(_connectionStatus);
      
      if (kDebugMode) print('❌ 프린터 연결 오류: $e');
      return false;
    }
  }
  
  /// 이미지를 시계방향으로 90도 회전
  Future<Uint8List> _rotateImage90Degrees(Uint8List imageBytes) async {
    try {
      // 이미지 디코딩
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      // 회전된 이미지 크기 (가로와 세로가 바뀜)
      final int rotatedWidth = originalImage.height;
      final int rotatedHeight = originalImage.width;
      
      // 새로운 캔버스 생성
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // 캔버스 중심점으로 이동
      canvas.translate(rotatedWidth / 2, rotatedHeight / 2);
      
      // 시계방향 90도 회전
      canvas.rotate(3.14159265359 / 2); // 90도 (π/2 라디안)
      
      // 이미지를 중심점 기준으로 그리기
      canvas.drawImage(
        originalImage, 
        Offset(-originalImage.width / 2, -originalImage.height / 2), 
        Paint()
      );
      
      // Picture을 Image로 변환
      final ui.Picture picture = recorder.endRecording();
      final ui.Image rotatedImage = await picture.toImage(rotatedWidth, rotatedHeight);
      
      // PNG 바이트로 변환
      final ByteData? rotatedByteData = await rotatedImage.toByteData(format: ui.ImageByteFormat.png);
      if (rotatedByteData == null) {
        throw Exception('회전된 이미지를 바이트로 변환 실패');
      }
      
      if (kDebugMode) {
        print('🔄 이미지 90도 회전 완료: ${originalImage.width}x${originalImage.height} → ${rotatedWidth}x$rotatedHeight');
      }
      
      return rotatedByteData.buffer.asUint8List();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 이미지 회전 실패: $e');
        print('원본 이미지 사용');
      }
      return imageBytes; // 회전 실패 시 원본 이미지 반환
    }
  }

  /// 이미지 인쇄 (강화된 디버깅 및 설정 최적화)
  Future<bool> printImage(Uint8List imageBytes, {bool enableRotation = true}) async {
    // 재시도 로직 추가 (최대 3회 시도)
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        if (kDebugMode) print('🖨️ 인쇄 시도 $attempt/3');
        
        if (!isConnected()) {
          if (kDebugMode) print('❌ 프린터가 연결되지 않음');
          return false;
        }
        
        if (kDebugMode) {
          print('🖨️ === 인쇄 시작 디버깅 정보 ===');
          print('연결된 프린터: ${_connectedPrinter?.getName()}');
          print('프린터 MAC 주소: ${_connectedPrinter?.getMacAddress()}');
          print('이미지 데이터 크기: ${imageBytes.length} bytes');
          print('이미지 데이터 첫 10바이트: ${imageBytes.take(10).toList()}');
          print('프린터 컨트롤러 상태: ${_printerController != null ? "활성" : "비활성"}');
          print('연결 상태: isConnected=${isConnected()}, _isConnected=$_isConnected');
          print('이미지 회전 기능 (90도 시계방향): ${enableRotation ? "활성" : "비활성"}');
        }
        
        // 🔄 이미지 회전 처리 (선택적)
        Uint8List finalImageBytes = imageBytes;
        if (enableRotation) {
          if (kDebugMode) print('🔄 프린터 출력을 위한 90도 시계방향 회전 처리 중...');
          finalImageBytes = await _rotateImage90Degrees(imageBytes);
        } else {
          if (kDebugMode) print('📷 원본 이미지 사용 (회전 비활성화)');
        }
      
        // 인쇄 정보 설정 (기본값 사용으로 호환성 극대화)
        final printInfo = NPrintInfo(_connectedPrinter!)
            .setImage(finalImageBytes) // 처리된 이미지 사용
            .setCopies(1)
            .setEnableDither(false) // 디더링 비활성화 (호환성 향상)
            .setEnableLastPageCut(true); // 마지막 페이지 컷 활성화
        
        if (kDebugMode) print('📋 인쇄 설정 완료, 인쇄 요청 전송 중...');
        
        final result = await _printerController!.print(printInfo);
        
        if (kDebugMode) {
          print('📤 인쇄 요청 결과 코드: $result');
          print('NResult.ok.code 비교: $result == ${NResult.ok.code}');
        }
        
        if (result == NResult.ok.code) {
          if (kDebugMode) print('✅ 인쇄 명령 전송 성공 - 프린터에서 처리 중');
          return true;
        } else {
          if (kDebugMode) {
            print('❌ 인쇄 명령 전송 실패 (시도 $attempt/3)');
            print('에러 코드: $result');
            print('가능한 원인: 이미지 형식, 프린터 용지 부족, 설정 호환성');
          }
          
          // 마지막 시도가 아니면 잠시 대기 후 재시도
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 1000 * attempt)); // 점진적 지연
            continue;
          } else {
            return false; // 모든 시도 실패
          }
        }
        
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('❌ 이미지 인쇄 예외 발생 (시도 $attempt/3): $e');
          print('스택 트레이스: $stackTrace');
        }
        
        // 마지막 시도가 아니면 잠시 대기 후 재시도
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
          continue;
        } else {
          return false; // 모든 시도 실패
        }
      }
    }
    
    return false; // 모든 재시도 실패
  }
  
  /// 프린터 연결 해제 (개선된 버전 - 상태 초기화 포함)
  Future<void> disconnect() async {
    try {
      await _printerController?.disconnect();
      _printerController = null;
      _connectedPrinter = null;
      _isConnecting = false;
      _isConnected = false;
      _connectionStatus = '연결 해제됨';
      onConnectionStatusChanged?.call(_connectionStatus);
      
      if (kDebugMode) print('🔗 프린터 연결 해제됨');
    } catch (e) {
      if (kDebugMode) print('❌ 프린터 연결 해제 오류: $e');
    }
  }
  
  // INPrinterScanController 구현
  @override
  void deviceFound(NPrinter printer) {
    onPrinterFound?.call(printer);
  }
  
  // INPrinterController 구현
  @override
  void disconnected() {
    _connectedPrinter = null;
    _isConnecting = false;
    _isConnected = false;
    _connectionStatus = '연결이 끊어짐 ⚠️';
    onConnectionStatusChanged?.call(_connectionStatus);
    
    if (kDebugMode) print('🔗 프린터 연결이 끊어짐');
    onDisconnected?.call();
  }
  
  @override
  void printProgress(int index, int total, int result) {
    final progress = ((index / total) * 100).round();
    if (kDebugMode) print('📊 인쇄 진행률: $progress% ($index/$total)');
    onPrintProgress?.call(index, total);
  }
  
  @override
  void printComplete(int result) {
    final success = result == NResult.ok.code;
    final message = success ? '인쇄 완료' : '인쇄 실패: $result';
    
    if (kDebugMode) {
      print(success ? '✅ 인쇄 완료!' : '❌ 인쇄 실패: $result');
    }
    
    onPrintComplete?.call(success, message);
  }
}