import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../gio_config.dart';
import 'delegator_factory.dart' as pkg_http_factory;

/// Transport interface that abstracts the underlying HTTP implementation.
///
/// Implementations may be based on `package:http`, native IO, browser XHR,
/// or any other transport. Use [HttpDelegator.new] factory to construct the
/// platform-appropriate instance.
abstract interface class HttpDelegator {
  factory HttpDelegator([GioConfig? config]) => createHttpDelegator(config);

  /// Sends an HTTP request and asynchronously returns the http.Response.
  Future<http.StreamedResponse> send(http.BaseRequest request);

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// Some clients maintain a pool of network connections that will not be
  /// disconnected until the client is closed. This may cause programs using
  /// using the Dart SDK (`dart run`, `dart test`, `dart compile`, etc.) to
  /// not terminate until the client is closed. Programs run using the Flutter
  /// SDK can still terminate even with an active connection pool.
  ///
  /// Once [close] is called, no other methods should be called. If [close] is
  /// called while other asynchronous methods are running, the behavior is
  /// undefined.
  void close();
}

/// Default delegator factory uses package:http-based transport with per-platform clients.
HttpDelegator createHttpDelegator([GioConfig? config]) =>
    pkg_http_factory.createPkgHttpDelegator(config);
