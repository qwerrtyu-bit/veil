import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final box = Hive.box('settings');
    final rawReports = box.get('reports', defaultValue: <Map<String, dynamic>>[]);
    setState(() {
      _reports = List<Map<String, dynamic>>.from(rawReports).reversed.toList();
    });
  }

  Map<String, int> _getStats() {
    final stats = <String, int>{};
    for (final report in _reports) {
      final key = report['publicKey'] as String? ?? '';
      stats[key] = (stats[key] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жалобы'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Очистить все',
              onPressed: () => _clearReports(),
            ),
        ],
      ),
      body: _reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Жалоб нет',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey[400])),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (stats.isNotEmpty) ...[
                  Text('Ключи с жалобами',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...stats.entries.map((entry) {
                    final key = entry.key;
                    final displayKey = key.length > 12 ? '${key.substring(0, 12)}...' : key;
                    final count = entry.value;
                    final isBad = count >= 3;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBad ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(isBad ? Icons.block : Icons.warning_amber_rounded,
                                  color: isBad ? Colors.red : Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayKey, style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 13)),
                                  Text('$count жалоб', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: key));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ключ скопирован')),
                                );
                              },
                              child: const Text('Копировать'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                Text('Все жалобы',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._reports.map((report) {
                  final reason = report['reasonText'] ?? report['reason'] ?? 'Неизвестно';
                  final name = report['contactName'] ?? 'Неизвестный';
                  final time = report['timestamp'] ?? '';
                  final timeStr = time.toString().length > 16
                      ? time.toString().substring(0, 16).replaceAll('T', ' ')
                      : time.toString();
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        child: const Icon(Icons.report, color: Colors.red, size: 20),
                      ),
                      title: Text('$name — $reason'),
                      subtitle: Text(timeStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  void _clearReports() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить жалобы?'),
        content: const Text('Все жалобы будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              await Hive.box('settings').delete('reports');
              Navigator.pop(ctx);
              _loadReports();
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}