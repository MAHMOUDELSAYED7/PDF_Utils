import 'package:equatable/equatable.dart';

import '../../domain/entities/pdf_entity.dart';

enum PdfStatus {
  initial,
  loading,
  downloading,
  downloaded,
  sharing,
  opening,
  success,
  error,
  cancelled,
  permissionDenied,
}

class PdfState extends Equatable {
  final PdfStatus status;
  final PdfEntity? pdfEntity;
  final String? errorMessage;
  final double downloadProgress;
  final String? progressMessage;
  final String? pdfUrl;

  const PdfState({
    this.status = PdfStatus.initial,
    this.pdfEntity,
    this.errorMessage,
    this.downloadProgress = 0.0,
    this.progressMessage,
    this.pdfUrl,
  });

  bool get isDownloaded => pdfEntity?.isDownloaded ?? false;
  String? get filePath => pdfEntity?.filePath;

  PdfState copyWith({
    PdfStatus? status,
    PdfEntity? pdfEntity,
    String? errorMessage,
    double? downloadProgress,
    String? progressMessage,
    String? pdfUrl,
  }) {
    return PdfState(
      status: status ?? this.status,
      pdfEntity: pdfEntity ?? this.pdfEntity,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      progressMessage: progressMessage,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pdfEntity,
        errorMessage,
        downloadProgress,
        progressMessage,
        pdfUrl,
      ];
}
