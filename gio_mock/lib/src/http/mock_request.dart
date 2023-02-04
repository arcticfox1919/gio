import 'dart:collection';
import 'dart:io';

import 'package:gio/gio.dart';

final _emptyParams = UnmodifiableMapView(<String, String>{});

class MockRequest extends Request {
  final Map<String, Object?> context;

  MockRequest(super.method, super.url, {Map<String, Object?>? context}) :
        context =context ?? {};

  MockRequest change({
    Map<String, String>? headers,
    Map<String, Object?>? context,
    body,
  }) {
    var newContext = Map.of(this.context);
    if(context != null){
      context.forEach((key, value) {
        newContext[key] = value;
      });
    }
    return MockRequest(method, url, context: newContext);
  }

  Map<String, String> get params {
    final p = context['arowana/params'];
    if (p is Map<String, String>) {
      return UnmodifiableMapView(p);
    }
    return _emptyParams;
  }

  bool get hasQuery =>url.hasQuery;

  Map<String, String> get query {
    return UnmodifiableMapView(url.queryParameters);
  }

  bool get hasFormData {
    var contentTypeStr = headers[HttpHeaders.contentTypeHeader];
    if (contentTypeStr != null) {
      var contentType = ContentType.parse(contentTypeStr);
      return contentType.primaryType == 'application' &&
          contentType.subType == 'x-www-form-urlencoded';
    }
    return false;
  }
}
