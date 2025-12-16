import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/pdf_repository.dart';

class OpenPdfUseCase {
  final PdfRepository repository;

  OpenPdfUseCase(this.repository);

  Future<Either<Failure, bool>> call(String filePath) async {
    return await repository.openPdf(filePath);
  }
}
