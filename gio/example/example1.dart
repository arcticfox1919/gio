import 'dart:convert';

import 'package:gio/gio.dart' as gio;

void main() async {
  var resp = await gio.get("https://httpbin.org/get");
  print(resp.body);

  // GET http://example.com?a=1&b=2
  resp = await gio
      .get("http://example.com", queryParameters: {"a": "1", "b": "2"});
  print(resp.request?.url);

  // POST Form
  var data = {"username": "Bob", "passwd": "123456"};
  var header = {"content-type": "application/x-www-form-urlencoded"};
  resp = await gio.post("http://example.com", headers: header, body: data);
  print(resp.body);

  // POST Json
  var data2 = {"name": "Bob", "age": "22"};
  var header2 = {"content-type": "application/json"};
  resp = await gio.post("http://example.com",
      headers: header, body: jsonEncode(data));
  print(resp.body);
}
