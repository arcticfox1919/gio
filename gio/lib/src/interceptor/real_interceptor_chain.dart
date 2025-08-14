import 'package:http/http.dart' as http;
import '../exception/error.dart';
import 'interceptor.dart';

class RealInterceptorChain implements Chain {
  final Iterator<Interceptor> iterator;

  @override
  final http.BaseRequest request;

  RealInterceptorChain(this.iterator, this.request);

  @override
  Future<http.StreamedResponse> proceed(http.BaseRequest request) {
    if (iterator.moveNext()) {
      final curInterceptor = iterator.current;
      return curInterceptor(RealInterceptorChain(iterator, request));
    }
    throw InterceptorError('RealInterceptorChain', 'Interceptor out of bounds');
  }
}
