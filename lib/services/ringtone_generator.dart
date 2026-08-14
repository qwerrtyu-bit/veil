import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class RingtoneGenerator {
  static const int _sampleRate = 44100;

  static Uint8List _generateTone(
    List<double> frequencies,
    double durationMs,
    double volume,
  ) {
    final int numSamples = (_sampleRate * durationMs / 1000).round();
    final Uint8List buffer = Uint8List(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      double value = 0.0;
      final double t = i / _sampleRate;

      for (final freq in frequencies) {
        value += volume * 0.8 * sin(2 * pi * freq * t);
      }

      final double envelope = _envelope(i, numSamples);
      value *= envelope;

      final int intValue = (value * 32767).toInt();
      final int clamped = intValue.clamp(-32767, 32767);

      buffer[i * 2] = clamped & 0xFF;
      buffer[i * 2 + 1] = (clamped >> 8) & 0xFF;
    }

    return buffer;
  }

  static double _envelope(int i, int total) {
    final double progress = i / total;
    if (progress < 0.1) return progress / 0.1;
    if (progress < 0.3) return 1.0 - (progress - 0.1) / 0.2 * 0.2;
    if (progress > 0.8) return 1.0 - (progress - 0.8) / 0.2;
    return 1.0;
  }

  /// ВХОДЯЩИЙ ЗВОНОК (обёртка для UI потока)
  static void playRingtone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playRingtoneInternal();
    });
  }

  static Future<void> _playRingtoneInternal() async {
    final player = AudioPlayer();
    
    final List<int> notes = [
      523, 587, 659, 523,
      587, 659, 784, 587,
      659, 784, 880, 659,
      784, 880, 1047, 784,
    ];

    final List<Uint8List> chunks = [];
    for (int i = 0; i < notes.length; i++) {
      final freq = notes[i].toDouble();
      final chunk = _generateTone([freq], 120, 0.25);
      chunks.add(chunk);
      
      if (i < notes.length - 1) {
        final silenceLength = (_sampleRate * 20 / 1000).round() * 2;
        chunks.add(Uint8List(silenceLength));
      }
    }

    final originalChunks = List<Uint8List>.from(chunks);
    chunks.addAll(originalChunks);

    final totalLength = chunks.fold(0, (sum, c) => sum + c.length);
    final fullBuffer = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in chunks) {
      fullBuffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    final tempFile = await _saveToTempFile(fullBuffer);
    await player.play(DeviceFileSource(tempFile.path));
  }

  /// ИСХОДЯЩИЙ ЗВОНОК
  static void playDialtone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playDialtoneInternal();
    });
  }

  static Future<void> _playDialtoneInternal() async {
    final player = AudioPlayer();
    final buffer = _generateTone([440, 350], 400, 0.2);
    final tempFile = await _saveToTempFile(buffer);
    await player.play(DeviceFileSource(tempFile.path));
  }

  /// УВЕДОМЛЕНИЕ
  static void playNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playNotificationInternal();
    });
  }

  static Future<void> _playNotificationInternal() async {
    final player = AudioPlayer();
    final buffer = _generateTone([880, 660], 80, 0.15);
    final tempFile = await _saveToTempFile(buffer);
    await player.play(DeviceFileSource(tempFile.path));
  }

  static Future<File> _saveToTempFile(Uint8List audioData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/ringtone_${DateTime.now().millisecondsSinceEpoch}.wav');
    
    final header = _createWavHeader(audioData.length, _sampleRate);
    final fullData = Uint8List.fromList(header + audioData);
    
    await file.writeAsBytes(fullData);
    return file;
  }

  static List<int> _createWavHeader(int dataLength, int sampleRate) {
    final header = <int>[];
    header.addAll([0x52, 0x49, 0x46, 0x46]);
    _addInt32(header, 36 + dataLength);
    header.addAll([0x57, 0x41, 0x56, 0x45]);
    header.addAll([0x66, 0x6D, 0x74, 0x20]);
    _addInt32(header, 16);
    _addInt16(header, 1);
    _addInt16(header, 2);
    _addInt32(header, sampleRate);
    _addInt32(header, sampleRate * 2 * 2);
    _addInt16(header, 2 * 2);
    _addInt16(header, 16);
    header.addAll([0x64, 0x61, 0x74, 0x61]);
    _addInt32(header, dataLength);
    return header;
  }

  static void _addInt32(List<int> list, int value) {
    list.add(value & 0xFF);
    list.add((value >> 8) & 0xFF);
    list.add((value >> 16) & 0xFF);
    list.add((value >> 24) & 0xFF);
  }

  static void _addInt16(List<int> list, int value) {
    list.add(value & 0xFF);
    list.add((value >> 8) & 0xFF);
  }
}