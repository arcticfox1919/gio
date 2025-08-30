import 'package:http/browser_client.dart' as http_browser;
import 'package:http/http.dart' as http;
import '../gio_config.dart';
import 'http_delegator.dart';

HttpDelegator createPkgHttpDelegatorImpl([GioConfig? config]) =>
    PkgHttpBrowserDelegator(config: config);

class PkgHttpBrowserDelegator implements HttpDelegator {
  late http.Client _client;

  PkgHttpBrowserDelegator({GioConfig? config}) {
    _client = http_browser.BrowserClient();
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
