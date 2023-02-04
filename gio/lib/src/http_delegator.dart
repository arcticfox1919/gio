
import 'base_request.dart';
import 'gio_config.dart';
import 'streamed_response.dart';

import 'gio_stub.dart'
    if (dart.library.html) 'web/browser_delegator.dart'
    if (dart.library.io) 'io/io_delegator.dart';

abstract class HttpDelegator{
  factory HttpDelegator([GioConfig? config]) => createHttpDelegator(config);

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request);

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to
  /// do so can cause the Dart process to hang.
  void close();
}