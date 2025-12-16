import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pdf_entity.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/pdf_remote_datasource.dart';

class PdfRepositoryImpl implements PdfRepository {
  final PdfRemoteDataSource remoteDataSource;

  PdfRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PdfEntity>> downloadPdf({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final result = await remoteDataSource.downloadPdf(
        url: url,
        savePath: savePath,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CancelledException catch (e) {
      return Left(CancelledFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> sharePdf(String filePath) async {
    try {
      final result = await remoteDataSource.sharePdf(filePath);
      return Right(result);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(StorageFailure('Failed to share: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> openPdf(String filePath) async {
    try {
      final result = await remoteDataSource.openPdf(filePath);
      return Right(result);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(StorageFailure('Failed to open: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePdf(String filePath) async {
    try {
      final result = await remoteDataSource.deletePdf(filePath);
      return Right(result);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(StorageFailure('Failed to delete: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkPermission() async {
    try {
      final result = await remoteDataSource.checkPermission();
      return Right(result);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(PermissionFailure('Permission error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getDownloadPath(String fileName) async {
    try {
      final result = await remoteDataSource.getDownloadPath(fileName);
      return Right(result);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(StorageFailure('Failed to get path: $e'));
    }
  }
}
