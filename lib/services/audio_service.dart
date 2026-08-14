import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioService {
  Future<bool> hasPermission() async {
    return false;
  }

  Future<void> start() async {}

  Future<String?> stop() async {
    return null;
  }

  bool get isRecording => false;
}