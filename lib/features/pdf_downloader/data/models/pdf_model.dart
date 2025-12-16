import '../../domain/entities/pdf_entity.dart';

class PdfModel extends PdfEntity {
  const PdfModel({
    required super.url,
    super.filePath,
    super.fileName,
    super.fileSize,
    super.downloadedAt,
    super.isDownloaded,
  });

  factory PdfModel.fromEntity(PdfEntity entity) {
    return PdfModel(
      url: entity.url,
      filePath: entity.filePath,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      downloadedAt: entity.downloadedAt,
      isDownloaded: entity.isDownloaded,
    );
  }

  PdfEntity toEntity() {
    return PdfEntity(
      url: url,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      downloadedAt: downloadedAt,
      isDownloaded: isDownloaded,
    );
  }

  @override
  PdfModel copyWith({
    String? url,
    String? filePath,
    String? fileName,
    int? fileSize,
    DateTime? downloadedAt,
    bool? isDownloaded,
  }) {
    return PdfModel(
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
