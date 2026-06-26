import 'dart:math';
import 'package:flutter/material.dart';

class EncryptAnimation extends StatefulWidget {
  final String text;
  final bool isEncrypting;
  final Color textColor;
  final double fontSize;
  final VoidCallback? onComplete;

  const EncryptAnimation({
    super.key,
    required this.text,
    required this.isEncrypting,
    required this.textColor,
    this.fontSize = 16,
    this.onComplete,
  });

  @override
  State<EncryptAnimation> createState() => _EncryptAnimationState();
}

class _EncryptAnimationState extends State<EncryptAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  final _random = Random();
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=!@#\$%^&*';
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addListener(() {
      setState(() {
        _displayText = _scramble(widget.text, _progress.value, widget.isEncrypting);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  String _scramble(String text, double progress, bool encrypting) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final charProgress = (progress * text.length - i).clamp(0.0, 1.0);
      if (encrypting) {
        // Шифрование: плавно заменяем на случайные символы
        if (charProgress > 0) {
          buffer.write(_chars[_random.nextInt(_chars.length)]);
        } else {
          buffer.write(text[i]);
        }
      } else {
        // Расшифровка: плавно возвращаем исходный текст
        if (charProgress > 0) {
          buffer.write(text[i]);
        } else {
          buffer.write(_chars[_random.nextInt(_chars.length)]);
        }
      }
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          _displayText,
          style: TextStyle(
            color: widget.textColor,
            fontSize: widget.fontSize,
            fontFamily: 'SpaceMono',
            letterSpacing: 1.2,
          ),
        );
      },
    );
  }
}