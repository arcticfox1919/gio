import 'package:http/http.dart' as http;
import 'interceptor.dart';

abstract class GioMockInterceptor implements CallServer {
  @override
  Future<http.StreamedResponse> call(Chain chain) async {
    throw UnimplementedError('GioMockInterceptor');
  }
}
