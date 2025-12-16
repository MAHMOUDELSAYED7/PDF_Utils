import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/pdf_repository.dart';

class GetDownloadPathUseCase {
  final PdfRepository repository;

  GetDownloadPathUseCase(this.repository);

  Future<Either<Failure, String>> call(String fileName) async {
    return await repository.getDownloadPath(fileName);
  }
}
