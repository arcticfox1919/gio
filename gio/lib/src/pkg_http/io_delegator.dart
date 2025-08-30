import 'dart:io' as io;
import 'dart:async';
import 'package:http/io_client.dart' as http_io;
import 'package:http/http.dart' as http;
import '../gio_config.dart';
import 'http_delegator.dart';
import '../io/io_context.dart';

HttpDelegator createPkgHttpDelegatorImpl([GioConfig? config]) =>
    PkgHttpIODelegator(config: config);

class PkgHttpIODelegator implements HttpDelegator {
  late http.Client _client;

  PkgHttpIODelegator({GioConfig? config}) {
    io.HttpClient inner;
    if (config?.context is IOContext) {
      inner = io.HttpClient(context: (config!.context as IOContext).context);
    } else {
      inner = io.HttpClient();
    }
    if (config?.proxy != null) {
      inner.findProxy =
          (uri) => 'PROXY ${config!.proxy!.host}:${config.proxy!.port}';
    }
    _client = http_io.IOClient(inner);
  }

  @override
  void close() {
    _client.close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _client.send(request);
  }
}
