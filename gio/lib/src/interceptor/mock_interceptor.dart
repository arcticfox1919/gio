
import '../streamed_response.dart';
import 'interceptor.dart';

abstract class GioMockInterceptor implements CallServer{
  @override
  Future<StreamedResponse> call(Chain chain) async {
    throw UnimplementedError('GioMockInterceptor');
  }
}