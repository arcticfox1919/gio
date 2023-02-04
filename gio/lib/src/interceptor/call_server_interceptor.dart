import '../http_delegator.dart';
import '../streamed_response.dart';
import 'interceptor.dart';

class CallServerInterceptor implements CallServer{
  final HttpDelegator delegator;

  CallServerInterceptor(this.delegator);

  @override
  Future<StreamedResponse> call(Chain chain) async {
    return await delegator.send(chain.request);
  }
}
