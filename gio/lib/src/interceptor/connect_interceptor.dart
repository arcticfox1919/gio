import '../exception/error.dart';

import '../streamed_response.dart';
import 'interceptor.dart';

abstract class GioConnectInterceptor {
  Future<StreamedResponse> call(Chain chain) async {
    if (await checkConnectivity()) {
      return chain.proceed(chain.request);
    }
    throw ConnectiveError(-1, 'The current network is unavailable');
  }

  Future<bool> checkConnectivity();
}

class DefaultConnectInterceptor extends GioConnectInterceptor {
  @override
  Future<bool> checkConnectivity() => Future.value(true);
}
