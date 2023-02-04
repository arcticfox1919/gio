

import 'dart:collection';

import '../base_request.dart';
import '../streamed_response.dart';


class InterceptorEntry extends LinkedListEntry<InterceptorEntry> {
  final Interceptor interceptor;
  InterceptorEntry(this.interceptor);
}


abstract class Chain {
  Future<StreamedResponse> proceed(BaseRequest request);

  BaseRequest get request;
}

typedef Interceptor = Future<StreamedResponse> Function(Chain chain);


abstract class CallServer{
  Future<StreamedResponse> call(Chain chain);
}