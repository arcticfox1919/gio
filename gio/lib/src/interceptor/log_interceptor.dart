import 'dart:async';
import 'dart:convert';

import '../base_request.dart';
import '../request.dart';
import '../streamed_request.dart';
import '../streamed_response.dart';
import 'interceptor.dart';

class GioLogInterceptor {
  GioLogInterceptor();

  Future<StreamedResponse> call(Chain chain) async {
    final request = chain.request;
    final requestTime = DateTime.now().millisecondsSinceEpoch;
    _logRequest(request);
    try {
      final response = await chain.proceed(request);
      var resp = response.copyWith(response.stream.asBroadcastStream());
      _logResponse(resp, requestTime);
      return resp;
    } catch (e) {
      _logUnknownError(e, request, requestTime);
      rethrow;
    }
  }

  void _logRequest(BaseRequest request) async {
    final sb = StringBuffer();
    final method = request.method.toUpperCase();
    final query = request.url.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final url = '${request.url}${query.isNotEmpty ? '?$query' : ''}';
    sb.writeln('--> $method $url');

    if (request is Request) {
      if (request.body.isNotEmpty) {
        sb.writeln(request.body);
      }
    } else if (request is StreamedRequest) {
      var bodyBytes = await request.finalize().asBroadcastStream().toList();
      if (bodyBytes.isNotEmpty) {
        sb.writeln(bodyBytes);
      }
    }

    sb.write('--> END $method');
    logPrint(sb.toString());
  }

  void _logResponse(StreamedResponse response, int requestTime) async {
    final url = response.request?.url;
    final sb = StringBuffer();
    sb.writeln(
        '<-- [${response.statusCode}][${DateTime.now().millisecondsSinceEpoch - requestTime}ms] $url ');

    var bytes = await response.stream.toBytes();
    if (bytes.isNotEmpty) {
      sb.writeln(utf8.decode(bytes));
    }
    sb.write('<-- END HTTP');
    logPrint(sb.toString());
  }

  void _logUnknownError(Object error, BaseRequest request, int requestTime) {
    final sb = StringBuffer();
    sb.writeln(
        '<-- [error][${DateTime.now().millisecondsSinceEpoch - requestTime}ms] ${request.url} ');
    sb.writeln(error.toString());
    sb.write('<-- END HTTP');
    logPrint(sb.toString());
  }

  void logPrint(String? message) {
    _print(message);
  }
}

const _maxLen = 128;
void _print(String? msg) {
  String data = msg ?? 'null';
  if (data.length <= _maxLen) {
    print(data);
    return;
  }
  while (data.isNotEmpty) {
    if (data.length > _maxLen) {
      print(data.substring(0, _maxLen));
      data = data.substring(_maxLen, data.length);
    } else {
      print(data);
      data = '';
    }
  }
}