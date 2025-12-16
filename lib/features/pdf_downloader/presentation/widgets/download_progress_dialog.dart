import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class DownloadProgressDialog extends StatelessWidget {
  final double progress;
  final String message;
  final bool isComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;

  const DownloadProgressDialog({
    super.key,
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.onCancel,
    this.onOpen,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadius,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppColors.borderRadius,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isComplete ? null : AppColors.primaryGradient,
                color: isComplete ? AppColors.success : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.download,
                size: 40,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isComplete ? 'Download Complete' : 'Downloading PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isComplete ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (!isComplete) ...[
              ClipRRect(
                borderRadius: AppColors.borderRadius,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.greyLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isComplete ? AppColors.success : AppColors.greyDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isComplete) ...[
              Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      onPressed: onShare,
                      icon: Icons.share,
                      label: 'Share',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GradientButton(
                      onPressed: onOpen,
                      icon: Icons.open_in_new,
                      label: 'Open',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.grey,
                        side: const BorderSide(color: AppColors.greyLight),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppColors.borderRadius,
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 20),
                          SizedBox(height: 4),
                          Text('Close', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppColors.borderRadius,
                    ),
                  ),
                  child: const Text('Cancel Download'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppColors.borderRadius,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppColors.borderRadius,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
