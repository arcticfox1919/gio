import 'dart:io';

import 'package:gio/src/base_request.dart';
import 'package:gio/src/http_delegator.dart';
import 'package:gio/src/io/io_context.dart';
import 'package:gio/src/streamed_response.dart';

import '../exception/client_socket_exception.dart';
import '../exception/exception.dart';
import '../gio_config.dart';
import 'io_streamed_response.dart';

/// Create an [IODelegator].
///
/// Used from conditional imports, matches the definition in `gio_stub.dart`.
HttpDelegator createHttpDelegator([GioConfig? config]) =>
    IODelegator(config: config);

class IODelegator implements HttpDelegator {
  HttpClient? _inner;

  IODelegator({HttpClient? client, GioConfig? config}) {
    if (client != null) {
      _inner = client;
    } else if (config?.context != null && config!.context is IOContext) {
      _inner = HttpClient(context: config.context?.context);
    } else {
      _inner = HttpClient();
    }

    if (config?.proxy != null) {
      _inner!.findProxy = (url) {
        return 'PROXY ${config!.proxy!.host}:${config.proxy!.port}';
      };
    }
  }

  /// Closes the client.
  ///
  /// Terminates all active connections. If a client remains unclosed, the Dart
  /// process may not terminate.
  @override
  void close() {
    if (_inner != null) {
      _inner!.close(force: true);
      _inner = null;
    }
  }

  /// Sends an HTTP request and asynchronously returns the response.
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (_inner == null) {
      throw ClientException(
          'HTTP request failed. Client is already closed.', request.url);
    }

    var stream = request.finalize();

    try {
      var ioRequest = (await _inner!.openUrl(request.method, request.url))
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..contentLength = (request.contentLength ?? -1)
        ..persistentConnection = request.persistentConnection;
      request.headers.forEach((name, value) {
        ioRequest.headers.set(name, value);
      });

      var response = await stream.pipe(ioRequest) as HttpClientResponse;

      var headers = <String, String>{};
      response.headers.forEach((key, values) {
        headers[key] = values.join(',');
      });

      return IOStreamedResponse(
          response.handleError((Object error) {
            final httpException = error as HttpException;
            throw ClientException(httpException.message, httpException.uri);
          }, test: (error) => error is HttpException),
          response.statusCode,
          contentLength:
              response.contentLength == -1 ? null : response.contentLength,
          request: request,
          headers: headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          inner: response);
    } on SocketException catch (error) {
      throw ClientSocketException(error, request.url);
    } on HttpException catch (error) {
      throw ClientException(error.message, error.uri);
    }
  }
}
