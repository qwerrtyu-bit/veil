// ========== lib/screens/plugin_detail_screen.dart ==========
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

    switch (result.riskLevel) {
      case 'critical': _riskColor = Colors.red; break;
      case 'high': _riskColor = Colors.orange; break;
      case 'medium': _riskColor = Colors.yellow; break;
      default: _riskColor = const Color(0xFF10B981);
    }

    setState(() => _scanResult = result);
  }

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(widget.plugin['name'] as String),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Автор: ${widget.plugin['author']}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          Text('Тип: ${widget.plugin['type']}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          Text('Цена: ${widget.plugin['price']}', style: const TextStyle(color: Color(0xFF10B981))),
          const SizedBox(height: 24),
          if (_scanResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _riskColor),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_scanResult!.safe ? Icons.shield : Icons.warning, color: _riskColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_scanResult!.message, style: TextStyle(color: _riskColor, fontWeight: FontWeight.w600))),
                ]),
                if (_scanResult!.riskLevel != null) ...[
                  const SizedBox(height: 4),
                  Text('Уровень угрозы: ${_scanResult!.riskLevel!.toUpperCase()}',
                      style: TextStyle(color: _riskColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                if (_scanResult!.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._scanResult!.warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(w, style: TextStyle(color: _riskColor.withOpacity(0.8), fontSize: 13)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Плагин установлен!'), backgroundColor: Color(0xFF10B981)),
                  );
                },
                child: const Text('Установить плагин', style: TextStyle(color: Color(0xFF09090B))),
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
              Expanded(child: Text('Антивирус встроен в ядро Veil и не может быть отключён',
                  style: TextStyle(color: Colors.orange, fontSize: 12))),
            ]),
          ),
        ]),
      ),
    );
  }
}