class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message)';
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException({
    required this.message,
    this.statusCode = 401,
  });

  @override
  String toString() => 'AuthException(message: $message)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Network connection failed. Please check your internet.'});

  @override
  String toString() => 'NetworkException(message: $message)';
}

class StorageException implements Exception {
  final String message;

  const StorageException({required this.message});

  @override
  String toString() => 'StorageException(message: $message)';
}
