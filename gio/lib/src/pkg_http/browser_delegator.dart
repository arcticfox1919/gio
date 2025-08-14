import 'package:http/browser_client.dart' as http_browser;
import 'package:http/http.dart' as http;
import '../gio_config.dart';
import '../http_delegator.dart';

HttpDelegator createPkgHttpDelegatorImpl([GioConfig? config]) =>
    PkgHttpBrowserDelegator(config: config);

class PkgHttpBrowserDelegator implements HttpDelegator {
  http.Client? _client;

  PkgHttpBrowserDelegator({GioConfig? config}) {
    final c = http_browser.BrowserClient();
    _client = c;
  }

  @override
  void close() {
    _client?.close();
    _client = null;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _client!.send(request);
  }
}
