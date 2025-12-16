import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/pdf_repository.dart';

class CheckPermissionUseCase {
  final PdfRepository repository;

  CheckPermissionUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.checkPermission();
  }
}
