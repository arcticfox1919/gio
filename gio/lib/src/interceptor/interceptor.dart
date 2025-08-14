import 'package:http/http.dart' as http;

/// Represents the interceptor chain and the current request being processed.
///
/// Interceptors receive a [Chain] and may:
/// - Inspect or modify the current [request]
/// - Short-circuit the chain by returning a [http.StreamedResponse]
/// - Or call [proceed] to pass control to the next interceptor
///
/// Implementations should be stateless and only carry routing state.
abstract class Chain {
  /// Proceeds with [request] to the next interceptor in the chain.
  Future<http.StreamedResponse> proceed(http.BaseRequest request);

  /// The current request associated with this chain position.
  http.BaseRequest get request;
}

/// Function type for request/response interceptors.
///
/// Interceptor implementations should call [Chain.proceed] to continue the
/// chain or return a response to short-circuit.
typedef Interceptor = Future<http.StreamedResponse> Function(Chain chain);

/// Interface for the final call that actually talks to the network (or mock).
abstract interface class CallServer {
  /// Executes the network or mock call and returns a streaming response.
  Future<http.StreamedResponse> call(Chain chain);
}
