import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../entities/pdf_entity.dart';
import '../repositories/pdf_repository.dart';

class DownloadPdfUseCase {
  final PdfRepository repository;

  DownloadPdfUseCase(this.repository);

  Future<Either<Failure, PdfEntity>> call({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    return await repository.downloadPdf(
      url: url,
      savePath: savePath,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }
}
