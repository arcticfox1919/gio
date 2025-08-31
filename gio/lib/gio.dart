/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' show Response;
import 'src/gio_interface.dart';

export 'src/gio_interface.dart';
export 'src/gio_client.dart';
export 'src/gio_option.dart';
export 'src/interceptor/interceptor.dart';
export 'src/interceptor/connect_interceptor.dart';
export 'src/interceptor/log_interceptor.dart';
export 'src/interceptor/mock_interceptor.dart';
// Re-export core types from package:http to avoid duplicating local implementations
export 'package:http/http.dart'
    show
        BaseRequest,
        Request,
        StreamedRequest,
        MultipartRequest,
        MultipartFile,
        BaseResponse,
        Response,
        StreamedResponse,
        ByteStream;
export 'src/exception/exception.dart';
export 'src/gio_context.dart';
export 'src/exception/error.dart';
// Export transfer functionality as extension methods
export 'src/transfer/gio_transfer_methods.dart';
// Export JSON functionality
export 'src/json/json_response_extension.dart';
export 'src/json/gio_json_codec.dart';

/// Sends an HTTP HEAD request with the given headers to the given URL.
///
/// This automatically initializes a new [Gio] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Gio] for all of those requests.
///
/// For more fine-grained control over the request, use [send] instead.
Future<Response> head(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) =>
        client.head(path, headers: headers, queryParameters: queryParameters));

/// Sends an HTTP GET request with the given headers to the given URL.
///
/// This automatically initializes a new [Gio] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Gio] for all of those requests.
///
/// For more fine-grained control over the request, use [send] instead.
Future<Response> get(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) =>
        client.get(path, headers: headers, queryParameters: queryParameters));

/// Sends an HTTP POST request with the given headers and body to the given URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>]
/// or a [Map<String, String>].
///
/// [jsonBody] sets the body as JSON data. This parameter is mutually exclusive
/// with [body]. When specified, the data will be JSON-encoded and the
/// content-type will be set to "application/json".
///
/// [parallelJson] controls whether JSON encoding should be performed in a background
/// isolate to avoid blocking the UI thread. When null (default), uses the global
/// setting from [GioOption.parallelJson]. When specified (true/false),
/// overrides the global setting for this request only. Only applies when [jsonBody] is used.
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
Future<Response> post(String path,
        {Map<String, String>? headers,
        Object? body,
        Object? jsonBody,
        bool? parallelJson,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.post(path,
        headers: headers,
        body: body,
        jsonBody: jsonBody,
        parallelJson: parallelJson,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP PUT request with the given headers and body to the given URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>]
/// or a [Map<String, String>]. If it's a String, it's encoded using
/// [encoding] and used as the body of the request. The content-type of the
/// request will default to "text/plain".
///
/// [jsonBody] sets the body as JSON data. This parameter is mutually exclusive
/// with [body]. When specified, the data will be JSON-encoded and the
/// content-type will be set to "application/json".
///
/// [parallelJson] controls whether JSON encoding should be performed in a background
/// isolate to avoid blocking the UI thread. When null (default), uses the global
/// setting from [GioOption.parallelJson]. When specified (true/false),
/// overrides the global setting for this request only. Only applies when [jsonBody] is used.
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
Future<Response> put(String path,
        {Map<String, String>? headers,
        Object? body,
        Object? jsonBody,
        bool? parallelJson,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.put(path,
        headers: headers,
        body: body,
        jsonBody: jsonBody,
        parallelJson: parallelJson,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP PATCH request with the given headers and body to the given
/// URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>]
/// or a [Map<String, String>]. If it's a String, it's encoded using
/// [encoding] and used as the body of the request. The content-type of the
/// request will default to "text/plain".
///
/// [jsonBody] sets the body as JSON data. This parameter is mutually exclusive
/// with [body]. When specified, the data will be JSON-encoded and the
/// content-type will be set to "application/json".
///
/// [parallelJson] controls whether JSON encoding should be performed in a background
/// isolate to avoid blocking the UI thread. When null (default), uses the global
/// setting from [GioOption.parallelJson]. When specified (true/false),
/// overrides the global setting for this request only. Only applies when [jsonBody] is used.
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
Future<Response> patch(String path,
        {Map<String, String>? headers,
        Object? body,
        Object? jsonBody,
        bool? parallelJson,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.patch(path,
        headers: headers,
        body: body,
        jsonBody: jsonBody,
        parallelJson: parallelJson,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP DELETE request with the given headers to the given URL.
///
/// [jsonBody] sets the body as JSON data. This parameter is mutually exclusive
/// with [body]. When specified, the data will be JSON-encoded and the
/// content-type will be set to "application/json".
///
/// [parallelJson] controls whether JSON encoding should be performed in a background
/// isolate to avoid blocking the UI thread. When null (default), uses the global
/// setting from [GioOption.parallelJson]. When specified (true/false),
/// overrides the global setting for this request only. Only applies when [jsonBody] is used.
///
/// For more fine-grained control over the request, use [send] instead.
Future<Response> delete(String path,
        {Map<String, String>? headers,
        Object? body,
        Object? jsonBody,
        bool? parallelJson,
        Encoding? encoding,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.delete(path,
        headers: headers,
        body: body,
        jsonBody: jsonBody,
        parallelJson: parallelJson,
        encoding: encoding,
        queryParameters: queryParameters));

/// Sends an HTTP GET request with the given headers to the given URL and
/// returns a Future that completes to the body of the response as a [String].
///
/// The Future will emit a [ClientException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Gio] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Gio] for all of those requests.
///
/// For more fine-grained control over the request and response, use [send] or
/// [get] instead.
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
/// This automatically initializes a new [Gio] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Gio] for all of those requests.
///
/// For more fine-grained control over the request and response, use [send] or
/// [get] instead.
Future<Uint8List> readBytes(String path,
        {Map<String, String>? headers,
        Map<String, dynamic>? queryParameters}) =>
    _withClient((client) => client.readBytes(path,
        headers: headers, queryParameters: queryParameters));

Future<T> _withClient<T>(Future<T> Function(Gio) fn) async {
  var gio = Gio();
  try {
    return await fn(gio);
  } finally {
    gio.close();
  }
}
