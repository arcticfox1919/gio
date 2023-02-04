/// An exception used to indicate that a request has been hijacked.
class HijackException implements Exception {
  const HijackException();

  @override
  String toString() =>
      "request's underlying data stream was hijacked.\n";
}
