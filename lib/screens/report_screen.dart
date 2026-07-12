import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String contactId;
  final String contactName;
  final String publicKey;

  const ReportScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.publicKey,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedReason = 'spam';
  bool _isSending = false;

  final Map<String, String> _reasons = {
    'spam': 'Спам',
    'harassment': 'Домогательство',
    'fraud': 'Мошенничество',
    'impersonation': 'Выдаёт себя за другого',
    'illegal': 'Незаконный контент',
    'other': 'Другое',
  };

  Future<void> _sendReport() async {
    setState(() => _isSending = true);

    final reportsBox = Hive.box('settings');
    final raw = reportsBox.get('reports');
    List<Map<String, dynamic>> reportsList = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          reportsList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    reportsList.add({
      'contactId': widget.contactId,
      'contactName': widget.contactName,
      'publicKey': widget.publicKey,
      'reason': _selectedReason,
      'reasonText': _reasons[_selectedReason],
      'timestamp': DateTime.now().toIso8601String(),
    });

    await reportsBox.put('reports', reportsList);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Жалоба отправлена. Спасибо за бдительность.'),
        backgroundColor: Colors.green,
      ),
    );

    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пожаловаться'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Жалоба на: ${widget.contactName}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Ваша личность в безопасности. Содержимое чата не будет раскрыто.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Причина жалобы', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ..._reasons.entries.map((entry) {
                final isSelected = _selectedReason == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedReason = entry.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C5CE7).withOpacity(0.1)
                            : Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1A1A2E)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFE0E0E0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(entry.value,
                                style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF6C5CE7) : null)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Color(0xFF6C5CE7), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Разработчик увидит только публичный ключ и причину жалобы. Сообщения останутся зашифрованными.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6C5CE7), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Отправить жалобу'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}