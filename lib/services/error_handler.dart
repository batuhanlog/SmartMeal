import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static String getFriendlyErrorMessage(String error) {
    if (error.contains('network-request-failed')) {
      return 'İnternet bağlantınızı kontrol edin';
    } else if (error.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi';
    } else if (error.contains('user-disabled')) {
      return 'Bu hesap devre dışı bırakılmış';
    } else if (error.contains('user-not-found')) {
      return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
    } else if (error.contains('wrong-password')) {
      return 'Hatalı şifre';
    } else if (error.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanımda';
    } else if (error.contains('weak-password')) {
      return 'Şifre çok zayıf. En az 6 karakter olmalı';
    } else if (error.contains('too-many-requests')) {
      return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
    } else if (error.contains('operation-not-allowed')) {
      return 'Bu işlem şu anda izin verilmiyor';
    } else if (error.contains('account-exists-with-different-credential')) {
      return 'Bu e-posta adresi farklı bir giriş yöntemi ile kullanılıyor';
    } else if (error.contains('invalid-credential')) {
      return 'Geçersiz giriş bilgileri';
    } else if (error.contains('quota-exceeded')) {
      return 'Günlük limit aşıldı. Lütfen daha sonra tekrar deneyin';
    } else {
      return 'Bir hata oluştu. Lütfen tekrar deneyin';
    }
  }
}

class LoadingDialog {
  static void show(BuildContext context, {String message = 'Yükleniyor...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
