import 'package:get_it/get_it.dart';

import 'core/network/dio_client.dart';
import 'core/services/file_service.dart';
import 'core/services/permission_service.dart';
import 'features/pdf_downloader/data/datasources/pdf_remote_datasource.dart';
import 'features/pdf_downloader/data/repositories/pdf_repository_impl.dart';
import 'features/pdf_downloader/domain/repositories/pdf_repository.dart';
import 'features/pdf_downloader/domain/usecases/check_permission_usecase.dart';
import 'features/pdf_downloader/domain/usecases/download_pdf_usecase.dart';
import 'features/pdf_downloader/domain/usecases/get_download_path_usecase.dart';
import 'features/pdf_downloader/domain/usecases/open_pdf_usecase.dart';
import 'features/pdf_downloader/domain/usecases/share_pdf_usecase.dart';
import 'features/pdf_downloader/presentation/cubit/pdf_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Cubit
  sl.registerFactory(
    () => PdfCubit(
      downloadPdfUseCase: sl(),
      sharePdfUseCase: sl(),
      openPdfUseCase: sl(),
      checkPermissionUseCase: sl(),
      getDownloadPathUseCase: sl(),
      fileService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => DownloadPdfUseCase(sl()));
  sl.registerLazySingleton(() => SharePdfUseCase(sl()));
  sl.registerLazySingleton(() => OpenPdfUseCase(sl()));
  sl.registerLazySingleton(() => CheckPermissionUseCase(sl()));
  sl.registerLazySingleton(() => GetDownloadPathUseCase(sl()));

  // Repository
  sl.registerLazySingleton<PdfRepository>(
    () => PdfRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<PdfRemoteDataSource>(
    () => PdfRemoteDataSourceImpl(
      dioClient: sl(),
      permissionService: sl(),
      fileService: sl(),
    ),
  );

  // Core
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton(() => PermissionService());
  sl.registerLazySingleton(() => FileService());
}
