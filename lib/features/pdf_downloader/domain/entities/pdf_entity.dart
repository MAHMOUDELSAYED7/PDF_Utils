import 'package:equatable/equatable.dart';

class PdfEntity extends Equatable {
  final String url;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final DateTime? downloadedAt;
  final bool isDownloaded;

  const PdfEntity({
    required this.url,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.downloadedAt,
    this.isDownloaded = false,
  });

  PdfEntity copyWith({
    String? url,
    String? filePath,
    String? fileName,
    int? fileSize,
    DateTime? downloadedAt,
    bool? isDownloaded,
  }) {
    return PdfEntity(
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [
        url,
        filePath,
        fileName,
        fileSize,
        downloadedAt,
        isDownloaded,
      ];
}
