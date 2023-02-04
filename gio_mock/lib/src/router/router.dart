import 'dart:async';
import 'dart:math';

import 'package:gio/gio.dart';
import 'package:gio_mock/src/http/response_x.dart';
import 'package:gio_mock/src/utilities/str.dart';

import '../http/handle.dart';
import '../http/http_methods.dart';
import '../http/middleware.dart';
import '../http/mock_request.dart';

part 'entry.dart';

/// Middleware to remove body from request.
final _removeBody = createMiddleware(responseHandler: (r) {
  if (r.headers.containsKey('content-length')) {
    r = r.change(headers: {'content-length': '0'});
  }
  return r.change(body: <int>[]);
});

class Router{

  /// The [notFoundHandler] will be invoked for requests where no matching route
  /// was found. By default, a simple [Response.notFound] will be used instead.
  Handler _notFoundHandler = _defaultNotFound;

  final Map<String, _Node> _trees = {};

  set notFoundHandler(Handler notFound){
    _notFoundHandler = notFound;
  }

  void add(String method, String route, Function handler,{Middleware? middleware}) {
    if (!isHttpMethod(method)) {
      throw ArgumentError.value(
          method, 'method', 'expected a valid HTTP method');
    }

    if (route.isEmpty || !route.startsWith('/')) {
      throw ArgumentError.value(
          method, 'route', 'path must begin with "/" in path "$route"');
    }
    method = method.toUpperCase();

    if (method == 'GET') {
      // Handling in a 'GET' request without handling a 'HEAD' request is always
      // wrong, thus, we add a default implementation that discards the body.
      _addRoute('HEAD', route, handler, middleware: _removeBody);
    }
    _addRoute(method, route, handler,middleware:middleware);
  }

  void _addRoute(String method, String path, Function handler,{Middleware? middleware}){
    var root = _trees[method];
    if(root == null){
      root = _Node.empty();
      _trees[method] = root;
    }

    _Node.addRoute(root, path, handler,middleware);
  }

  _NodeResult _getRoute(String method, String path) {
    var root = _trees[method];
    Map<String, String>? params;
    Function? handle;
    Middleware? middleware;

    if(root != null){
      var r = _Node.getValue(root, path);
      handle = r[0] as Function?;
      params = r[1] as Map<String, String>?;
      // var tsr = r[2] as bool;
      middleware = r[3] as Middleware?;

      return _NodeResult(root, params,handle,middleware);
    }
    return _NodeResult(root, params,handle,middleware);
  }

  RouterGroup group(String prefix){
    if (!prefix.startsWith('/')) {
      throw ArgumentError.value(
          prefix, 'prefix', 'must start with a slash');
    }
    return RouterGroup(prefix,this);
  }


  /// Route incoming requests to registered handlers.
  ///
  /// This method allows a Router instance to be a [Handler].
  FutureOr<Response> call(MockRequest request) async {
    var nodeResult = _getRoute(request.method,request.url.path);

    if(nodeResult._node != null){
      var params = nodeResult._params;
      var middleware = nodeResult._middleware;
      request = request.change(context: {'arowana/params': params});

      middleware ??= ((Handler fn) => fn);

      return await middleware((request) async {
        var handle = nodeResult._handle;
        if (handle is Handler) {
          return await handle.call(request);
        }

        if(handle != null && params != null){
          return await Function.apply(handle, [
            request,
            ...params.values,
          ]);
        }
        return _notFoundHandler(request);
      })(request);
    }
    return _notFoundHandler(request);
  }

  /// Handle `GET` request to [route] using [handler].
  ///
  /// If no matching handler for `HEAD` requests is registered, such requests
  /// will also be routed to the [handler] registered here.
  void get(String route, Function handler) => add('GET', route, handler);

  /// Handle `HEAD` request to [route] using [handler].
  void head(String route, Function handler) => add('HEAD', route, handler);

  /// Handle `POST` request to [route] using [handler].
  void post(String route, Function handler) => add('POST', route, handler);

  /// Handle `PUT` request to [route] using [handler].
  void put(String route, Function handler) => add('PUT', route, handler);

  /// Handle `DELETE` request to [route] using [handler].
  void delete(String route, Function handler) => add('DELETE', route, handler);

  /// Handle `CONNECT` request to [route] using [handler].
  void connect(String route, Function handler) =>
      add('CONNECT', route, handler);

  /// Handle `OPTIONS` request to [route] using [handler].
  void options(String route, Function handler) =>
      add('OPTIONS', route, handler);

  /// Handle `TRACE` request to [route] using [handler].
  void trace(String route, Function handler) => add('TRACE', route, handler);

  /// Handle `PATCH` request to [route] using [handler].
  void patch(String route, Function handler) => add('PATCH', route, handler);

  static Response _defaultNotFound(Request request) => routeNotFound;

  static final Response routeNotFound = _RouteNotFoundResponse();
}

class RouterGroup{
  String prefix;
  Router parent;
  Middleware? middleware;

  RouterGroup(this.prefix,this.parent);

  void add(String method, String route, Function handler) {
    parent.add(method, prefix+route, handler,middleware: middleware);
  }

  void use(Middleware middleware){
    this.middleware = middleware;
  }

  void get(String route, Function handler) => add('GET', route, handler);

  void head(String route, Function handler) => add('HEAD', route, handler);

  void post(String route, Function handler) => add('POST', route, handler);

  void put(String route, Function handler) => add('PUT', route, handler);

  void delete(String route, Function handler) => add('DELETE', route, handler);

  void connect(String route, Function handler) => add('CONNECT', route, handler);

  void options(String route, Function handler) => add('OPTIONS', route, handler);

  void trace(String route, Function handler) => add('TRACE', route, handler);

  void patch(String route, Function handler) => add('PATCH', route, handler);
}

/// Extends [Response] to allow it to be used multiple times in the
/// actual content being served.
class _RouteNotFoundResponse extends Response {
  static const _message = 'Route not found';

  _RouteNotFoundResponse() : super(_message, 404);
}