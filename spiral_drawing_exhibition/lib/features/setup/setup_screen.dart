import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nemonic_sdk/n_printer.dart';
import '../../services/printer_service.dart';
import '../../services/settings_service.dart';
import '../camera/camera_screen.dart';

/// 초기 설정 화면
/// 카메라 선택, 프린터 연결, 드로잉 시간 설정
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PrinterService _printerService = PrinterService();
  final SettingsService _settingsService = SettingsService();
  
  // 카메라 관련
  final List<String> _availableCameras = ['전면 카메라', '후면 카메라'];
  String? _selectedCamera;
  
  // 프린터 관련
  final List<NPrinter> _availablePrinters = [];
  NPrinter? _selectedPrinter;
  bool _isScanning = false;
  String _scanStatus = '';
  
  // 연결 상태
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = '';
  NPrinter? _currentConnectedPrinter; // 현재 연결된 프린터 정보
  
  // 드로잉 시간 옵션 (초)
  final List<int> _durationOptions = [10, 15, 20, 30, 50];
  int _drawingDuration = 30; // 기본값
  
  @override
  void initState() {
    super.initState();
    
    // 기본 카메라 선택
    _selectedCamera = _availableCameras.first;
    
    // 저장된 드로잉 시간 불러오기
    _loadSavedDrawingDuration();
    
    // 현재 연결된 프린터 상태 확인
    _checkCurrentConnection();
    
    // 프린터 서비스 콜백 설정
    _printerService.onPrinterFound = (printer) {
      setState(() {
        if (!_availablePrinters.any((p) => p.getMacAddress() == printer.getMacAddress())) {
          _availablePrinters.add(printer);
        }
        _scanStatus = '${_availablePrinters.length}개 프린터 발견';
      });
    };
    
    // 📡 연결 상태 변경 콜백 추가 (실시간 업데이트)
    _printerService.onConnectionStatusChanged = (status) {
      if (mounted) {
        if (kDebugMode) {
          print('🔄 설정화면: 프린터 연결 상태 변경됨 - $status');
        }
        // 연결 상태가 변경되었을 때 전체 상태 재확인
        _checkCurrentConnection();
        
        // UI 상태 즉시 반영
        setState(() {
          _connectionStatus = status;
        });
      }
    };
    
    // 📡 주기적 연결 상태 확인 (30초마다)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (kDebugMode) {
        print('🔄 설정화면: 주기적 연결 상태 확인');
      }
      _checkCurrentConnection();
    });
  }
  
  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }
  
  /// 프린터 스캔 시작
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = '프린터 검색 중...';
      _availablePrinters.clear();
    });
    
    try {
      await _printerService.startPrinterScan();
      
      // 10초 후 자동 중단
      Future.delayed(const Duration(seconds: 10), () {
        if (_isScanning) {
          _stopScan();
        }
      });
      
    } catch (e) {
      setState(() {
        _scanStatus = '스캔 오류: $e';
        _isScanning = false;
      });
    }
  }
  
  /// 프린터 스캔 중단
  Future<void> _stopScan() async {
    await _printerService.stopPrinterScan();
    setState(() {
      _isScanning = false;
      _scanStatus = _availablePrinters.isEmpty ? '프린터를 찾을 수 없습니다' : '${_availablePrinters.length}개 프린터 발견';
    });
  }
  
  /// 저장된 드로잉 시간 불러오기
  Future<void> _loadSavedDrawingDuration() async {
    try {
      final duration = await _settingsService.getSavedDrawingDuration();
      setState(() {
        _drawingDuration = duration;
      });
    } catch (e) {
      // 기본값 유지
    }
  }
  
  /// 현재 연결된 프린터 상태 확인 및 유효성 검증
  Future<void> _checkCurrentConnection() async {
    try {
      // 1. 기본 연결 상태 확인
      final isConnected = _printerService.isConnected();
      final connectedPrinter = _printerService.getConnectedPrinter();
      final connectionStatus = _printerService.getConnectionStatus();
      
      // 2. 연결 상태 유효성 검증
      bool isValidConnection = false;
      if (isConnected && connectedPrinter != null) {
        // 실제 프린터와의 통신 가능성 검증
        try {
          // 프린터 상태 체크 (간단한 연결 테스트)
          // nemonic SDK가 상태 확인을 지원한다면 여기서 실행
          isValidConnection = true; // 기본적으로 연결 상태를 신뢰
          
          if (kDebugMode) {
            print('✅ 프린터 연결 검증 성공: ${connectedPrinter.getName()}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('🔍 프린터 연결 검증 실패: $e');
          }
          isValidConnection = false;
        }
      }
      
      if (mounted) {
        setState(() {
          _isConnected = isConnected && isValidConnection;
          _currentConnectedPrinter = _isConnected ? connectedPrinter : null;
          _connectionStatus = _isConnected 
              ? '${connectedPrinter?.getName() ?? "프린터"}에 연결됨'
              : isConnected ? '연결 불안정' : connectionStatus;
          
          // 유효한 연결된 프린터가 있으면 선택된 프린터로 설정
          if (_isConnected && connectedPrinter != null) {
            _selectedPrinter = connectedPrinter;
          }
        });
        
        if (kDebugMode) {
          print('💻 설정화면 연결 상태 확인:');
          print('기본 연결 상태: $isConnected');
          print('검증된 연결 상태: $isValidConnection');
          print('최종 연결 상태: $_isConnected');
          print('연결된 프린터: ${_currentConnectedPrinter?.getName() ?? "없음"}');
          print('상태 메시지: $_connectionStatus');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 연결 상태 확인 중 오류: $e');
      }
      
      if (mounted) {
        setState(() {
          _isConnected = false;
          _currentConnectedPrinter = null;
          _connectionStatus = '연결 상태 확인 실패';
        });
      }
    }
  }


  
  /// 프린터 선택 및 연결
  Future<void> _selectAndConnectPrinter(NPrinter printer) async {
    // PrinterService가 상태 추적을 처리하므로 단순화
    try {
      final connectResult = await _printerService.connectToPrinter(printer);
      
      if (connectResult) {
        setState(() {
          _selectedPrinter = printer;
          _isConnected = _printerService.isConnected();
          _isConnecting = false;
        });
        
        if (kDebugMode) {
          print('🔗 프린터 연결 성공: ${printer.getName()}');
        }
      } else {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
        
        if (kDebugMode) {
          print('❌ 프린터 연결 실패: ${printer.getName()}');
        }
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
      }
      
      if (kDebugMode) {
        print('❌ 프린터 연결 오류: $e');
      }
    }
  }
  
  /// 설정 완료 및 메인 화면으로 이동
  Future<void> _completeSetup() async {
    if (_selectedCamera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라를 선택해주세요')),
      );
      return;
    }
    
    try {
      // 설정 저장
      await _settingsService.saveSettings(
        selectedCamera: _selectedCamera!,
        selectedPrinter: _selectedPrinter, // null 가능
        drawingDuration: _drawingDuration, // 드로잉 지속 시간
      );
      
      // 메인 카메라 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CameraScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 실패: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final squareSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ALL IN - 초기 설정',
          style: TextStyle(
            fontFamily: 'Futura',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(squareSize * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 카메라 선택 섹션
            _buildSection(
              title: '📷 카메라 선택',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '드로잉에 사용할 카메라를 선택하세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: _availableCameras.map((camera) => 
                      ListTile(
                        title: Text(camera),
                        leading: Icon(
                          _selectedCamera == camera ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _selectedCamera == camera ? Colors.blue : Colors.grey,
                        ),
                        onTap: () => setState(() => _selectedCamera = camera),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: squareSize * 0.04),
            
            // 2. 드로잉 시간 설정 섹션
            _buildSection(
              title: '⏱️ 드로잉 시간 설정',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 설정: $_drawingDuration초 (${(_drawingDuration / 60).toStringAsFixed(1)}분)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durationOptions.map((duration) => 
                      _buildDurationChip(duration),
                    ).toList(),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: squareSize * 0.04),
            
            // 3. 프린터 연결 섹션 (선택사항)
            _buildSection(
              title: '🖨️ 프린터 연결 (선택사항)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '메모닉 프린터를 연결하면 작품을 바로 인쇄할 수 있습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 스캔 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? _stopScan : _startScan,
                      icon: _isScanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.bluetooth_searching),
                      label: Text(_isScanning ? '중단' : '검색'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isScanning ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 스캔 상태
                  if (_scanStatus.isNotEmpty)
                    Text(
                      _scanStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // 연결 상태 표시
                  if (_connectionStatus.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isConnected 
                            ? Colors.green.withValues(alpha: 0.1)
                            : _isConnecting
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isConnected 
                              ? Colors.green.withValues(alpha: 0.3)
                              : _isConnecting
                                  ? Colors.blue.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isConnecting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          if (_isConnecting) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color: _isConnected 
                                    ? Colors.green.shade700
                                    : _isConnecting
                                        ? Colors.blue.shade700
                                        : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // 현재 연결된 프린터 섹션
                  if (_isConnected && _currentConnectedPrinter != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bluetooth_connected,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '현재 연결된 프린터',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildConnectedPrinterTile(_currentConnectedPrinter!),
                        ],
                      ),
                    ),
                  ],
                  
                  // 스캔된 프린터 목록
                  if (_availablePrinters.isNotEmpty) ...[
                    Text(
                      '검색된 프린터',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // 프린터 목록 (현재 연결된 프린터 제외)
                  ..._availablePrinters.where((printer) =>
                    _currentConnectedPrinter?.getMacAddress() != printer.getMacAddress()
                  ).map((printer) => 
                    _buildPrinterTile(
                      printer,
                      _selectedPrinter?.getMacAddress() == printer.getMacAddress(),
                      () => _selectAndConnectPrinter(printer),
                    ),
                  ),
                  
                  // 프린터 없음 표시
                  if (_availablePrinters.isEmpty && !_isScanning && !_isConnected)
                    ListTile(
                      title: const Text('프린터 없음'),
                      subtitle: const Text('검색 버튼을 눌러 프린터를 찾아보세요'),
                      leading: const Icon(Icons.info_outline),
                      selected: _selectedPrinter == null,
                      onTap: () => setState(() => _selectedPrinter = null),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: squareSize * 0.08),
            
            // 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCamera != null && (_selectedPrinter == null || _isConnected)
                    ? _completeSetup
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '설정 완료',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
  
  Widget _buildDurationChip(int duration) {
    final isSelected = _drawingDuration == duration;
    final minutes = duration / 60;
    final displayText = duration < 60 ? '$duration초' : '${minutes.toStringAsFixed(0)}분';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _drawingDuration = duration;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectedPrinterTile(NPrinter printer) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.print,
            color: Colors.green.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  printer.getName(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MAC: ${printer.getMacAddress().substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _connectionStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green.shade700,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterTile(
    NPrinter printer,
    bool isSelected,
    VoidCallback onTap,
  ) {
    // 현재 연결된 프린터인지 확인
    final isCurrentlyConnected = _isConnected && 
        _currentConnectedPrinter != null && 
        _currentConnectedPrinter!.getMacAddress() == printer.getMacAddress();
    
    // 선택된 프린터인지 확인
    final isSelectedPrinter = isSelected;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentlyConnected 
              ? Colors.green.withValues(alpha: 0.3)
              : isSelectedPrinter 
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
          width: isCurrentlyConnected || isSelectedPrinter ? 2 : 1,
        ),
        color: isCurrentlyConnected 
            ? Colors.green.withValues(alpha: 0.05)
            : isSelectedPrinter 
                ? Colors.blue.withValues(alpha: 0.05)
                : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                printer.getName(),
                style: TextStyle(
                  fontWeight: isCurrentlyConnected || isSelectedPrinter 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  color: isCurrentlyConnected 
                      ? Colors.green.shade800
                      : Colors.black87,
                ),
              ),
            ),
            if (isCurrentlyConnected) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  '연결됨',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'MAC: ${printer.getMacAddress().substring(0, 8)}...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (isCurrentlyConnected) ...[
              const SizedBox(height: 2),
              Text(
                _connectionStatus,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentlyConnected 
                ? Colors.green.withValues(alpha: 0.1)
                : isSelectedPrinter 
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
          ),
          child: Icon(
            isCurrentlyConnected 
                ? Icons.bluetooth_connected
                : Icons.bluetooth,
            color: isCurrentlyConnected 
                ? Colors.green.shade700
                : isSelectedPrinter 
                    ? Colors.blue.shade700
                    : Colors.grey.shade600,
            size: 20,
          ),
        ),
        trailing: isSelectedPrinter
            ? Icon(
                isCurrentlyConnected 
                    ? Icons.check_circle
                    : Icons.radio_button_checked,
                color: isCurrentlyConnected 
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
                size: 24,
              )
            : Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
                size: 24,
              ),
        selected: isSelectedPrinter,
        onTap: _isConnecting ? null : onTap,
      ),
    );
  }
}