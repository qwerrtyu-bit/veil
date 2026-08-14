// lib/screens/doc_verify_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';

class DocVerifyScreen extends ConsumerStatefulWidget {
  const DocVerifyScreen({super.key});

  @override
  ConsumerState<DocVerifyScreen> createState() => _DocVerifyScreenState();
}

class _DocVerifyScreenState extends ConsumerState<DocVerifyScreen> {
  final _passwordController = TextEditingController();
  String _scannedData = '';
  String _result = '';
  bool _showScanner = false;
  bool _isAdmin = false;

  static const String _verifyPassword = 'X7k9#mP2\$vL5@nQ8&wR3^tY6!hJ1*cF4(dB0)gM7+sA2?eU9~oW5:iZ3%xK8^yN4!pQ2@jR6&mS9*tV3#wX5(hB7)lD1\$nF0~gH4+iJ8?aC2_eY6:kT9^pM3!sW7@vR5&xZ1*nQ4(tB8)hL2\$dF6~jN0:iG9^aE5!yU3@mW7#pR1&sT4*vX8)lZ2\$cB6~hN9:jG3^iF0+eD5!aY7@kM1#wQ4&tR8*nU2\$vX6~pB9:lZ3^cH7!iF0&eD4@aY8#kM1*wQ5\$tR9^nU3~vX7:pB2^lZ6!cH0&iF4@eD8#aY1*wM5\$kQ9^nT3~pU7:vR2^lX6!cZ0&iB4@eH8#aF1*wD5\$kM9^nQ3~tT7:pU2^vR6!lX0&cZ4@iB8#eH1*aF5\$wD9^kM3~nQ7:tT2^pU6!vR0&lX4@cZ8#iB1*eH5\$aF9^wD3~kM7:nQ2!tT6^pU0&vR4@lX8#cZ1*iB5\$eH9~aF3^wD7!kM2:nQ6\$tT0^pU4&vR8@lX1#cZ5*iB9~eH3\$aF7!wD2^kM6:nQ0\$tT4^pU8&vR1@lX5#cZ9~iB3\$eH7!aF2*wD6^kM0:nQ4\$tT8^pU1&vR5@lX9#cZ3~iB7\$eH2!aF6*wD0^kM4:nQ8\$tT1^pU5&vR9@lX3#cZ7~iB2\$eH6!aF0*wD4\$kM8^nQ1~tT5:pU9^vR2&lX7@cZ0#iB6!eH4\$aF8*wD1\$kM5^nQ9~tT3:pU7^vR1&lX5@cZ2#iB0!eH8\$aF4*wD9\$kM3^nQ6~tT1:pU4^vR7&lX0@cZ5#iB8!eH1\$aF9*wD2\$kM6^nQ0~tT8:pU3^vR5&lX1@cZ4#iB9!eH7\$aF0';
  static const String _qrCipher = 'veilveilVEILVEILVEILVEILVEIL882829842079825623896382975892357892659216525892175981265892659821658961258962158962189562198562198658926502165891265082618215896218965981265981256218956219856219856219856219856219861289659812568921шифрование_QR_кода_90902929292929';

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
  }

  void _onQRScanned(String data) {
    setState(() {
      _scannedData = data;
      _showScanner = false;
    });
  }

  void _verify() {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;

    if (_scannedData.isEmpty) {
      setState(() => _result = l10n.docNoScan);
      return;
    }

    if (password != _verifyPassword) {
      setState(() => _result = l10n.docWrongPassword);
      return;
    }

    if (_scannedData.startsWith('VEIL-DOC-') ||
        _scannedData.startsWith('VEIL-СД-') ||
        _scannedData == _qrCipher) {
      setState(() => _result = l10n.docOriginal);
    } else {
      setState(() => _result = l10n.docFake);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.docVerify),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('1. Отсканируйте QR-код документа', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_showScanner)
            SizedBox(
              height: 250,
              child: MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.first;
                  if (barcode.rawValue != null) {
                    _onQRScanned(barcode.rawValue!);
                  }
                },
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showScanner = true),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Сканировать QR'),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              ),
            ),

          if (_scannedData.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
              child: Text(_scannedData, style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 11)),
            ),
          ],

          const SizedBox(height: 24),
          const Text('2. Введите пароль верификации', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Пароль верификации'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verify,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Проверить подлинность'),
            ),
          ),

          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _result.contains('✅') ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _result.contains('✅') ? const Color(0xFF10B981) : Colors.red),
              ),
              child: Text(
                _result,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _result.contains('✅') ? const Color(0xFF10B981) : Colors.red,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}