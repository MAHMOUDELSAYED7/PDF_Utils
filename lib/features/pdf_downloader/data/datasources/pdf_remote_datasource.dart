import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/services/permission_service.dart';
import '../models/pdf_model.dart';

abstract class PdfRemoteDataSource {
  Future<PdfModel> downloadPdf({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  });

  Future<bool> sharePdf(String filePath);

  Future<bool> openPdf(String filePath);

  Future<bool> deletePdf(String filePath);

  Future<bool> checkPermission();

  Future<String> getDownloadPath(String fileName);
}

class PdfRemoteDataSourceImpl implements PdfRemoteDataSource {
  final DioClient dioClient;
  final PermissionService permissionService;
  final FileService fileService;

  PdfRemoteDataSourceImpl({
    required this.dioClient,
    required this.permissionService,
    required this.fileService,
  });

  @override
  Future<PdfModel> downloadPdf({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      log('Starting download from: $url');
      log('Saving to: $savePath');

      // First attempt: Direct byte download
      try {
        final response = await dioClient.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
        );

        if (response.statusCode == 200 && response.data != null) {
          final file = File(savePath);
          await file.writeAsBytes(response.data!);

          if (await file.exists() && await file.length() > 0) {
            log('Download successful. File size: ${await file.length()} bytes');
            return PdfModel(
              url: url,
              filePath: savePath,
              fileName: savePath.split('/').last,
              fileSize: await file.length(),
              downloadedAt: DateTime.now(),
              isDownloaded: true,
            );
          }
        }
        throw ServerException('Failed to download file: ${response.statusCode}');
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          throw const CancelledException('Download cancelled by user');
        }
        log('Direct download failed, trying alternative method: $e');
      }

      // Second attempt: Dio download method
      await dioClient.download(
        url,
        savePath,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      final file = File(savePath);
      if (await file.exists() && await file.length() > 0) {
        log('Alternative download successful. File size: ${await file.length()} bytes');
        return PdfModel(
          url: url,
          filePath: savePath,
          fileName: savePath.split('/').last,
          fileSize: await file.length(),
          downloadedAt: DateTime.now(),
          isDownloaded: true,
        );
      }

      throw const ServerException('Download failed: File is empty or invalid');
    } on CancelledException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const CancelledException('Download cancelled by user');
      }
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      if (e is CancelledException || e is ServerException) {
        rethrow;
      }
      throw ServerException('Download failed: $e');
    }
  }

  @override
  Future<bool> sharePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const StorageException('File does not exist');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PDF Document',
        subject: 'Sharing PDF',
      );
      return true;
    } catch (e) {
      throw StorageException('Failed to share file: $e');
    }
  }

  @override
  Future<bool> openPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const StorageException('File does not exist');
      }

      final result = await OpenFilex.open(filePath, type: 'application/pdf');
      if (result.type != ResultType.done) {
        throw StorageException('Failed to open file: ${result.message}');
      }
      return true;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to open file: $e');
    }
  }

  @override
  Future<bool> deletePdf(String filePath) async {
    try {
      await fileService.deleteFile(filePath);
      return true;
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }

  @override
  Future<bool> checkPermission() async {
    try {
      return await permissionService.requestStoragePermission();
    } catch (e) {
      throw PermissionException('Permission error: $e');
    }
  }

  @override
  Future<String> getDownloadPath(String fileName) async {
    try {
      final directory = await fileService.getDownloadDirectory();
      return '${directory.path}/$fileName';
    } catch (e) {
      throw StorageException('Failed to get download path: $e');
    }
  }
}
