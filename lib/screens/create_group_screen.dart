import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  String _groupKey = '';

  @override
  void initState() {
    super.initState();
    _generateKey();
  }

  void _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    setState(() {
      _groupKey = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название группы'), backgroundColor: Colors.red),
      );
      return;
    }

    final groupsBox = Hive.box('messages');
    final groups = groupsBox.get('groups_list', defaultValue: <Map<String, dynamic>>[]);
    final groupsList = List<Map<String, dynamic>>.from(groups);

    final groupId = DateTime.now().millisecondsSinceEpoch.toString();

    groupsList.add({
      'id': groupId,
      'name': name,
      'key': _groupKey,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await groupsBox.put('groups_list', groupsList);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Группа создана!'), backgroundColor: Colors.green),
    );

    context.go('/group/$groupId');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать группу'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Название группы',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Например: Семья, Работа, Друзья'),
                maxLength: 30,
              ),
              const SizedBox(height: 24),
              Text(
                'Ключ группы',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _groupKey,
                        style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generateKey,
                      tooltip: 'Сгенерировать новый',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createGroup,
                  child: const Text('Создать группу'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}