import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

enum FeedbackType { error, warning, success, info }

class AppFeedback {
  AppFeedback._();

  static void error(BuildContext context, String message) =>
      _show(context, message, FeedbackType.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, FeedbackType.warning);

  static void success(BuildContext context, String message) =>
      _show(context, message, FeedbackType.success);

  static void info(BuildContext context, String message) =>
      _show(context, message, FeedbackType.info);

  static void _show(BuildContext context, String message, FeedbackType type) {
    final color = switch (type) {
      FeedbackType.error || FeedbackType.warning => AppColors.accentOrange,
      FeedbackType.success => AppColors.statutTermineTexte,
      FeedbackType.info => AppColors.accentBleu,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(color: color),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
