import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../entities/pdf_entity.dart';

abstract class PdfRepository {
  Future<Either<Failure, PdfEntity>> downloadPdf({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  });

  Future<Either<Failure, bool>> sharePdf(String filePath);

  Future<Either<Failure, bool>> openPdf(String filePath);

  Future<Either<Failure, bool>> deletePdf(String filePath);

  Future<Either<Failure, bool>> checkPermission();

  Future<Either<Failure, String>> getDownloadPath(String fileName);
}
