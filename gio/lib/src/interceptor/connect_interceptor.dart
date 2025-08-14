import 'package:http/http.dart' as http;
import '../exception/error.dart';
import 'interceptor.dart';

abstract class GioConnectInterceptor {
  Future<http.StreamedResponse> call(Chain chain) async {
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
