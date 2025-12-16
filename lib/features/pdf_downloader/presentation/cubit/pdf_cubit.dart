import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/file_service.dart';
import '../../domain/usecases/check_permission_usecase.dart';
import '../../domain/usecases/download_pdf_usecase.dart';
import '../../domain/usecases/get_download_path_usecase.dart';
import '../../domain/usecases/open_pdf_usecase.dart';
import '../../domain/usecases/share_pdf_usecase.dart';
import 'pdf_state.dart';

class PdfCubit extends Cubit<PdfState> {
  final DownloadPdfUseCase downloadPdfUseCase;
  final SharePdfUseCase sharePdfUseCase;
  final OpenPdfUseCase openPdfUseCase;
  final CheckPermissionUseCase checkPermissionUseCase;
  final GetDownloadPathUseCase getDownloadPathUseCase;
  final FileService fileService;

  CancelToken? _cancelToken;

  PdfCubit({
    required this.downloadPdfUseCase,
    required this.sharePdfUseCase,
    required this.openPdfUseCase,
    required this.checkPermissionUseCase,
    required this.getDownloadPathUseCase,
    required this.fileService,
  }) : super(const PdfState());

  void setUrl(String url) {
    emit(state.copyWith(pdfUrl: url, status: PdfStatus.initial));
  }

  Future<void> downloadPdf(String url) async {
    if (url.isEmpty) {
      emit(state.copyWith(
        status: PdfStatus.error,
        errorMessage: 'Please enter a valid URL',
      ));
      return;
    }

    // Check permissions first
    final permissionResult = await checkPermissionUseCase();
    final hasPermission = permissionResult.fold(
      (failure) => false,
      (granted) => granted,
    );

    if (!hasPermission) {
      emit(state.copyWith(
        status: PdfStatus.permissionDenied,
        errorMessage: 'Storage permission denied. Please enable in settings.',
      ));
      return;
    }

    emit(state.copyWith(
      status: PdfStatus.downloading,
      downloadProgress: 0.0,
      progressMessage: 'Preparing download...',
      pdfUrl: url,
    ));

    // Generate file path
    final fileName = fileService.generateFileName(prefix: 'document');
    final pathResult = await getDownloadPathUseCase(fileName);

    final savePath = pathResult.fold(
      (failure) => null,
      (path) => path,
    );

    if (savePath == null) {
      emit(state.copyWith(
        status: PdfStatus.error,
        errorMessage: 'Failed to get download path',
      ));
      return;
    }

    _cancelToken = CancelToken();

    log('Downloading PDF from: $url to: $savePath');

    final result = await downloadPdfUseCase(
      url: url,
      savePath: savePath,
      cancelToken: _cancelToken,
      onProgress: (received, total) {
        if (total != -1 && !isClosed) {
          final progress = received / total;
          emit(state.copyWith(
            status: PdfStatus.downloading,
            downloadProgress: progress,
            progressMessage: 'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
          ));
        }
      },
    );

    result.fold(
      (failure) {
        if (failure.message.contains('cancelled')) {
          emit(state.copyWith(
            status: PdfStatus.cancelled,
            errorMessage: 'Download cancelled',
          ));
        } else {
          emit(state.copyWith(
            status: PdfStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
      (pdfEntity) {
        emit(state.copyWith(
          status: PdfStatus.downloaded,
          pdfEntity: pdfEntity,
          downloadProgress: 1.0,
          progressMessage: 'Download complete!',
        ));
      },
    );

    _cancelToken = null;
  }

  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
    emit(state.copyWith(
      status: PdfStatus.cancelled,
      errorMessage: 'Download cancelled',
    ));
  }

  Future<void> sharePdf() async {
    final filePath = state.filePath;
    if (filePath == null) {
      emit(state.copyWith(
        status: PdfStatus.error,
        errorMessage: 'No file to share. Download a PDF first.',
      ));
      return;
    }

    emit(state.copyWith(status: PdfStatus.sharing));

    final result = await sharePdfUseCase(filePath);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PdfStatus.error,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(status: PdfStatus.success));
      },
    );
  }

  Future<void> openPdf() async {
    final filePath = state.filePath;
    if (filePath == null) {
      emit(state.copyWith(
        status: PdfStatus.error,
        errorMessage: 'No file to open. Download a PDF first.',
      ));
      return;
    }

    emit(state.copyWith(status: PdfStatus.opening));

    final result = await openPdfUseCase(filePath);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PdfStatus.error,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(status: PdfStatus.success));
      },
    );
  }

  void reset() {
    emit(const PdfState());
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}
