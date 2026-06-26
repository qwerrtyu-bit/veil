import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    setState(() {
      _isScanning = true;
    });

    // Имитация сканирования QR
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _idController.text = '0x7F3A9B2C1D4E5F6A7B8C9D0E1F2A3B4C5D6E7F8A';
      });
    });
  }

  void _addContact() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите или отсканируйте ID контакта'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя контакта'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Имитация добавления контакта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Контакт "$name" добавлен!'),
        backgroundColor: Colors.green,
      ),
    );

    // Возврат в список чатов
    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить контакт'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Область сканирования
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isScanning
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7),
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Сканирование...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // Рамка сканера
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF6C5CE7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Кнопка сканирования
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _simulateScan,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Сканировать QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),

            // Разделитель "или"
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ИЛИ ВВЕДИТЕ ВРУЧНУЮ',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Поле ID
            Text(
              'ID контакта (публичный ключ)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '0x7F3A9B2C...',
              ),
            ),
            const SizedBox(height: 16),

            // Поле имени
            Text(
              'Имя контакта',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Как вы знаете этого человека',
              ),
            ),
            const SizedBox(height: 32),

            // Кнопка добавить
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