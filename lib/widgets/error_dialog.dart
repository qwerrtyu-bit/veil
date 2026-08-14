import 'package:flutter/material.dart';

class VeilErrorDialog {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onRetry,
    bool showRetry = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          if (showRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry?.call();
              },
              child: const Text('Повторить'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(buttonText ?? 'Понятно'),
          ),
        ],
      ),
    );
  }
}