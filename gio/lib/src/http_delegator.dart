import 'package:http/http.dart' as http;
import 'gio_config.dart';
import 'pkg_http/delegator_factory.dart' as pkg_http_factory;

/// Transport interface that abstracts the underlying HTTP implementation.
///
/// Implementations may be based on `package:http`, native IO, browser XHR,
/// or any other transport. Use [HttpDelegator.new] factory to construct the
/// platform-appropriate instance.
abstract interface class HttpDelegator {
  factory HttpDelegator([GioConfig? config]) => createHttpDelegator(config);

  /// Sends an HTTP request and asynchronously returns a streaming response.
  Future<http.StreamedResponse> send(http.BaseRequest request);

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to
  /// do so can cause the Dart process to hang.
  void close();
}

/// Default delegator factory uses package:http-based transport with per-platform clients.
HttpDelegator createHttpDelegator([GioConfig? config]) =>
    pkg_http_factory.createPkgHttpDelegator(config);
