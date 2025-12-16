import 'package:flutter/material.dart';
import 'package:modern_toast/modern_toast.dart';

class ToastService {
  static void showSuccess(BuildContext context, String message) {
    showModernToast(
      context,
      message: message,
      type: ModernToastType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    showModernToast(
      context,
      message: message,
      type: ModernToastType.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showModernToast(
      context,
      message: message,
      type: ModernToastType.info,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showModernToast(
      context,
      message: message,
      type: ModernToastType.warning,
    );
  }
}
