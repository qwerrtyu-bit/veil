// lib/screens/access_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/crypto_service.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';

class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key});

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  final _masterController = TextEditingController();
  final _cryptoService = CryptoService();
  bool _isVerified = false;
  String? _errorText;
  bool _isAdmin = false;

  final Map<String, String> _keys = {
    'Доступ ко всему': '1092829028272628389V73828299OOO01019929',
    'Шифр QR-кода': '2891010983883829101918283838',
    'Изменение кода': '82920933839202938388291010838299102938388',
    'Передача владельца': 'VEILCEO9291010029393IOP929292023062026',
    'Подтверждение передачи': '19102091293838372719101903892929292',
  };

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final adminService = AdminService();
    final isAdmin = await adminService.isAdmin();
    if (!isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Доступ запрещён'), backgroundColor: Colors.red),
        );
        context.go('/chats');
      }
      return;
    }
    setState(() => _isAdmin = true);
    _checkVerified();
  }

  void _checkVerified() {
    final box = Hive.box('settings');
    _isVerified = box.get('access_verified', defaultValue: false);
    setState(() {});
  }

  void _verifyMaster() {
    const masterHash = 'veilveilVEILVEILVEILVEILVEIL882829842079825623896382975892357892659216525892175981265892659821658961258962158962189562198562198658926502165891265082618215896218965981265981256218956219856219856219856219856219861289659812568921шифрование_QR_кода_90902929292929';
    
    if (_masterController.text == masterHash) {
      Hive.box('settings').put('access_verified', true);
      setState(() {
        _isVerified = true;
        _errorText = null;
      });
    } else {
      setState(() => _errorText = 'Неверный мастер-ключ');
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isVerified) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/chats'),
),title: const Text('Доступ')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Color(0xFF10B981)),
              const SizedBox(height: 24),
              const Text('Введите мастер-ключ верификации', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _masterController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Мастер-ключ'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _verifyMaster, child: const Text('Подтвердить')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Система доступа'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('QR-ключи доступа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Каждый ключ зашифрован в отдельный QR-код', style: TextStyle(color: Color(0xFF888899))),
          const SizedBox(height: 24),
          ..._keys.entries.map((entry) => Card(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${entry.value.length} символов', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () => _showQr(context, entry.key, entry.value),
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _showQr(BuildContext context, String title, String data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title),
        content: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: QrImageView(data: data, size: 200),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}