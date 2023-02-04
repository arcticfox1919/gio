

class ConnectiveError extends StateError {
  int? code;

  ConnectiveError(
    this.code, [
    String message = '',
  ]) : super('Network connection error: [$code]$message');
}

class TimeoutError extends StateError {
  TimeoutError([String message = '']) : super('Network timeout error: $message');
}

class CancelError extends StateError {
  CancelError([String message = '']) : super('Request to cancel: $message');
}

class InterceptorError extends Error {
  final String message;
  final String name;

  InterceptorError(this.name, this.message);

  @override
  String toString() => "$name: $message";
}

class IllegalResponseError extends ArgumentError {}
