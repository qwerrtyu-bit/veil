import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(File audioFile, Duration duration) onSend;

  const VoiceRecorder({super.key, required this.onSend});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isInitialized = false;
  
  late AnimationController _waveController;
  final List<double> _waveData = List.generate(30, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(_updateWave);
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        setState(() => _isInitialized = true);
        print('✅ Разрешение на запись получено');
      } else {
        print('❌ Нет разрешения на запись');
        // Запрашиваем разрешение через системный диалог
        await _requestPermission();
      }
    } catch (e) {
      print('⚠️ Ошибка инициализации: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      // Для Android запрашиваем через permission_handler
      // Пока просто пробуем ещё раз
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешите доступ к микрофону в настройках'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {}
  }

  void _updateWave() {
    if (!_isRecording) return;
    setState(() {
      for (int i = 0; i < _waveData.length; i++) {
        _waveData[i] = 0.3 + (DateTime.now().millisecond % 100) / 100 * 0.7;
      }
    });
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) {
      await _initRecorder();
      if (!_isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступа к микрофону'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      print('📁 Путь для записи: $path');

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _filePath = path;
        _duration = Duration.zero;
        _waveController.repeat();
      });
      
      print('🎤 Запись начата');
    } catch (e) {
      print('❌ Ошибка записи: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка записи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _waveController.stop();

      print('⏹️ Запись остановлена, путь: $path');

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          print('📦 Размер файла: ${bytes.length} байт');
          
          setState(() {
            _isRecording = false;
            _filePath = path;
            // Примерная длительность
            _duration = Duration(seconds: bytes.length ~/ 16000);
          });

          // Отправляем сразу после записи
          widget.onSend(file, _duration);
          Navigator.pop(context);
        } else {
          print('❌ Файл не найден: $path');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Файл не сохранён'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ Путь к файлу пустой');
      }
    } catch (e) {
      print('❌ Ошибка остановки записи: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_filePath == null) return;
    
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(_filePath!));
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  void _cancelRecording() {
    _recorder.stop();
    _waveController.stop();
    setState(() => _isRecording = false);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final sec = d.inSeconds;
    return '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRecording ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (_isRecording) ...[
            // Индикатор записи
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Волна
            Expanded(
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_waveData.length, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: 8 + _waveData[i] * 30,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red, size: 36),
              onPressed: _stopRecording,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: _cancelRecording,
            ),
          ] else if (_filePath != null) ...[
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: const Color(0xFF6C5CE7),
                size: 36,
              ),
              onPressed: _playRecording,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Голосовое сообщение',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 4,
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Container(
                          height: 4,
                          width: _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds / _duration.inMilliseconds * 100).clamp(0, 100)
                              : 0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF6C5CE7)),
              onPressed: () {
                if (_filePath != null) {
                  final file = File(_filePath!);
                  widget.onSend(file, _duration);
                  Navigator.pop(context);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ] else ...[
            Expanded(
              child: InkWell(
                onTap: _isInitialized ? _startRecording : _initRecorder,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isInitialized ? Icons.mic : Icons.mic_off,
                        color: _isInitialized ? const Color(0xFF6C5CE7) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isInitialized ? 'Нажмите для записи' : 'Запись недоступна',
                        style: TextStyle(
                          color: _isInitialized ? const Color(0xFF6C5CE7) : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}