class VeilConstants {
  static const String appName = 'Veil';
  static const String tagline = 'Говори свободно.';
  static const String packageName = 'com.veil.messenger';
  static const String version = '2.5.0';
  static const int seedWordCount = 24;
  static const int passwordMinLength = 8;
  static const int totpDigits = 6;
  static const int totpPeriod = 30;

  // === СЕРВЕР ===
  static const String serverUrl = 'http://192.168.0.106:8080';
  static const String wsUrl = 'ws://192.168.0.106:8080/ws';
  
  // === НАСТРОЙКИ ДИЗАЙНА ===
  static const double cornerRadius = 20;
  static const double glassBlur = 20;
  static const double animationDuration = 300;
}