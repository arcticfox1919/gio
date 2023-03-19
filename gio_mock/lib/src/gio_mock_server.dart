
import 'dart:async';

import 'package:gio/gio.dart';
import 'package:gio_mock/src/http/mock_request.dart';

import 'mock_channel.dart';

class GioMockServer implements GioMockInterceptor{
  final MockChannel channel;

  GioMockServer(this.channel){
    channel.entryPoint();
  }

  @override
  Future<StreamedResponse> call(Chain chain) async{
    var request = chain.request;
    var response = await channel(_convert(request));

    var controller = StreamController<List<int>>(sync: true);
    var streamResponse = StreamedResponse(
        controller.stream, response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase);

    controller.add(response.bodyBytes);
    unawaited(controller.close());
    return streamResponse;
  }

  MockRequest _convert(BaseRequest request){
    if(request is Request){
      var mock = MockRequest(request.method, request.url);
      mock.headers.addAll(request.headers);
      mock.bodyBytes = request.bodyBytes;
      return mock;
    }
    throw Exception("Only `Request` type requests are supported for now");
  }

}