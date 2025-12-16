# PDF Utils

A Flutter application for downloading, sharing, and opening PDF files with clean architecture (MVVM + BLoC).

## Features

- 📥 Download PDFs from URLs
- 📤 Share downloaded PDFs
- 📄 Open PDFs with external viewer
- 📊 Download progress tracking
- ❌ Cancel ongoing downloads
- 🔐 Handle storage permissions

## Architecture

This project follows **Clean Architecture** principles with the following layers:

```
lib/
├── core/                      # Core utilities and services
│   ├── constants/             # App constants (colors, API endpoints)
│   ├── error/                 # Custom exceptions and failures
│   ├── network/               # Dio HTTP client
│   └── services/              # Permission and file services
├── features/
│   └── pdf_downloader/
│       ├── data/              # Data layer
│       │   ├── datasources/   # Remote data sources
│       │   ├── models/        # Data models
│       │   └── repositories/  # Repository implementations
│       ├── domain/            # Domain layer
│       │   ├── entities/      # Business entities
│       │   ├── repositories/  # Repository interfaces
│       │   └── usecases/      # Use cases
│       └── presentation/      # Presentation layer
│           ├── cubit/         # BLoC state management
│           ├── screens/       # UI screens
│           └── widgets/       # Reusable widgets
└── injection_container.dart   # Dependency injection setup
```

## Packages Used

| Package | Version | Description |
|---------|---------|-------------|
| `flutter_bloc` | ^9.1.0 | State management using BLoC/Cubit pattern |
| `dio` | ^5.9.0 | HTTP client for network requests |
| `dartz` | ^0.10.1 | Functional programming (Either type for error handling) |
| `get_it` | ^8.0.3 | Dependency injection service locator |
| `permission_handler` | ^12.0.0+1 | Handle runtime permissions |
| `path_provider` | ^2.1.5 | Access device file system paths |
| `share_plus` | ^12.0.1 | Share files to other apps |
| `open_filex` | ^4.7.0 | Open files with default app |
| `equatable` | ^2.0.7 | Simplify equality comparisons |
| `modern_toast` | ^0.0.5 | Display toast messages |

---

## Technical Implementation Details

### Data Source Layer

The `PdfRemoteDataSource` is the core component handling all PDF operations. It abstracts the implementation details from the repository layer.

#### Interface Definition

```dart
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
```

---

### HTTP Client (DioClient)

The `DioClient` wraps Dio with pre-configured settings for reliable downloads:

```dart
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': '*/*',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...',
        },
      ),
    );

    // Logging interceptor for debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        log('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        log('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        return handler.next(error);
      },
    ));
  }
}
```

**Key Features:**
- **Timeouts**: 30s connect, 60s receive, 30s send
- **User-Agent Header**: Mimics browser to avoid server blocks
- **Logging Interceptor**: Logs all requests/responses for debugging

---

### Download Flow

The download process uses a **two-attempt strategy** for maximum compatibility:

```
┌─────────────────────────────────────────────────────────────┐
│                    DOWNLOAD FLOW                            │
├─────────────────────────────────────────────────────────────┤
│  1. Check storage permissions                               │
│     └── Android: Handle different API levels (11+, 13+)     │
│     └── iOS: Return true (handled by system)                │
│                                                             │
│  2. Generate save path                                      │
│     └── Android: /storage/emulated/0/Download/              │
│     └── iOS: Application Documents Directory                │
│                                                             │
│  3. Attempt 1: Direct byte download                         │
│     └── GET request with ResponseType.bytes                 │
│     └── Write bytes directly to file                        │
│                                                             │
│  4. If Attempt 1 fails → Attempt 2: Dio download()          │
│     └── Uses Dio's built-in download method                 │
│     └── Handles redirects and streaming                     │
│                                                             │
│  5. Verify file exists and has content                      │
│                                                             │
│  6. Return PdfModel with file metadata                      │
└─────────────────────────────────────────────────────────────┘
```

#### Download Implementation

