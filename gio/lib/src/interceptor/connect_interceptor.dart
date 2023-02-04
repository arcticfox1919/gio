import '../exception/error.dart';

import '../streamed_response.dart';
import 'interceptor.dart';

abstract class ConnectInterceptor {
  Future<StreamedResponse> call(Chain chain) async {
    if (await checkConnectivity()) {
      return chain.proceed(chain.request);
    }
    throw ConnectiveError(-1, 'The current network is unavailable');
  }

  Future<bool> checkConnectivity();
}

class GioConnectInterceptor extends ConnectInterceptor {
  @override
  Future<bool> checkConnectivity() => Future.value(true);
}
