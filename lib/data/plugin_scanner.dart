// ========== lib/data/plugin_scanner.dart ==========
import 'dart:convert';

class PluginScanResult {
  final bool safe;
  final String message;
  final List<String> warnings;
  final String? riskLevel;

  PluginScanResult({
    required this.safe,
    required this.message,
    this.warnings = const [],
    this.riskLevel,
  });
}

class PluginScanner {
  static const List<String> _criticalPatterns = [
    'dart:io',
    'Process.run',
    'Process.start',
    'spawn',
    'Isolate.spawn',
    'eval(',
    'Function(',
  ];

  static const List<String> _highPatterns = [
    'File.delete',
    'Directory.delete',
    'HttpServer',
    'Socket.',
    'RawSocket',
    'InternetAddress',
  ];

  static const List<String> _mediumPatterns = [
    'http.',
    'HttpClient',
    'readAsBytes',
    'writeAsBytes',
    'openWrite',
    'createFile',
    'deleteSync',
  ];

  static const List<String> _privacyPatterns = [
    'readAsString',
    'readAsLines',
    'copy',
    'rename',
    'Platform.environment',
    'Platform.operatingSystem',
  ];

  static const Set<String> _knownMalware = {
    'abc123def456',
  };

  PluginScanResult scan(String pluginCode, {String? fileName}) {
    final warnings = <String>[];
    int riskScore = 0;

    final sizeBytes = utf8.encode(pluginCode).length;
    if (sizeBytes > 1024 * 1024) {
      return PluginScanResult(safe: false, message: 'Плагин слишком большой (>1 МБ)', riskLevel: 'critical');
    }
    if (sizeBytes > 512 * 1024) {
      warnings.add('Размер плагина больше 512 КБ');
      riskScore += 10;
    }

    final hash = _calculateHash(pluginCode);
    if (_knownMalware.contains(hash)) {
      return PluginScanResult(safe: false, message: 'Обнаружен известный вирус! Плагин заблокирован.',
          warnings: ['Хеш совпадает с базой известных угроз'], riskLevel: 'critical');
    }

    for (final pattern in _criticalPatterns) {
      if (pluginCode.contains(pattern)) {
        return PluginScanResult(safe: false, message: 'Обнаружен критически опасный код: $pattern',
            warnings: ['Плагин пытается выполнить системные операции'], riskLevel: 'critical');
      }
    }

    for (final pattern in _highPatterns) {
      if (pluginCode.contains(pattern)) {
        warnings.add('⚠️ Высокая опасность: $pattern');
        riskScore += 40;
      }
    }

    for (final pattern in _mediumPatterns) {
      if (pluginCode.contains(pattern)) {
        warnings.add('⚠️ Средняя опасность: $pattern');
        riskScore += 20;
      }
    }

    for (final pattern in _privacyPatterns) {
      if (pluginCode.contains(pattern)) {
        warnings.add('🔍 Доступ к данным: $pattern');
        riskScore += 10;
      }
    }

    if (_isObfuscated(pluginCode)) {
      warnings.add('⚠️ Код обфусцирован — требуется ручная проверка');
      riskScore += 50;
    }

    final urls = _extractUrls(pluginCode);
    if (urls.isNotEmpty) {
      warnings.add('🌐 Обнаружены внешние ссылки: ${urls.length} шт.');
      riskScore += urls.length * 15;
    }

    if (riskScore >= 80) {
      return PluginScanResult(safe: false, message: 'Плагин не прошёл проверку безопасности (${riskScore} баллов)',
          warnings: warnings, riskLevel: 'high');
    }

    if (riskScore >= 40) {
      return PluginScanResult(safe: true, message: 'Плагин требует внимания (${riskScore} баллов)',
          warnings: warnings, riskLevel: 'medium');
    }

    if (warnings.isEmpty) {
      return PluginScanResult(safe: true, message: 'Плагин безопасен', riskLevel: 'low');
    }

    return PluginScanResult(safe: true, message: 'Плагин проверен, есть замечания',
        warnings: warnings, riskLevel: 'low');
  }

  bool quickScan(String pluginCode) {
    for (final pattern in _criticalPatterns) {
      if (pluginCode.contains(pattern)) return false;
    }
    return true;
  }

  bool _isObfuscated(String code) {
    final lines = code.split('\n');
    int longLines = 0, shortLines = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length > 500) longLines++;
      if (trimmed.length < 5 && trimmed.isNotEmpty) shortLines++;
    }
    return longLines > 3 || (shortLines > lines.length * 0.3);
  }

  List<String> _extractUrls(String code) {
        final urlPattern = RegExp("https?://[^\\s\"']+");
    return urlPattern.allMatches(code).map((m) => m.group(0)!).toList();
  }

  String _calculateHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}