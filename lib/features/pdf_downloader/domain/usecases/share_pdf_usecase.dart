import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/pdf_repository.dart';

class SharePdfUseCase {
  final PdfRepository repository;

  SharePdfUseCase(this.repository);

  Future<Either<Failure, bool>> call(String filePath) async {
    return await repository.sharePdf(filePath);
  }
}
