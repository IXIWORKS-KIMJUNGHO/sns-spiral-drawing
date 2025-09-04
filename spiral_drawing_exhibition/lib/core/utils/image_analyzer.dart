import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';

/// 이미지 밝기 분석 유틸리티
/// 
/// Processing의 brightness() 함수와 동일한 역할
/// 이미지의 각 픽셀에서 밝기값을 추출하여 드로잉에 사용
class ImageAnalyzer {
  final ui.Image image;
  late final ByteData _byteData;
  late final int _width;
  late final int _height;
  bool _isInitialized = false;
  
  ImageAnalyzer(this.image) {
    _width = image.width;
    _height = image.height;
  }
  
  /// 이미지 데이터 초기화
  /// Processing: loadPixels()와 유사
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 이미지를 ByteData로 변환
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    
    if (data != null) {
      _byteData = data;
      _isInitialized = true;
    }
  }
  
  /// 특정 좌표의 밝기값 가져오기 (0.0 ~ 1.0)
  /// 
  /// Processing의 brightness(img.get(x, y))와 동일
  /// 흑백 이미지인 경우 R 채널만 사용 (R=G=B이므로)
  double getBrightness(double x, double y) {
    if (!_isInitialized) {
      return 0.5; // 초기화되지 않은 경우 중간값 반환
    }
    
    // 이미지 범위 내로 좌표 제한
    int pixelX = (x.clamp(0.0, _width - 1.0)).toInt();
    int pixelY = (y.clamp(0.0, _height - 1.0)).toInt();
    
    // 픽셀 인덱스 계산 (RGBA 형식이므로 4바이트씩)
    int pixelIndex = (pixelY * _width + pixelX) * 4;
    
    // 흑백 이미지인 경우 R 채널만 읽어도 충분 (R=G=B)
    // 이미 흑백 변환된 이미지이므로 직접 밝기값 사용
    int brightness = _byteData.getUint8(pixelIndex);
    
    // 0.0 ~ 1.0 범위로 정규화
    return brightness / 255.0;
  }
  
  /// 정규화된 좌표(0.0 ~ 1.0)로 밝기값 가져오기
  /// 캔버스 크기와 무관하게 이미지를 샘플링
  double getBrightnessNormalized(double normalizedX, double normalizedY) {
    double x = normalizedX * (_width - 1);
    double y = normalizedY * (_height - 1);
    return getBrightness(x, y);
  }
  
  /// 이선형 보간을 사용한 부드러운 밝기값 가져오기
  /// 픽셀 사이의 값을 보간하여 더 부드러운 결과 생성
  double getBrightnessSmooth(double x, double y) {
    if (!_isInitialized) {
      return 0.5;
    }
    
    // 좌표를 이미지 범위 내로 제한
    x = x.clamp(0.0, _width - 1.0);
    y = y.clamp(0.0, _height - 1.0);
    
    // 정수 부분과 소수 부분 분리
    int x0 = x.floor();
    int y0 = y.floor();
    int x1 = min(x0 + 1, _width - 1);
    int y1 = min(y0 + 1, _height - 1);
    
    double fx = x - x0;
    double fy = y - y0;
    
    // 네 모서리 픽셀의 밝기값 가져오기
    double b00 = getBrightness(x0.toDouble(), y0.toDouble());
    double b10 = getBrightness(x1.toDouble(), y0.toDouble());
    double b01 = getBrightness(x0.toDouble(), y1.toDouble());
    double b11 = getBrightness(x1.toDouble(), y1.toDouble());
    
    // 이선형 보간
    double b0 = b00 * (1 - fx) + b10 * fx;
    double b1 = b01 * (1 - fx) + b11 * fx;
    double brightness = b0 * (1 - fy) + b1 * fy;
    
    return brightness;
  }
  
  /// 전체 이미지의 평균 밝기 계산
  double getAverageBrightness() {
    if (!_isInitialized) {
      return 0.5;
    }
    
    double totalBrightness = 0.0;
    int sampleCount = 0;
    
    // 성능을 위해 일정 간격으로 샘플링
    int stepSize = max(1, (_width * _height / 10000).floor());
    
    for (int y = 0; y < _height; y += stepSize) {
      for (int x = 0; x < _width; x += stepSize) {
        totalBrightness += getBrightness(x.toDouble(), y.toDouble());
        sampleCount++;
      }
    }
    
    return sampleCount > 0 ? totalBrightness / sampleCount : 0.5;
  }
  
  /// 디버그용: 밝기 히스토그램 생성
  List<int> getBrightnessHistogram({int buckets = 10}) {
    if (!_isInitialized) {
      return List.filled(buckets, 0);
    }
    
    List<int> histogram = List.filled(buckets, 0);
    
    for (int y = 0; y < _height; y++) {
      for (int x = 0; x < _width; x++) {
        double brightness = getBrightness(x.toDouble(), y.toDouble());
        int bucket = (brightness * (buckets - 1)).round();
        histogram[bucket]++;
      }
    }
    
    return histogram;
  }
}