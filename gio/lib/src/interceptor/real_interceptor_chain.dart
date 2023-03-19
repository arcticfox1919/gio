import 'dart:collection';

import '../base_request.dart';
import '../exception/error.dart';
import '../streamed_response.dart';
import 'interceptor.dart';

class RealInterceptorChain implements Chain {
  final HasNextIterator<Interceptor> iterator;

  @override
  final BaseRequest request;

  RealInterceptorChain(this.iterator, this.request);

  @override
  Future<StreamedResponse> proceed(BaseRequest request) {
    if (iterator.hasNext) {
      var curInterceptor = iterator.next();
      return curInterceptor(RealInterceptorChain(iterator, request));
    }
    throw InterceptorError('RealInterceptorChain','Interceptor out of bounds');
  }
}

