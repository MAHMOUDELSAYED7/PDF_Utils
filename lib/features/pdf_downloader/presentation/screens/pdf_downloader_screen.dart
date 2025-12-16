import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/toast_service.dart';
import '../cubit/pdf_cubit.dart';
import '../cubit/pdf_state.dart';
import '../widgets/download_progress_dialog.dart';
import '../widgets/pdf_actions_sheet.dart';

class PdfDownloaderScreen extends StatefulWidget {
  const PdfDownloaderScreen({super.key});

  @override
  State<PdfDownloaderScreen> createState() => _PdfDownloaderScreenState();
}

class _PdfDownloaderScreenState extends State<PdfDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with sample URL for testing
    _urlController.text = ApiConstants.samplePdfUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showDownloadDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    final cubit = context.read<PdfCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<PdfCubit, PdfState>(
            builder: (ctx, state) {
              return DownloadProgressDialog(
                progress: state.downloadProgress,
                message: state.progressMessage ?? 'Preparing...',
                isComplete: state.status == PdfStatus.downloaded,
                onCancel: () {
                  cubit.cancelDownload();
                  Navigator.of(dialogContext).pop();
                  _isDialogShowing = false;
                },
                onOpen: () {
                  Navigator.of(dialogContext).pop();
                  _isDialogShowing = false;
                  cubit.openPdf();
                },
                onShare: () {
                  Navigator.of(dialogContext).pop();
                  _isDialogShowing = false;
                  cubit.sharePdf();
                },
              );
            },
          ),
        );
      },
    ).then((_) => _isDialogShowing = false);
  }

  void _showActionsSheet(String filePath) {
    final cubit = context.read<PdfCubit>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return PdfActionsSheet(
          filePath: filePath,
          onShare: () {
            Navigator.of(sheetContext).pop();
            cubit.sharePdf();
          },
          onOpen: () {
            Navigator.of(sheetContext).pop();
            cubit.openPdf();
          },
          onClose: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.gradientBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'PDF Downloader',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          elevation: 0,
          actions: [
            BlocBuilder<PdfCubit, PdfState>(
              builder: (context, state) {
                if (state.isDownloaded && state.filePath != null) {
                  return IconButton(
                    onPressed: () => _showActionsSheet(state.filePath!),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Actions',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocListener<PdfCubit, PdfState>(
          listener: (context, state) {
            switch (state.status) {
              case PdfStatus.downloading:
                if (!_isDialogShowing) {
                  _showDownloadDialog();
                }
                break;
              case PdfStatus.downloaded:
                // Dialog will update automatically via BlocBuilder
                ToastService.showSuccess(context, 'PDF downloaded successfully!');
                break;
              case PdfStatus.error:
                if (_isDialogShowing) {
                  Navigator.of(context, rootNavigator: true).pop();
                  _isDialogShowing = false;
                }
                ToastService.showError(
                  context,
                  state.errorMessage ?? 'An error occurred',
                );
                break;
              case PdfStatus.cancelled:
                ToastService.showWarning(context, 'Download cancelled');
                break;
              case PdfStatus.permissionDenied:
                if (_isDialogShowing) {
                  Navigator.of(context, rootNavigator: true).pop();
                  _isDialogShowing = false;
                }
                ToastService.showError(context, 'Storage permission required');
                _showPermissionDialog();
                break;
              default:
                break;
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUrlSection(),
                const SizedBox(height: 24),
                _buildDownloadButton(),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PDF URL',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          style: const TextStyle(color: AppColors.black),
          decoration: InputDecoration(
            hintText: 'Enter PDF URL...',
            hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.7)),
            prefixIcon: const Icon(Icons.link, color: AppColors.primary),
            suffixIcon: IconButton(
              onPressed: () => _urlController.clear(),
              icon: const Icon(Icons.clear, color: AppColors.grey),
            ),
            border: OutlineInputBorder(
              borderRadius: AppColors.borderRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppColors.borderRadius,
              borderSide: const BorderSide(color: AppColors.white, width: 2),
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return BlocBuilder<PdfCubit, PdfState>(
      builder: (context, state) {
        final isDownloading = state.status == PdfStatus.downloading;
        return ElevatedButton.icon(
          onPressed: isDownloading
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  context.read<PdfCubit>().downloadPdf(_urlController.text);
                },
          icon: isDownloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.download),
          label: Text(isDownloading ? 'Downloading...' : 'Download PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.white.withValues(alpha: 0.7),
            disabledForegroundColor: AppColors.primary.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: AppColors.borderRadius,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return BlocBuilder<PdfCubit, PdfState>(
      builder: (context, state) {
        if (!state.isDownloaded) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: AppColors.borderRadius,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 56,
                    color: AppColors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No PDF downloaded yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter a URL and tap Download',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppColors.borderRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 56,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PDF Downloaded Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppColors.borderRadius,
                  ),
                  child: Text(
                    state.pdfEntity?.fileName ?? 'Unknown file',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (state.pdfEntity?.fileSize != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Size: ${_formatFileSize(state.pdfEntity!.fileSize!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<PdfCubit, PdfState>(
      builder: (context, state) {
        if (!state.isDownloaded) return const SizedBox.shrink();

        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.read<PdfCubit>().sharePdf(),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppColors.borderRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.read<PdfCubit>().openPdf(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppColors.borderRadius,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Storage permission is required to download PDFs. Would you like to open settings?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
