import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plugin_scanner.dart';

class PluginDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> plugin;

  const PluginDetailScreen({super.key, required this.plugin});

  @override
  ConsumerState<PluginDetailScreen> createState() => _PluginDetailScreenState();
}

class _PluginDetailScreenState extends ConsumerState<PluginDetailScreen> {
  final _scanner = PluginScanner();
  PluginScanResult? _scanResult;

    Color _riskColor = const Color(0xFF10B981);

    void _runScan() {
    final demoCode = widget.plugin['description'] as String;
    final result = _scanner.scan(demoCode);

    // Цвета по уровню риска
    Color riskColor;
    switch (result.riskLevel) {
      case 'critical':
        riskColor = Colors.red;
        break;
      case 'high':
        riskColor = Colors.orange;
        break;
      case 'medium':
        riskColor = Colors.yellow;
        break;
      default:
        riskColor = const Color(0xFF10B981);
    }

    setState(() {
      _scanResult = result;
      _riskColor = riskColor;
    });
  }

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: Text(widget.plugin['name'] as String),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Автор: ${widget.plugin['author']}', style: const TextStyle(color: Color(0xFF888899))),
          const SizedBox(height: 8),
          Text('Тип: ${widget.plugin['type']}', style: const TextStyle(color: Color(0xFF888899))),
          const SizedBox(height: 8),
          Text('Цена: ${widget.plugin['price']}', style: const TextStyle(color: Color(0xFF4ADE80))),
          const SizedBox(height: 24),
          if (_scanResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _scanResult!.safe ? const Color(0xFF4ADE80).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _scanResult!.safe ? const Color(0xFF4ADE80) : Colors.red),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_scanResult!.safe ? Icons.shield : Icons.warning,
                      color: _scanResult!.safe ? const Color(0xFF4ADE80) : Colors.red),
                  const SizedBox(width: 8),
                  Text(_scanResult!.message,
                      style: TextStyle(
                          color: _scanResult!.safe ? const Color(0xFF4ADE80) : Colors.red,
                          fontWeight: FontWeight.w600)),
                ]),
                if (_scanResult!.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._scanResult!.warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(w, style: const TextStyle(color: Colors.orange, fontSize: 13)),
                      )),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 24),
          if (_scanResult?.safe == true)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Плагин установлен!'), backgroundColor: Color(0xFF4ADE80)),
                  );
                },
                child: const Text('Установить плагин', style: TextStyle(color: Color(0xFF0A0A0F))),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.lock, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text('Антивирус встроен в ядро Veil и не может быть отключён',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}