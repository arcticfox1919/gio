import 'dart:convert';
import 'dart:typed_data';
import 'package:gio/gio.dart';
import 'package:gio/src/gio_config.dart';
import 'package:gio/src/http_delegator.dart';
import 'package:gio/src/interceptor/call_server_interceptor.dart';

import 'package:meta/meta.dart';
import 'client.dart';
import 'interceptor/real_interceptor_chain.dart';

Map<String, List<Interceptor>>? _groupTable;

GroupInterceptor group(String groupName) {
  _groupTable ??= {};
  if (!_groupTable!.containsKey(groupName)) {
    _groupTable![groupName] = <Interceptor>[];
  }
  return GroupInterceptor._(groupName);
}

class GroupInterceptor {
  final String name;

  GroupInterceptor._(this.name) : assert(_groupTable != null);

  void addInterceptor(Interceptor interceptor) {
    var interceptors = _groupTable![name];
    interceptors!.add(interceptor);
  }

  void clear() {
    _groupTable!.remove(name);
  }

  set interceptors(List<Interceptor> interceptors) {
    var intercept = _groupTable![name];
    for (var e in interceptors) {
      intercept!.add(e);
    }
  }
}

class Gio implements Client {
  static GioOption? _option;

  final _globalInterceptors = <Interceptor>[];
  final _localInterceptors = <Interceptor>[];
  late final HttpDelegator _delegator;
  late final List<Interceptor> _gioInterceptors;
  late final String basePath;

  static set option(GioOption option) {
    _option = option;
  }

  Gio({String? baseUrl, GioContext? context}) {
    _option ??= GioOption();
    basePath = baseUrl ?? _option!.basePath;
    final cfg =
        GioConfig(proxy: _option?.proxy, context: context ?? _option?.context);
    if (_option!.delegatorFactory != null) {
      _delegator = _option!.delegatorFactory!(cfg);
    } else {
      _delegator = createDelegator(cfg);
    }

    final callServer =
        _option!.mockInterceptor ?? CallServerInterceptor(_delegator);
    final logger = _option!.logInterceptor ??
        (_option!.enableLog ? GioLogInterceptor() : null);

    if (logger != null) {
      _gioInterceptors = [
        logger.call,
        (_option!.connectInterceptor ?? DefaultConnectInterceptor()).call,
        callServer.call
      ];
    } else {
      _gioInterceptors = [
        (_option!.connectInterceptor ?? DefaultConnectInterceptor()).call,
        callServer.call
      ];
    }

    for (var e in _option!.globalInterceptors) {
      _globalInterceptors.add(e);
    }
  }

  @internal
  HttpDelegator createDelegator(GioConfig config) => HttpDelegator(config);

  void addInterceptor(Interceptor interceptor) {
    _localInterceptors.add(interceptor);
  }

  void removeInterceptor(Interceptor interceptor) {
    _localInterceptors.remove(interceptor);
  }

  @override
  Future<Response> head(String path,
          {Map<String, String>? headers,
          Map<String, dynamic>? queryParameters}) =>
      headUri(Uri.parse(path).replace(queryParameters: queryParameters),
          headers: headers);

  @override
  Future<Response> headUri(Uri url, {Map<String, String>? headers}) =>
      _sendUnstreamed('HEAD', _mergeUri(url), headers);

  @override
  Future<Response> get(String path,
          {Map<String, String>? headers,
          Map<String, dynamic>? queryParameters}) =>
      getUri(Uri.parse(path).replace(queryParameters: queryParameters),
          headers: headers);

  @override
  Future<Response> getUri(Uri url, {Map<String, String>? headers}) =>
      _sendUnstreamed('GET', _mergeUri(url), headers);

