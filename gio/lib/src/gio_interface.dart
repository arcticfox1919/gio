import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../gio.dart' as gio;
import 'exception/exception.dart';
import 'package:http/http.dart' show Response, BaseRequest, StreamedResponse;
import 'gio_client.dart';
import 'gio_option.dart';
import 'interceptor/interceptor.dart';

/// The interface for HTTP clients that take care of maintaining persistent
/// connections across multiple requests to the same server.
///
/// If you only need to send a single request, it's usually easier to use
/// [gio.head], [gio.get], [gio.post], [gio.put], [gio.patch], or
/// [gio.delete] instead.
///
/// When creating an HTTP client class with additional functionality, you must
/// implement [Gio] rather than extending it. In most cases, you can wrap
/// another instance of [Gio] and add functionality on top of that. This
/// allows all classes implementing [Gio] to be mutually composable.
abstract interface class Gio {
  /// Creates a Gio instance using global configuration or defaults
  ///
  /// This constructor uses the global [GioOption] configuration, with optional
  /// overrides for [baseUrl] and [context].
  ///
  /// Example:
  /// ```dart
  /// // Use global configuration
  /// final gio = Gio();
  ///
  /// // Override base URL
  /// final customGio = Gio(baseUrl: 'https://api.custom.com');
  /// ```
  factory Gio({String? baseUrl, gio.GioContext? context}) =>
      GioClient(baseUrl: baseUrl, context: context);

  /// Creates a Gio instance with custom options, independent of global configuration
  ///
  /// This constructor allows you to create an isolated Gio client with its own
  /// configuration without affecting or being affected by the global [GioOption].
  ///
  /// Example:
  /// ```dart
  /// final customOption = GioOption(
  ///   basePath: 'https://api.custom.com',
  ///   enableLog: false,
  ///   globalInterceptors: [authInterceptor],
  /// );
  ///
  /// final customGio = Gio.withOption(customOption);
  /// ```
  factory Gio.withOption(gio.GioOption option) => GioClient.withOption(option);

  /// Sends an HTTP HEAD request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(String url,
      {Map<String, String>? headers, Map<String, dynamic>? queryParameters});

  Future<Response> headUri(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP GET request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(String url,
      {Map<String, String>? headers, Map<String, dynamic>? queryParameters});

  Future<Response> getUri(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP POST request with the given headers and body to the given
  /// URL.
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
  Future<Response> post(String url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding,
      Map<String, dynamic>? queryParameters});

  Future<Response> postUri(Uri url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding});

  /// Sends an HTTP PUT request with the given headers and body to the given
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
  Future<Response> put(String url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding,
      Map<String, dynamic>? queryParameters});

  Future<Response> putUri(Uri url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding});

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
  Future<Response> patch(String url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding,
      Map<String, dynamic>? queryParameters});

  Future<Response> patchUri(Uri url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding});

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
  Future<Response> delete(String url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding,
      Map<String, dynamic>? queryParameters});

  Future<Response> deleteUri(Uri url,
      {Map<String, String>? headers,
      Object? body,
      Object? jsonBody,
      bool? parallelJson,
      Encoding? encoding});

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a String.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(String url,
      {Map<String, String>? headers, Map<String, dynamic>? queryParameters});

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
  Future<Uint8List> readBytes(String url,
      {Map<String, String>? headers, Map<String, dynamic>? queryParameters});

  Future<Uint8List> readBytesUri(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request);

  /// Adds a local interceptor to this client instance.
  ///
  /// Local interceptors are specific to this [Gio] instance and are executed
  /// before global interceptors in the interceptor chain.
  ///
  /// Interceptors can be used to:
  /// - Add authentication headers
  /// - Log requests and responses
  /// - Implement retry logic
  /// - Transform requests or responses
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// gio.addInterceptor((chain) async {
  ///   final request = chain.request;
  ///   // Add custom header
  ///   request.headers['X-Custom-Header'] = 'value';
  ///   return chain.proceed(request);
  /// });
  /// ```
  void addInterceptor(Interceptor interceptor);

  /// Removes a previously added local interceptor from this client instance.
  ///
  /// The [interceptor] must be the same instance that was passed to
  /// [addInterceptor].
  ///
  void removeInterceptor(Interceptor interceptor);

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to
  /// do so can cause the Dart process to hang.
  void close();

  static set option(GioOption option) {
    GioClient.option = option;
  }
}