```dart
Future<PdfModel> downloadPdf({
  required String url,
  required String savePath,
  CancelToken? cancelToken,
  void Function(int received, int total)? onProgress,
}) async {
  // ATTEMPT 1: Direct byte download
  try {
    final response = await dioClient.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,  // Get raw bytes
        followRedirects: true,             // Handle URL redirects
        validateStatus: (status) => status != null && status < 500,
      ),
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,       // Progress callback
    );

    if (response.statusCode == 200 && response.data != null) {
      final file = File(savePath);
      await file.writeAsBytes(response.data!);  // Save to disk
      
      return PdfModel(
        url: url,
        filePath: savePath,
        fileName: savePath.split('/').last,
        fileSize: await file.length(),
        downloadedAt: DateTime.now(),
        isDownloaded: true,
      );
    }
  } on DioException catch (e) {
    if (e.type == DioExceptionType.cancel) {
      throw const CancelledException('Download cancelled by user');
    }
    // Fall through to attempt 2
  }

  // ATTEMPT 2: Dio download method (fallback)
  await dioClient.download(
    url,
    savePath,
    options: Options(followRedirects: true),
    cancelToken: cancelToken,
    onReceiveProgress: onProgress,
  );

  // Verify and return
  final file = File(savePath);
  if (await file.exists() && await file.length() > 0) {
    return PdfModel(...);
  }
  
  throw const ServerException('Download failed');
}
```

**Why Two Attempts?**
1. **Byte download** gives more control and works with most servers
2. **Dio download()** handles edge cases like chunked transfers and special redirects

---

### Progress Tracking

Progress is tracked via callback and emitted through Cubit state:

```dart
// In PdfCubit
final result = await downloadPdfUseCase(
  url: url,
  savePath: savePath,
  cancelToken: _cancelToken,
  onProgress: (received, total) {
    if (total != -1 && !isClosed) {
      final progress = received / total;
      emit(state.copyWith(
        status: PdfStatus.downloading,
        downloadProgress: progress,  // 0.0 to 1.0
        progressMessage: 'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
      ));
    }
  },
);
```

---

### Cancel Download

Downloads can be cancelled using Dio's `CancelToken`:

```dart
CancelToken? _cancelToken;

Future<void> downloadPdf(String url) async {
  _cancelToken = CancelToken();
  
  final result = await downloadPdfUseCase(
    url: url,
    savePath: savePath,
    cancelToken: _cancelToken,  // Pass token
    ...
  );
}

void cancelDownload() {
  _cancelToken?.cancel('Download cancelled by user');
  emit(state.copyWith(status: PdfStatus.cancelled));
}
```

---

### Open PDF

Uses `open_filex` package to open PDF with the device's default PDF viewer:

```dart
Future<bool> openPdf(String filePath) async {
  final file = File(filePath);
  
  // Verify file exists
  if (!await file.exists()) {
    throw const StorageException('File does not exist');
  }

  // Open with system default app
  final result = await OpenFilex.open(
    filePath, 
    type: 'application/pdf',  // MIME type
  );
  
  if (result.type != ResultType.done) {
    throw StorageException('Failed to open file: ${result.message}');
  }
  
  return true;
}
```

**Result Types:**
- `ResultType.done` - Successfully opened
- `ResultType.error` - Error occurred
- `ResultType.noAppToOpen` - No app can handle PDF
- `ResultType.permissionDenied` - Permission denied
- `ResultType.fileNotFound` - File not found

---

### Share PDF

Uses `share_plus` package to share PDF via system share sheet:

```dart
Future<bool> sharePdf(String filePath) async {
  final file = File(filePath);
  
  if (!await file.exists()) {
    throw const StorageException('File does not exist');
  }

  await Share.shareXFiles(
    [XFile(filePath)],        // File to share
    text: 'PDF Document',      // Optional text
    subject: 'Sharing PDF',    // Email subject line
  );
  
  return true;
}
```

**Share Options:**
- Share to email, messaging apps, cloud storage
- iOS: Uses UIActivityViewController
- Android: Uses ACTION_SEND intent

---

### Error Handling

The app uses a layered error handling approach:

#### Exception Types (Data Layer)

```dart
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class NetworkException implements Exception { ... }
class StorageException implements Exception { ... }
class PermissionException implements Exception { ... }
class CancelledException implements Exception { ... }
```

