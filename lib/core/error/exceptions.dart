class ServerException implements Exception {
  final String message;

  const ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);
}

class StorageException implements Exception {
  final String message;

  const StorageException(this.message);
}

class PermissionException implements Exception {
  final String message;

  const PermissionException(this.message);
}

class CancelledException implements Exception {
  final String message;

  const CancelledException(this.message);
}
