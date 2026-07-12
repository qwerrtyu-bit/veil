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

  @override
  void dispose() { _idController.dispose(); _nameController.dispose(); super.dispose(); }

  void _addContact() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (id.isEmpty || name.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Контакт "$name" добавлен!'), backgroundColor: Colors.green),
    );
    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить контакт'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats'))),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        TextField(controller: _idController, decoration: const InputDecoration(hintText: 'ID контакта')),
        const SizedBox(height: 16),
        TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Имя')),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _addContact, child: const Text('Добавить'))),
      ])),
    );
  }
}