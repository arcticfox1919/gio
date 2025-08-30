import 'package:http/http.dart' as http;
import '../pkg_http/http_delegator.dart';
import 'interceptor.dart';

class CallServerInterceptor implements CallServer {
  final HttpDelegator delegator;

  CallServerInterceptor(this.delegator);

  @override
  Future<http.StreamedResponse> call(Chain chain) async {
    return await delegator.send(chain.request);
  }
}