  @override
  Future<Response> post(String path,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          Map<String, dynamic>? queryParameters}) =>
      postUri(Uri.parse(path).replace(queryParameters: queryParameters),
          headers: headers, body: body, encoding: encoding);

  @override
  Future<Response> postUri(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      _sendUnstreamed('POST', _mergeUri(url), headers, body, encoding);

  @override
  Future<Response> put(String path,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          Map<String, dynamic>? queryParameters}) =>
      putUri(Uri.parse(path).replace(queryParameters: queryParameters),
          headers: headers, body: body, encoding: encoding);

  @override
  Future<Response> putUri(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      _sendUnstreamed('PUT', _mergeUri(url), headers, body, encoding);

  @override
  Future<Response> patch(String path,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          Map<String, dynamic>? queryParameters}) =>
      patchUri(Uri.parse(path).replace(queryParameters: queryParameters),
          headers: headers, body: body, encoding: encoding);

  @override
  Future<Response> patchUri(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      _sendUnstreamed('PATCH', _mergeUri(url), headers, body, encoding);

  @override
  Future<Response> delete(String path,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          Map<String, dynamic>? queryParameters}) =>
      deleteUri(Uri.parse(path).replace(queryParameters: queryParameters),
          headers: headers, body: body, encoding: encoding);

  @override
  Future<Response> deleteUri(Uri url,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      _sendUnstreamed('DELETE', _mergeUri(url), headers, body, encoding);

  @override
  Future<String> read(String path,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParameters}) async {
    final response =
        await get(path, headers: headers, queryParameters: queryParameters);
    _checkResponseSuccess(_getUri(path), response);
    return response.body;
  }

  @override
  Future<String> readUri(Uri url, {Map<String, String>? headers}) async {
    final response = await getUri(url, headers: headers);
    _checkResponseSuccess(_mergeUri(url), response);
    return response.body;
  }

  @override
  Future<Uint8List> readBytes(String path,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParameters}) async {
    final response =
        await get(path, headers: headers, queryParameters: queryParameters);
    _checkResponseSuccess(_getUri(path), response);
    return response.bodyBytes;
  }

  @override
  Future<Uint8List> readBytesUri(Uri url,
      {Map<String, String>? headers}) async {
    final response = await getUri(url, headers: headers);
    _checkResponseSuccess(_mergeUri(url), response);
    return response.bodyBytes;
  }

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request) {
    return _handleInterceptors(request);
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<Response> _sendUnstreamed(
      String method, Uri url, Map<String, String>? headers,
      [Object? body, Encoding? encoding]) async {
    var request = Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return Response.fromStream(await _handleInterceptors(request));
  }

  Uri _getUri(String path) => Uri.parse("$basePath$path");

  Uri _mergeUri(Uri url) {
    if (basePath.isNotEmpty) {
      var baseUri = Uri.parse(basePath);
      return url.replace(scheme: baseUri.scheme, host: baseUri.host);
    } else {
      return url;
    }
  }

  Future<StreamedResponse> _handleInterceptors(BaseRequest request) {
    var intercept = <Interceptor>[];
    if (_localInterceptors.isNotEmpty) {
      intercept.addAll(_localInterceptors);
    }
    intercept.addAll(_globalInterceptors);
    intercept.addAll(_gioInterceptors);

    final chain = RealInterceptorChain(intercept.iterator, request);
    return chain.proceed(request);
  }

  /// Throws an error if [response] is not successful.
  void _checkResponseSuccess(Uri url, Response response) {
    if (response.statusCode < 400) return;
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    throw ClientException('$message.', url);
  }

  @override
  void close() {
    _delegator.close();
  }
}

class GioGroup extends Gio {
  final String name;

  GioGroup(this.name) {
    assert(_groupTable != null);
    _groupTable![name] = <Interceptor>[];
  }

  @override
  Future<StreamedResponse> _handleInterceptors(BaseRequest request) {
    var intercept = <Interceptor>[];
    if (_localInterceptors.isNotEmpty) {
      intercept.addAll(_localInterceptors);
    }

    var groupInterceptors = _groupTable![name];
    if (groupInterceptors != null && groupInterceptors.isNotEmpty) {
      intercept.addAll(groupInterceptors);
    }

    intercept.addAll(_globalInterceptors);
    intercept.addAll(_gioInterceptors);

    final chain = RealInterceptorChain(intercept.iterator, request);
    return chain.proceed(request);
  }
}
