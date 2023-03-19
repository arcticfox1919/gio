/// Support for doing something awesome.
///
/// More dartdocs go here.
library gio;

import 'dart:convert';
import 'dart:typed_data';

import 'package:gio/src/gio_client.dart';
import 'package:gio/src/response.dart';

import 'src/client.dart';

export 'src/gio_client.dart';
export 'src/gio_option.dart';
export 'src/interceptor/interceptor.dart';
export 'src/interceptor/connect_interceptor.dart';
export 'src/interceptor/log_interceptor.dart';
export 'src/interceptor/mock_interceptor.dart';
export 'src/base_request.dart';
export 'src/request.dart';
export 'src/streamed_request.dart';
export 'src/multipart_request.dart';
export 'src/base_response.dart';
export 'src/response.dart';
export 'src/streamed_response.dart';
export 'src/exception/exception.dart';
export 'src/gio_context.dart';
export 'src/exception/error.dart';

/// Sends an HTTP HEAD request with the given headers to the given URL.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> head(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) =>
        client.head(path, headers: headers, queryParameters: queryParameters));

/// Sends an HTTP GET request with the given headers to the given URL.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> get(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) =>
        client.get(path, headers: headers, queryParameters: queryParameters));

/// Sends an HTTP POST request with the given headers and body to the given URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>] or
/// a [Map<String, String>]. If it's a String, it's encoded using [encoding] and
/// used as the body of the request. The content-type of the request will
/// default to "text/plain".
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
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> post(String path,
        {Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.post(path,
        headers: headers,
        body: body,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP PUT request with the given headers and body to the given URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>] or
/// a [Map<String, String>]. If it's a String, it's encoded using [encoding] and
/// used as the body of the request. The content-type of the request will
/// default to "text/plain".
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
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> put(String path,
        {Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.put(path,
        headers: headers,
        body: body,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP PATCH request with the given headers and body to the given
/// URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>] or
/// a [Map<String, String>]. If it's a String, it's encoded using [encoding] and
/// used as the body of the request. The content-type of the request will
/// default to "text/plain".
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
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> patch(String path,
        {Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.patch(path,
        headers: headers,
        body: body,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP DELETE request with the given headers to the given URL.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> delete(String path,
        {Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.delete(path,
        headers: headers,
        body: body,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP GET request with the given headers to the given URL and
/// returns a Future that completes to the body of the response as a [String].
///
/// The Future will emit a [ClientException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request and response, use [Request]
/// instead.
Future<String> read(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) =>
        client.read(path, headers: headers, queryParameters: queryParameters));

/// Sends an HTTP GET request with the given headers to the given URL and
/// returns a Future that completes to the body of the response as a list of
/// bytes.
///
/// The Future will emit a [ClientException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request and response, use [Request]
/// instead.
Future<Uint8List> readBytes(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.readBytes(path,
        headers: headers, queryParameters: queryParameters));

Future<T> _withClient<T>(Future<T> Function(Client) fn) async {
  var gio = Gio();
  try {
    return await fn(gio);
  } finally {
    gio.close();
  }
}
