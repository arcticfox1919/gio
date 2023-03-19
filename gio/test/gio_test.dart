import 'dart:convert';

import 'package:gio/gio.dart' as gio;
import 'package:gio_mock/gio_mock.dart';
import 'package:test/test.dart';

import 'mock_channel.dart';

void main() {
  group('#request', () {
    setUp(() {
      gio.Gio.option = gio.GioOption(
          basePath: 'https://giomock.io',
          mockInterceptor: GioMockServer(MyMockChannel()));
    });

    test('GET /greet', () async {
      var resp = await gio.get("/greet", queryParameters: {'name': 'Bob'});
      expect(resp.body, equals('hello,Bob'));
    });

    test('POST /login', () async {
      var data = {"username": "Bob", "passwd": "123456"};
      var header = {"content-type":"application/x-www-form-urlencoded"};
      var resp = await gio.post("/login", headers: header,body: data);
      expect(resp.body, equals(jsonEncode(data)));
    });

    test('POST /list', () async {
      var data = {
        "array":[
          {
            "name":"Go",
            "url":"https://go.dev/",
          },
          {
            "name":"Dart",
            "url":"https://dart.dev/",
          },
        ]
      };
      var header = {"content-type":"application/json"};
      var resp = await gio.post("/list", headers: header,body: jsonEncode(data));
      expect(resp.body, equals(jsonEncode(data)));
    });
  });
}
