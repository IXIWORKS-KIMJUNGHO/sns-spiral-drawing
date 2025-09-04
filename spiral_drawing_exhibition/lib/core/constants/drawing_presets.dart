import '../models/drawing_config.dart';

/// \ K  X
class DrawingPresets {
  static const Map<String, String> presetDescriptions = {
    'fast': '`x  (20)',
    'standard': '  (30)',
    'detailed': 'L|  (45)',
    'custom': ' X',
  };
  
  static const Map<String, DrawingConfig> presets = {
    'fast': DrawingConfig(
      speedMultiplier: 2.0,
      maxDuration: 20,
      autoStop: true,
      minStrokeWidth: 0.8,
      maxStrokeWidth: 3.0,
      samplingDensity: 80,
      initialRadius: 1.5,
      radiusIncrement: 0.15,
      degreeIncrement: 0.15,
      presetName: 'fast',
    ),
    'standard': DrawingConfig(
      speedMultiplier: 1.0,
      maxDuration: 30,
      autoStop: true,
      minStrokeWidth: 0.5,
      maxStrokeWidth: 4.0,
      samplingDensity: 100,
      initialRadius: 1.0,
      radiusIncrement: 0.1,
      degreeIncrement: 0.1,
      presetName: 'standard',
    ),
    'detailed': DrawingConfig(
      speedMultiplier: 0.7,
      maxDuration: 45,
      autoStop: true,
      minStrokeWidth: 0.3,
      maxStrokeWidth: 5.0,
      samplingDensity: 150,
      initialRadius: 0.8,
      radiusIncrement: 0.08,
      degreeIncrement: 0.08,
      presetName: 'detailed',
    ),
  };
  
  /// K DtX ( )
  static const Map<String, String> presetIcons = {
    'fast': '',
    'standard': 'P',
    'detailed': '<',
    'custom': '',
  };
  
  /// |tT  
  static const double minSpeedMultiplier = 0.5;
  static const double maxSpeedMultiplier = 3.0;
  
  static const int minDuration = 10;
  static const int maxDuration = 60;
  
  static const double minStrokeWidth = 0.1;
  static const double maxStrokeWidth = 10.0;
  
  static const int minSamplingDensity = 50;
  static const int maxSamplingDensity = 200;
}