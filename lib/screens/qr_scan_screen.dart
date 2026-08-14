import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _showScanner = false;
  bool _isScanning = false;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onQRScanned(String data) {
    setState(() {
      _idController.text = data;
      _showScanner = false;
      _isScanning = false;
    });
  }

  void _addContact() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();

    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите ID и имя контакта'), backgroundColor: Colors.red),
      );
      return;
    }

    final contactsBox = Hive.box('contacts');
    contactsBox.put(id, {
      'id': id,
      'name': name,
      'initial': name.isNotEmpty ? name[0].toUpperCase() : '?',
      'status': 'В сети',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Контакт "$name" добавлен!'), backgroundColor: Colors.green),
    );

    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить контакт'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          if (_isMobile)
            IconButton(
              icon: Icon(_showScanner ? Icons.close : Icons.qr_code_scanner),
              onPressed: () {
                setState(() {
                  _showScanner = !_showScanner;
                  if (!_showScanner) _isScanning = false;
                });
              },
              tooltip: 'Сканировать QR',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showScanner && _isMobile) ...[
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      if (_isScanning) return;
                      final barcode = capture.barcodes.first;
                      if (barcode.rawValue != null) {
                        setState(() => _isScanning = true);
                        _onQRScanned(barcode.rawValue!);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Наведите камеру на QR-код',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (!_isMobile && !_showScanner)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QR-сканер доступен только на Android и iOS. Введите ключ вручную.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Text(
              'ID контакта (публичный ключ)',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                hintText: '0x7F3A9B2C...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Имя контакта',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Как вы знаете этого человека',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addContact,
                child: const Text('Добавить контакт'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}