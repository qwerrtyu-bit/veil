import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileCard extends StatelessWidget {
  final String publicKey;
  final String displayName;
  final String displayBio;

  const ProfileCard({
    super.key,
    required this.publicKey,
    required this.displayName,
    required this.displayBio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0F),
            Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Логотип
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'VEIL',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF4F4F5),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Говори свободно.',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF888899),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // QR-код
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: publicKey,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Имя пользователя
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF4F4F5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayBio,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 16),
          // Разделитель
          Container(
            width: 60,
            height: 1,
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          // Публичный ключ
          Text(
            _formatKey(publicKey),
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: Color(0xFF888899),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Ссылка для добавления
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withOpacity(0.2),
              ),
            ),
            child: Text(
              'veil://add?key=$publicKey',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: Color(0xFF6C5CE7),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    if (key.length <= 20) return key;
    return '${key.substring(0, 10)}…${key.substring(key.length - 10)}';
  }
}