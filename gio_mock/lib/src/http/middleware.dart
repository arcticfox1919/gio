
import 'dart:async';

import 'package:gio/gio.dart';

import 'handle.dart';
import 'hijack_exception.dart';


/// A function which creates a new [Handler] by wrapping a [Handler].
///
/// You can extend the functions of a [Handler] by wrapping it in
/// [Middleware] that can intercept and process a request before it it sent
/// to a handler, a response after it is sent by a handler, or both.
///
/// Because [Middleware] consumes a [Handler] and returns a new
/// [Handler], multiple [Middleware] instances can be composed
/// together to offer rich functionality.
///
/// Common uses for middleware include caching, logging, and authentication.
///
/// Middleware that captures exceptions should be sure to pass
/// [HijackException]s on without modification.
///
/// A simple [Middleware] can be created using [createMiddleware].
typedef Middleware = Handler Function(Handler innerHandler);

/// Creates a [Middleware] using the provided functions.
///
/// If provided, [requestHandler] receives a [Request]. It can respond to
/// the request by returning a [Response] or [Future<Response>].
/// [requestHandler] can also return `null` for some or all requests in which
/// case the request is sent to the inner [Handler].
///
/// If provided, [responseHandler] is called with the [Response] generated
/// by the inner [Handler]. Responses generated by [requestHandler] are not
/// sent to [responseHandler].
///
/// [responseHandler] should return either a [Response] or
/// [Future<Response>]. It may return the response parameter it receives or
/// create a new response object.
///
/// If provided, [errorHandler] receives errors thrown by the inner handler. It
/// does not receive errors thrown by [requestHandler] or [responseHandler], nor
/// does it receive [HijackException]s. It can either return a new response or
/// throw an error.
Middleware createMiddleware({
  FutureOr<Response?> Function(Request)? requestHandler,
  FutureOr<Response> Function(Response)? responseHandler,
  FutureOr<Response> Function(Object error, StackTrace)? errorHandler,
}) {
  requestHandler ??= (request) => null;
  responseHandler ??= (response) => response;

  FutureOr<Response> Function(Object, StackTrace)? onError;
  if (errorHandler != null) {
    onError = (error, stackTrace) {
      if (error is HijackException) throw error;
      return errorHandler(error, stackTrace);
    };
  }

  return (Handler innerHandler) {
    return (request) {
      return Future.sync(() => requestHandler!(request)).then((response) {
        if (response != null) return response;

        return Future.sync(() => innerHandler(request))
            .then((response) => responseHandler!(response), onError: onError);
      });
    };
  };
}