import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gio/gio.dart';

import 'authorizer.dart';

extension ResponseX on Response {
  Response change({
    Map<String, String>? headers,
    Map<String, Object?>? context,
    List<int>? body,
  }) {
    final newHeaders = Map<String, String>.of(this.headers);
    if (headers != null) {
      headers.forEach((key, value) {
        newHeaders[key] = value;
      });
    }
    return Response.bytes(body?? bodyBytes, statusCode,
        request: request,
        headers: newHeaders,
        isRedirect: isRedirect,
        persistentConnection: persistentConnection,
        reasonPhrase: reasonPhrase);
  }

  static Response _createResponse(body,int statusCode,{Map<String,String>? headers}){
    assert(body != null);
    if(body is String){
      return Response(body,statusCode,headers: headers?? const {});
    }else if(body is Map){
      return Response(json.encode(body),statusCode,headers: headers?? const {});
    }else if(body is List<int> || body is Uint8List){
      Response.bytes(body,statusCode,headers: headers?? const {});
    }else{
      throw Exception("The `body` type is not allowed!");
    }
    return Response("The `body` type is not allowed!", 500);
  }

  /// Constructs a 200 OK response.
  static Response ok(body,{Map<String,String>? headers}){
    return _createResponse(body,HttpStatus.ok,headers: headers);
  }

  /// Represents a 400 response.
  static Response badRequest(body,{Map<String,String>? headers}){
    return _createResponse(body,HttpStatus.badRequest,headers: headers);
  }

  /// Represents a 401 response.
  static Response unauthorized(body,{Map<String,String>? headers}){
    return _createResponse(body,HttpStatus.unauthorized,headers: headers);
  }

  /// Represents a 500 response.
  static Response serverError(body,{Map<String,String>? headers}){
    return _createResponse(body,HttpStatus.internalServerError,headers: headers);
  }

  static Response token(AuthToken token) {
    return _createResponse(json.encode(token.asMap()),HttpStatus.ok,headers: {
      'Cache-Control': 'no-store',
      'Pragma': 'no-cache',
      HttpHeaders.contentTypeHeader: 'application/json'
    });
  }
}
