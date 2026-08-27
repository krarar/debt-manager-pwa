sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class DataException extends AppException {
  const DataException(super.message);
}
