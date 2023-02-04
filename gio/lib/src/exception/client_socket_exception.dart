import 'dart:io';

import 'exception.dart';

/// Exception thrown when the underlying [HttpClient] throws a
/// [SocketException].
///
/// Implemenents [SocketException] to avoid breaking existing users of
/// [IOClient] that may catch that exception.
class ClientSocketException extends ClientException
    implements SocketException {
  final SocketException cause;
  ClientSocketException(SocketException e, Uri url)
      : cause = e,
        super(e.message, url);

  @override
  InternetAddress? get address => cause.address;

  @override
  OSError? get osError => cause.osError;

  @override
  int? get port => cause.port;
}