#### Failure Types (Domain Layer)

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class StorageFailure extends Failure { ... }
class PermissionFailure extends Failure { ... }
class CancelledFailure extends Failure { ... }
```

#### Exception → Failure Conversion (Repository)

```dart
// In repository implementation
try {
  final result = await remoteDataSource.downloadPdf(...);
  return Right(result);  // Success
} on ServerException catch (e) {
  return Left(ServerFailure(e.message));  // Convert to failure
} on CancelledException catch (e) {
  return Left(CancelledFailure(e.message));
}
```

---

### Data Model

```dart
class PdfModel extends PdfEntity {
  const PdfModel({
    required super.url,       // Original download URL
    super.filePath,           // Local file path
    super.fileName,           // File name
    super.fileSize,           // Size in bytes
    super.downloadedAt,       // Download timestamp
    super.isDownloaded,       // Download status
  });

  factory PdfModel.fromEntity(PdfEntity entity) { ... }
  PdfEntity toEntity() { ... }
  PdfModel copyWith(...) { ... }
}
```

---

### Permission Handling

Platform-specific permission logic:

```dart
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final androidVersion = await _getAndroidVersion();
    
    if (androidVersion >= 33) {
      // Android 13+: No storage permission needed for app-specific dirs
      return true;
    } else if (androidVersion >= 30) {
      // Android 11-12: Need MANAGE_EXTERNAL_STORAGE
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      // Android 10 and below: Regular storage permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  } else if (Platform.isIOS) {
    // iOS handles storage differently - app sandbox
    return true;
  }
  return false;
}
```

---

### File Path Generation

```dart
class FileService {
  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Use public Downloads folder on Android
      Directory directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else {
      // Use app documents directory on iOS
      return await getApplicationDocumentsDirectory();
    }
  }

  String generateFileName({String prefix = 'document', String extension = 'pdf'}) {
    // Unique filename using timestamp
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }
}
```

## Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<!-- Photo Library Permission (for saving files) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to save PDF files to your photo library.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save PDF files.</string>

<!-- File Sharing -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

<!-- Document Types for PDF -->
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>PDF Document</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.adobe.pdf</string>
        </array>
    </dict>
</array>
```

## How to Reuse This Code

### 1. Copy the Core Services

Copy the `lib/core/` folder to your project:

- **PermissionService**: Handles storage permissions across platforms
- **FileService**: Manages file operations (save, delete, path generation)
- **DioClient**: Configured HTTP client for downloads

### 2. Copy the PDF Feature Module

Copy `lib/features/pdf_downloader/` to your project and adapt as needed.

### 3. Setup Dependency Injection

Use `injection_container.dart` as a template:

```dart
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Register your Cubits
  sl.registerFactory(() => PdfCubit(
    downloadPdfUseCase: sl(),
    sharePdfUseCase: sl(),
    openPdfUseCase: sl(),
    checkPermissionUseCase: sl(),
    getDownloadPathUseCase: sl(),
    fileService: sl(),
  ));

  // Register Use Cases
  sl.registerLazySingleton(() => DownloadPdfUseCase(sl()));
  sl.registerLazySingleton(() => SharePdfUseCase(sl()));
  sl.registerLazySingleton(() => OpenPdfUseCase(sl()));
  sl.registerLazySingleton(() => CheckPermissionUseCase(sl()));
  sl.registerLazySingleton(() => GetDownloadPathUseCase(sl()));

  // Register Repository
  sl.registerLazySingleton<PdfRepository>(
    () => PdfRepositoryImpl(remoteDataSource: sl()),
  );

  // Register Data Sources
  sl.registerLazySingleton<PdfRemoteDataSource>(
    () => PdfRemoteDataSourceImpl(
      dioClient: sl(),
      permissionService: sl(),
      fileService: sl(),
    ),
  );

  // Register Core Services
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton(() => PermissionService());
  sl.registerLazySingleton(() => FileService());
}
```

### 4. Use the PdfCubit in Your UI

```dart
BlocProvider(
  create: (_) => sl<PdfCubit>(),
  child: BlocBuilder<PdfCubit, PdfState>(
    builder: (context, state) {
      // Handle states: initial, downloading, downloaded, error
      return YourWidget();
    },
  ),
)
```

### 5. Download a PDF

```dart
context.read<PdfCubit>().downloadPdf('https://example.com/file.pdf');
```

### 6. Share/Open Downloaded PDF

```dart
// Share
context.read<PdfCubit>().sharePdf();

// Open
context.read<PdfCubit>().openPdf();
```

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`

## Requirements

- Flutter SDK: ^3.8.1
- Dart SDK: ^3.8.1

## License

This project is open source and available under the MIT License.
