import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

/// 이미지 변환 유틸리티
/// 컬러 이미지를 흑백으로 변환하고 밝기 정보를 최적화
class ImageConverter {
  
  /// 컬러 이미지를 흑백으로 변환
  /// ITU-R BT.709 표준 사용 (사람 눈의 민감도를 반영한 가중치)
  static Future<ui.Image> convertToGrayscale(ui.Image sourceImage) async {
    // 이미지를 ByteData로 변환
    final ByteData? data = await sourceImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    
    if (data == null) {
      throw Exception('Failed to convert image to ByteData');
    }
    
    final int width = sourceImage.width;
    final int height = sourceImage.height;
    
    // 새로운 픽셀 데이터를 위한 버퍼 생성
    final Uint8List pixels = Uint8List(width * height * 4);
    
    // 각 픽셀을 흑백으로 변환
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = (y * width + x) * 4;
        
        // RGBA 값 추출
        final int r = data.getUint8(pixelIndex);
        final int g = data.getUint8(pixelIndex + 1);
        final int b = data.getUint8(pixelIndex + 2);
        final int a = data.getUint8(pixelIndex + 3);
        
        // ITU-R BT.709 표준 가중치로 밝기 계산
        // 인간의 눈은 녹색에 가장 민감하고, 파란색에 가장 둔감
        final int gray = (0.2126 * r + 0.7152 * g + 0.0722 * b).round();
        
        // 흑백 픽셀 설정 (R=G=B=gray)
        pixels[pixelIndex] = gray;     // R
        pixels[pixelIndex + 1] = gray; // G
        pixels[pixelIndex + 2] = gray; // B
        pixels[pixelIndex + 3] = a;    // A (알파값 유지)
      }
    }
    
    // 새로운 이미지 생성 - decodeImageFromPixels 사용
    final completer = Completer<ui.Image>();
    
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    
    return await completer.future;
  }
  
  /// 이미지 대비 향상 (선택적)
  /// 흑백 이미지의 대비를 높여 더 극적인 효과 생성
  static Future<ui.Image> enhanceContrast(
    ui.Image sourceImage, {
    double contrastFactor = 1.5, // 1.0 = 원본, >1.0 = 대비 증가
  }) async {
    final ByteData? data = await sourceImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    
    if (data == null) {
      throw Exception('Failed to convert image to ByteData');
    }
    
    final int width = sourceImage.width;
    final int height = sourceImage.height;
    final Uint8List pixels = Uint8List(width * height * 4);
    
    // 대비 조정 공식: new_value = (old_value - 128) * contrast + 128
    for (int i = 0; i < pixels.length; i += 4) {
      for (int c = 0; c < 3; c++) { // RGB 채널만 조정
        int value = data.getUint8(i + c);
        value = ((value - 128) * contrastFactor + 128).round();
        value = value.clamp(0, 255);
        pixels[i + c] = value;
      }
      pixels[i + 3] = data.getUint8(i + 3); // 알파값 유지
    }
    
    final completer = Completer<ui.Image>();
    
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    
    return await completer.future;
  }
  
  /// 히스토그램 균등화 (선택적)
  /// 밝기 분포를 균등하게 만들어 더 나은 대비 생성
  static Future<ui.Image> equalizeHistogram(ui.Image sourceImage) async {
    final ByteData? data = await sourceImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    
    if (data == null) {
      throw Exception('Failed to convert image to ByteData');
    }
    
    final int width = sourceImage.width;
    final int height = sourceImage.height;
    final int totalPixels = width * height;
    
    // 히스토그램 생성
    final List<int> histogram = List.filled(256, 0);
    for (int i = 0; i < totalPixels * 4; i += 4) {
      // 흑백 이미지이므로 R 채널만 사용
      histogram[data.getUint8(i)]++;
    }
    
    // 누적 분포 함수 (CDF) 계산
    final List<int> cdf = List.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }
    
    // 정규화된 CDF 계산
    final int cdfMin = cdf.firstWhere((value) => value > 0);
    final List<int> equalizedValues = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      equalizedValues[i] = ((cdf[i] - cdfMin) * 255 / (totalPixels - cdfMin)).round();
    }
    
    // 균등화된 픽셀 데이터 생성
    final Uint8List pixels = Uint8List(totalPixels * 4);
    for (int i = 0; i < totalPixels * 4; i += 4) {
      final int oldValue = data.getUint8(i);
      final int newValue = equalizedValues[oldValue];
      pixels[i] = newValue;     // R
      pixels[i + 1] = newValue; // G
      pixels[i + 2] = newValue; // B
      pixels[i + 3] = data.getUint8(i + 3); // A
    }
    
    final completer = Completer<ui.Image>();
    
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    
    return await completer.future;
  }
}