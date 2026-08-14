import 'package:flutter/material.dart';

/// Все возможные ошибки в приложении
enum VeilErrorType {
  // Аутентификация
  invalidPassword,
  invalidSeed,
  invalidTotp,
  accountBlocked,
  
  // Сеть
  noInternet,
  serverUnavailable,
  timeout,
  connectionFailed,
  
  // Чаты
  chatNotFound,
  messageNotFound,
  sendFailed,
  receiveFailed,
  
  // Файлы
  fileTooLarge,
  fileNotFound,
  uploadFailed,
  downloadFailed,
  
  // Криптография
  encryptionFailed,
  decryptionFailed,
  keyNotFound,
  
  // Кошелёк
  insufficientBalance,
  transferFailed,
  invalidAmount,
  
  // Общие
  unknown,
  permissionDenied,
  storageFull,
}

/// Человекочитаемые сообщения
extension VeilErrorMessages on VeilErrorType {
  String get message {
    switch (this) {
      // Аутентификация
      case VeilErrorType.invalidPassword:
        return '❌ Неверный пароль. Попробуйте ещё раз.';
      case VeilErrorType.invalidSeed:
        return '❌ Неверная seed-фраза. Проверьте все 24 слова.';
      case VeilErrorType.invalidTotp:
        return '❌ Неверный код 2FA. Попробуйте снова.';
      case VeilErrorType.accountBlocked:
        return '🚫 Аккаунт временно заблокирован. Попробуйте позже.';
      
      // Сеть
      case VeilErrorType.noInternet:
        return '🌐 Нет интернета. Проверьте подключение.';
      case VeilErrorType.serverUnavailable:
        return '⚠️ Сервер недоступен. Попробуйте позже.';
      case VeilErrorType.timeout:
        return '⏰ Время ожидания истекло. Проверьте соединение.';
      case VeilErrorType.connectionFailed:
        return '🔌 Не удалось подключиться к серверу.';
      
      // Чаты
      case VeilErrorType.chatNotFound:
        return '💬 Чат не найден.';
      case VeilErrorType.messageNotFound:
        return '💬 Сообщение не найдено.';
      case VeilErrorType.sendFailed:
        return '📤 Не удалось отправить сообщение. Попробуйте снова.';
      case VeilErrorType.receiveFailed:
        return '📥 Не удалось получить сообщение.';
      
      // Файлы
      case VeilErrorType.fileTooLarge:
        return '📁 Файл слишком большой (макс. 50 МБ).';
      case VeilErrorType.fileNotFound:
        return '📁 Файл не найден.';
      case VeilErrorType.uploadFailed:
        return '📤 Не удалось загрузить файл.';
      case VeilErrorType.downloadFailed:
        return '📥 Не удалось скачать файл.';
      
      // Криптография
      case VeilErrorType.encryptionFailed:
        return '🔐 Ошибка шифрования. Попробуйте снова.';
      case VeilErrorType.decryptionFailed:
        return '🔐 Ошибка расшифровки. Возможно, ключи не совпадают.';
      case VeilErrorType.keyNotFound:
        return '🔑 Ключ не найден. Возможно, личность не создана.';
      
      // Кошелёк
      case VeilErrorType.insufficientBalance:
        return '💰 Недостаточно средств на балансе.';
      case VeilErrorType.transferFailed:
        return '💸 Ошибка перевода. Попробуйте позже.';
      case VeilErrorType.invalidAmount:
        return '💸 Введите корректную сумму.';
      
      // Общие
      case VeilErrorType.unknown:
        return '❌ Что-то пошло не так. Попробуйте снова.';
      case VeilErrorType.permissionDenied:
        return '🚫 Нет доступа. Разрешите в настройках.';
      case VeilErrorType.storageFull:
        return '📱 Недостаточно места на устройстве.';
    }
  }
}

/// Результат операции с ошибкой
class VeilResult<T> {
  final T? data;
  final VeilErrorType? error;
  final bool isSuccess;

  VeilResult.success(this.data)
      : error = null,
        isSuccess = true;

  VeilResult.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Показать пользователю
  void showSnackBar(BuildContext context) {
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error!.message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}