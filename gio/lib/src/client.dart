import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../gio.dart' as gio;
import 'exception/exception.dart';
import 'response.dart';

/// The interface for HTTP clients that take care of maintaining persistent
/// connections across multiple requests to the same server.
///
/// If you only need to send a single request, it's usually easier to use
/// [gio.head], [gio.get], [gio.post], [gio.put], [gio.patch], or
/// [gio.delete] instead.
///
/// When creating an HTTP client class with additional functionality, you must
/// extend [BaseClient] rather than [Client]. In most cases, you can wrap
/// another instance of [Client] and add functionality on top of that. This
/// allows all classes implementing [Client] to be mutually composable.
abstract class Client {
  /// Sends an HTTP HEAD request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(String url, {Map<String, String>? headers});
  Future<Response> headUri(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP GET request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(String url, {Map<String, String>? headers});
  Future<Response> getUri(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP POST request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>].
  ///
  /// If [body] is a String, it's encoded using [encoding] and used as the body
  /// of the request. The content-type of the request will default to
  /// "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(String url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  Future<Response> postUri(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP PUT request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(String url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  Future<Response> putUri(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP PATCH request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> patch(String url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  Future<Response> patchUri(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP DELETE request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> delete(String url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  Future<Response> deleteUri(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a String.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(String url, {Map<String, String>? headers});
  Future<String> readUri(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a list of
  /// bytes.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<Uint8List> readBytes(String url, {Map<String, String>? headers});
  Future<Uint8List> readBytesUri(Uri url, {Map<String, String>? headers});

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to
  /// do so can cause the Dart process to hang.
  void close();
}
