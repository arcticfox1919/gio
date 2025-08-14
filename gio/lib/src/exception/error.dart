class ConnectiveError extends StateError {
  int? code;

  ConnectiveError(
    this.code, [
    String message = '',
  ]) : super('Network connection error: [$code]$message');
}

class InterceptorError extends Error {
  final String message;
  final String name;

  InterceptorError(this.name, this.message);

  @override
  String toString() => "$name: $message";
}
